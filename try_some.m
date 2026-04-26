vec1 = ones(1e4, 1);
vec2 = ones(1e4, 1);

conv(vec1, flip(vec2));
xcorr(vec1, vec2);