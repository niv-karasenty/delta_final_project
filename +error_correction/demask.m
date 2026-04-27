function demasked_bits = demask(raw_bits)

arguments
    raw_bits (1, 7200)
end
    seq=error_correction.gen_gold_code().';
    demasked_bits=xor(raw_bits, seq);
end