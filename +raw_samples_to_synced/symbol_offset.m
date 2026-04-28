function off = symbol_offset(sym_1b, P)
    off = 0;
    for k = 1:sym_1b-1
        cp = P.cp_normal;
        if any(k == P.ext_syms_1b), cp = P.cp_extended; end
        off = off + cp + P.n_fft;
    end
end