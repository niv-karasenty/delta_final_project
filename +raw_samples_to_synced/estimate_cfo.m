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