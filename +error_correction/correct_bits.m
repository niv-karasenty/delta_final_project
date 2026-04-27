function [corrected_bits, no_correction] = correct_bits(raw_bits)

arguments
    raw_bits (1, 7200)
end
 
    demasked_bits=error_correction.demask(raw_bits);
    decycled_bits=error_correction.decycle_buffer(demasked_bits);
    [S, P1, P2] = error_correction.deinterlace(decycled_bits);
    deinterleaved_bit_arrays = error_correction.deinterleave({S, P1, P2});
    [S, P1, P2] = deinterleaved_bit_arrays{:};

    % generated the real parity bits to see if it works better
    % but it yields to the same results as without it

    % conv_out=convenc(S, poly2trellis(4, [13 15], 13));
    % real_parity = conv_out(2:2:end);
    % length(P1)
    % length(conv_out)
    no_correction=S;
    corrected_bits=error_correction.turbo(S, P1, P2);

end