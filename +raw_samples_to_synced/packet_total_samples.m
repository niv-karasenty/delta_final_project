function n = packet_total_samples(P)
    n = (P.n_symbols - numel(P.ext_syms_1b)) * (P.n_fft + P.cp_normal) + ...
        numel(P.ext_syms_1b) * (P.n_fft + P.cp_extended);
end