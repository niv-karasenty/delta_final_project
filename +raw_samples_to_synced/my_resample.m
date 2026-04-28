function y = my_resample(x, fs_in, fs_out)
    [P, Q] = rat(fs_out / fs_in, 1e-9);
    if exist('resample', 'file') == 2
        y = resample(x, P, Q);
    else
        n_out = round(numel(x) * P / Q);
        y = ifft(fft(x), n_out) * (n_out / numel(x));
    end
end