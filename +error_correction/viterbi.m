function corrected_bits=viterbi(S, P)
    
    code=[S;P];
    code=code(:).';
    
    max_degree=3;
    constraint_length=max_degree+1;
    % 5 is standard for conv codes with rate of 1/2
    tb=5*constraint_length;
    
    % 13 and 15
    trellis=poly2trellis(constraint_length, [13 15], 13);
    
    % REMEMBER TO MULTIPLY IN MINUS 1 IF SOFT DEICSION
    corrected_bits=vitdec(code,trellis,tb,'trunc','hard');   

end