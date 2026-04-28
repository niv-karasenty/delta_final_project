clc
close all
clear

file = 'raw_samples/raw_samples_12_Feb_2026_09_30_39_442_fs_10MHz.32fc';
fs = 10e6;

data = drone_id_demod(file, fs);


function data_qpsk = drone_id_demod(input, fs)
    %% ==================== Read File ====================
    iq = double(read_complex32_file(char(input)));

    %% ==================== Constants ====================
    P.fs_native = 15.36e6;
    P.n_fft = 1024;
    P.n_active = 601;
    P.active_lo_1b = 213;
    P.active_hi_1b = 813;
    P.cp_normal = 72;
    P.cp_extended = 80;
    P.n_symbols = 9;
    P.sync_syms_1b = [4 6];
    P.data_syms_1b = [2 3 5 7 8 9];
    P.ext_syms_1b = [1 9];
    P.zc_root_sym4 = 600;
    P.zc_root_sym6 = 147;
    P.n_qpsk_per_sym = 600;

    %% ==================== Find The Packet ====================
    [s, e] = detect_packet_window(iq, fs, 2.0e-6, 4.0, 50.0e-6);

    if abs(fs - P.fs_native) > 1
        chunk_native = my_resample(iq(s:e), fs, P.fs_native);
    else
        chunk_native = iq(s:e);
    end

    %% ==================== Time Sync ====================
    tpl4 = zc_time_template(P.zc_root_sym4, P);
    [pkt_start, sync_peak] = find_packet_start(chunk_native, tpl4, P);

    %% ==================== Find The Freq Offset ====================
    cfo_hz = estimate_cfo(chunk_native, pkt_start, P);

    %% ==================== Get The OFDM symmbols ====================
    pkt_len = packet_total_samples(P);
    sl = chunk_native(pkt_start : pkt_start + pkt_len - 1);
    t = (0:numel(sl)-1).' / P.fs_native;
    sl = sl .* exp(-1j*2*pi*cfo_hz*t);

    bodies = zeros(P.n_fft, P.n_symbols);
    pos = 0;
    for k = 1:P.n_symbols
        cp = P.cp_normal;
        if any(k == P.ext_syms_1b), cp = P.cp_extended; end
        bodies(:,k) = sl(pos + cp + (1:P.n_fft));
        pos = pos + cp + P.n_fft;
    end

    spectra = fftshift(fft(bodies), 1);
    lo = P.active_lo_1b;
    hi = P.active_hi_1b;
    actives = spectra(lo:hi, :);

    %% ==================== Channel Estimation ====================
    half = (P.n_active + 1) / 2;
    keep = true(P.n_active,1); keep(half) = false;

    zc4 = zc_freq(P.zc_root_sym4, P.n_active);
    zc6 = zc_freq(P.zc_root_sym6, P.n_active);
    rx4 = actives(:,4);
    rx6 = actives(:,6);

    h4 = rx4(keep) ./ zc4(keep);
    h6 = rx6(keep) ./ zc6(keep);
    h_avg = 0.5 * (h4 + h6);

    h_smooth = movmean(h_avg, 7);

    %% ==================== Open The Symbols ====================
    data_qpsk = zeros(numel(P.data_syms_1b), P.n_qpsk_per_sym);
    for i = 1:numel(P.data_syms_1b)
        rx = actives(:, P.data_syms_1b(i));
        data_qpsk(i, :) = (rx(keep) ./ h_smooth).';
    end

    %% ==================== Finilize ====================
    x4_angle_deg = zeros(1, size(data_qpsk,1));
    for ii = 1:size(data_qpsk,1)
        x = data_qpsk(ii,:);
        m4 = mean(x.^4);
        phi = (angle(m4) - pi) / 4;
        phi = phi - (pi/2) * round(phi / (pi/2));
        data_qpsk(ii,:) = x .* exp(-1j*phi);
        x4_angle_deg(ii) = angle(mean(data_qpsk(ii,:).^4)) * 180/pi;
    end
end

%% Functions
function iq = read_complex32_file(fname)
    fid = fopen(fname, 'rb');
    if fid < 0
        error('drone_id_demod:fileOpen', 'Cannot open file: %s', fname);
    end
    raw = fread(fid, inf, 'float32=>double');
    fclose(fid);
    if mod(numel(raw), 2) ~= 0
        error('drone_id_demod:oddLen', 'File length is odd, not interleaved I/Q.');
    end
    iq = raw(1:2:end) + 1j*raw(2:2:end);
end

function [s, e] = detect_packet_window(iq, fs, smooth_s, thresh_factor, margin_s)
    p   = abs(iq).^2;
    win = max(1, round(smooth_s*fs));
    sm  = movmean(p, win);
    th  = thresh_factor * median(sm);
    above = sm > th;
    if ~any(above)
        error('drone_id_demod:noPacket', 'No packet found above threshold.');
    end

    d  = diff([0; above(:); 0]);
    starts = find(d == 1);
    ends   = find(d == -1) - 1;
    [~,bi] = max(ends - starts);
    s = starts(bi); e = ends(bi);
    pad = round(margin_s*fs);
    s = max(1, s - pad);
    e = min(numel(iq), e + pad);
end

function y = my_resample(x, fs_in, fs_out)
    [P, Q] = rat(fs_out / fs_in, 1e-9);
    if exist('resample', 'file') == 2
        y = resample(x, P, Q);
    else
        n_out = round(numel(x) * P / Q);
        y = ifft(fft(x), n_out) * (n_out / numel(x));
    end
end

function n = packet_total_samples(P)
    n = (P.n_symbols - numel(P.ext_syms_1b)) * (P.n_fft + P.cp_normal) + numel(P.ext_syms_1b) * (P.n_fft + P.cp_extended);
end

function off = symbol_offset(sym_1b, P)
    off = 0;
    for k = 1:sym_1b-1
        cp = P.cp_normal;
        if any(k == P.ext_syms_1b), cp = P.cp_extended; end
        off = off + cp + P.n_fft;
    end
end

function zc = zc_freq(root, N)
    n = (0:N-1).';
    if mod(N,2) == 1
        zc = exp(-1j*pi*root*n.*(n+1)/N);
    else
        zc = exp(-1j*pi*root*n.^2/N);
    end
end

function td = zc_time_template(root, P)
    zc = zc_freq(root, P.n_active);

    spec_shifted = zeros(P.n_fft, 1);
    half  = (P.n_active + 1)/2;
    lo_0b = P.active_lo_1b - 1;

    spec_shifted(lo_0b + (1:half-1)) = zc(1:half-1);
    spec_shifted(lo_0b + half + (1:P.n_active-half)) = zc(half+1:end);

    spec = ifftshift(spec_shifted);
    td   = ifft(spec) * P.n_fft;
end

function [pkt_start, peak_mag] = find_packet_start(iq_native, tpl, P)
    n = numel(iq_native) + numel(tpl) - 1;
    nfft = 2^nextpow2(n);
    X = fft(iq_native, nfft);
    H = fft(conj(tpl(end:-1:1)), nfft);
    c = ifft(X .* H);
    c = c(1:n);
    [peak_mag, peak_idx] = max(abs(c));
    sym4_body_start = peak_idx - numel(tpl) + 1;
    pkt_start = sym4_body_start - P.cp_normal - symbol_offset(4, P);
    if pkt_start < 1
        pkt_start = 1;
    end
    if pkt_start + packet_total_samples(P) - 1 > numel(iq_native)
        error('drone_id_demod:syncRange', ...
              'Packet sync indicates start beyond available samples.');
    end
end

function cfo = estimate_cfo(iq_native, pkt_start, P)
    angles  = zeros(P.n_symbols, 1);
    weights = zeros(P.n_symbols, 1);
    pos = pkt_start;
    for k = 1:P.n_symbols
        cp = P.cp_normal;
        if any(k == P.ext_syms_1b), cp = P.cp_extended; end
        cp_block   = iq_native(pos        : pos + cp - 1);
        tail_block = iq_native(pos + cp + P.n_fft - cp : pos + cp + P.n_fft - 1);
        c = sum(cp_block .* conj(tail_block));
        angles(k)  = angle(c);
        weights(k) = abs(c);
        pos = pos + cp + P.n_fft;
    end
    z = sum(weights .* exp(1j*angles));
    cfo = -angle(z) * P.fs_native / (2*pi*P.n_fft);
end