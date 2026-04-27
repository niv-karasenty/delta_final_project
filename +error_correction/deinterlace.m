function [S, P1, P2] = deinterlace(decycled_bits)
    bits_per_subblock=1412;
    S=decycled_bits(1:bits_per_subblock);
    P1=decycled_bits(bits_per_subblock+1:2:end);
    P2=decycled_bits(bits_per_subblock+2:2:end);
end