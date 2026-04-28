function [corrected_viterbi, corrected_turbo, not_corrected] = correct_bits(raw_bits)

arguments
    raw_bits (1, 7200)
end
 
    demasked_bits= error_correction.demask(raw_bits);
    decycled_bits= error_correction.decycle_buffer(demasked_bits);
    [S, P1, P2] = error_correction.deinterlace(decycled_bits);
    deinterleaved_bit_arrays = error_correction.deinterleave({S, P1, P2});
    [S, P1, P2] = deinterleaved_bit_arrays{:};

    not_corrected=S;
    corrected_viterbi= error_correction.viterbi(S, P1);
    num_iters=6;
    corrected_turbo= error_correction.turbo(S, P1, P2, num_iters);

end
