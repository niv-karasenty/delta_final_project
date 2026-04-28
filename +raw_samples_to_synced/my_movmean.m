function y = my_movmean(x, w)
    if exist('movmean', 'builtin') || exist('movmean', 'file') == 2
        try
            y = movmean(x, w);
            return;
        catch
            % PASS
        end
    end
    k = ones(w,1) / w;
    if isrow(x)
        y = conv(x.', k, 'same').';
    else
        y = conv(x, k, 'same');
    end
end