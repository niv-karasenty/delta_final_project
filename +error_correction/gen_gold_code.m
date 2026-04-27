function seq = gen_gold_code(Nc, L, seed)

arguments
    Nc (1,1) = 1600
    L (1,1) = 7200
    seed (1,1) = 0x12345678
end

    x1 = zeros(Nc + L + 31, 1);
    x2 = zeros(Nc + L + 31, 1);
    x2(1:32) = flip(dec2bin(seed, 32)-'0');
    x1(1) = 1;
    for n = 1:(Nc + L)
        x1(n + 31) = xor(x1(n + 3), x1(n));
        x2(n + 31) = xor(xor(x2(n + 3), x2(n + 2)), xor(x2(n+1), x2(n)));
    end
    seq = xor(x1(Nc + 1:Nc+L), x2(Nc + 1:Nc+L));
end