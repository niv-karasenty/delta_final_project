function c = fft_xcorr(x, h)
    n = numel(x) + numel(h) - 1;
    nfft = 2^nextpow2(n);
    X = fft(x, nfft);
    H = fft(conj(h(end:-1:1)), nfft);
    c = ifft(X .* H);
    c = c(1:n);
end