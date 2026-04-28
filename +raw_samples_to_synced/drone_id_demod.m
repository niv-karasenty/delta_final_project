function data_qpsk = drone_id_demod(input, fs)
    %% ==================== Read File ====================
    iq = double(raw_samples_to_synced.read_complex32_file(char(input)));

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
    [s, e] = raw_samples_to_synced.detect_packet_window(iq, fs, 2.0e-6, 4.0, 50.0e-6);

    if abs(fs - P.fs_native) > 1
        chunk_native = raw_samples_to_synced.my_resample(iq(s:e), fs, P.fs_native);
    else
        chunk_native = iq(s:e);
    end

    %% ==================== Time Sync ====================
    tpl4 = raw_samples_to_synced.zc_time_template(P.zc_root_sym4, P);
    [pkt_start, sync_peak] = raw_samples_to_synced.find_packet_start(chunk_native, tpl4, P);

    %% ==================== Find The Freq Offset ====================
    cfo_hz = raw_samples_to_synced.estimate_cfo(chunk_native, pkt_start, P);

    %% ==================== Get The OFDM symmbols ====================
    pkt_len = raw_samples_to_synced.packet_total_samples(P);
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

    zc4 = raw_samples_to_synced.zc_freq(P.zc_root_sym4, P.n_active);
    zc6 = raw_samples_to_synced.zc_freq(P.zc_root_sym6, P.n_active);
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