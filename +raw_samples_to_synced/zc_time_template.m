function td = zc_time_template(root, P)
    zc = raw_samples_to_synced.zc_freq(root, P.n_active);

    spec_shifted = zeros(P.n_fft, 1);
    half = (P.n_active + 1)/2;
    lo_0b = P.active_lo_1b - 1;

    spec_shifted(lo_0b + (1:half-1)) = zc(1:half-1);
    spec_shifted(lo_0b + half + (1:P.n_active-half)) = zc(half+1:end);

    spec = ifftshift(spec_shifted);
    td = ifft(spec) * P.n_fft;
end