function avg_acorr = mean_cp_autocorr(iq_native, pkt_start, P)
    pos = pkt_start;
    acorrs = zeros(P.n_symbols, 1);
    for k = 1:P.n_symbols
        cp = P.cp_normal;
        if any(k == P.ext_syms_1b), cp = P.cp_extended; end
        cp_block   = iq_native(pos        : pos + cp - 1);
        tail_block = iq_native(pos + cp + P.n_fft - cp : pos + cp + P.n_fft - 1);
        c   = sum(cp_block .* conj(tail_block));
        nrm = sqrt(sum(abs(cp_block).^2)) * sqrt(sum(abs(tail_block).^2));
        if nrm > 0
            acorrs(k) = abs(c) / nrm;
        else
            acorrs(k) = 0;
        end
        pos = pos + cp + P.n_fft;
    end
    avg_acorr = mean(acorrs);
end
