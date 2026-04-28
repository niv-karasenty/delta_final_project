function [pkt_start, peak_mag] = find_packet_start(iq_native, tpl, P)
    n = numel(iq_native) + numel(tpl) - 1;
    nfft = 2^nextpow2(n);
    X = fft(iq_native, nfft);
    H = fft(conj(tpl(end:-1:1)), nfft);
    c = ifft(X .* H);
    c = c(1:n);
    [peak_mag, peak_idx] = max(abs(c));
    sym4_body_start = peak_idx - numel(tpl) + 1;
    pkt_start = sym4_body_start - P.cp_normal - raw_samples_to_synced.symbol_offset(4, P);
    if pkt_start < 1
        pkt_start = 1;
    end
    if pkt_start + raw_samples_to_synced.packet_total_samples(P) - 1 > numel(iq_native)
        error('drone_id_demod:syncRange', ...
              'Packet sync indicates start beyond available samples.');
    end
end
