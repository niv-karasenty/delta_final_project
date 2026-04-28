function zc = zc_freq(root, N)
    n = (0:N-1).';
    if mod(N,2) == 1
        zc = exp(-1j*pi*root*n.*(n+1)/N);
    else
        zc = exp(-1j*pi*root*n.^2/N);
    end
end