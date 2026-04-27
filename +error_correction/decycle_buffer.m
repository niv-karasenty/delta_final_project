function decycled_bits = decycle_buffer(demasked_bits)
    num_bits_post_correction_code=4236;
    start_idx=4149;

    demasked_bits=demasked_bits(1:num_bits_post_correction_code);
    decycled_bits=circshift(demasked_bits, num_bits_post_correction_code-start_idx+1);

end