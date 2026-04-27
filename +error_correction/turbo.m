function corrected_bits=turbo(S, P1, P2)
    
    

    % encodedData=[S;P1;P2];
    % encodedData=encodedData(:).';
    % p = qfunc(sqrt(2 * 10^(10/10)));
    % [receivedData, nzVar] = bsc(encodedData, p)
    
    code=[S;P1];
    code=code(:).';

    max_degree=3;
    constraint_length=max_degree+1;
    % 5 is standard for conv codes with rate of 1/2
    tb=5*constraint_length;

    % 13 and 15
    trellis=poly2trellis(constraint_length, [13 15], 13);

    % viterbidecoder = comm.ViterbiDecoder('TrellisStructure', trellis,'TracebackDepth',tb, 'InputFormat','Hard', 'TerminationMethod','Truncated');
    % corrected_bits=viterbidecoder(code.').';

    corrected_bits=vitdec(code,trellis,tb,'trunc','hard');
    
    
end