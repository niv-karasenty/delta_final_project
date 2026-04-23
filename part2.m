% Part 2 (correction code):
% goldcode de-masking -> cyclic buffer extraction -> de-interlacing ->
% de-interleaving -> viterbi -> bits

raw_hex=fileread("raw_bits_12_Feb_2026_09_30_40_676.txt")
raw_bits = hexToBinaryVector(raw_hex);
corrected_bits=correct_bits(raw_bits);

test_hex = fileread("processed_bits12_Feb_2026_09_30_40_676.txt");
test_bits=binaryVectorToHex(test_hex);
biterr(test_bits, corrected_bits);

function corrected_bits = correct_bits(raw_bits)

arguments
    raw_bits (1, 7200)
end
    
    demasked_bits=demask(raw_bits);
    decycled_bits=decycle_buffer(demasked_bits);
    [S, P1, P2] = deinterlace(decycled_bits);
   
    corrected_bits=turbo(S, P1, P2);

end

function corrected_bits=turbo(S, P1, P2)
    ls=[S; P1; P2];
    for i = 1:length(ls)
        ls(i,:) = deinterleave(ls(i,:));
    end

    % g(d) = [1, (1 + d + d^2 + d^3)/(1+d^2+d^3)]
    % in octal representation of the poly vectors we get [17, 13]
    % where 17 is for the parity path and 13 is for the feedback
    
    CodeGenerator=[17, 13];
    ConstraintLength=4; % max_degree+1 which is the number of shift registers
    FeedbackConnection=17; % denominator (parity path) octal

    trellis = poly2trellis(ConstraintLength,CodeGenerator,FeedbackConnection);
    interlv_indices=mod((43*(1:1408) + 88 * (1:1408).^2), 1408);
    numIter=6;
    turboDec = comm.TurboDecoder(trellis, interlv_indices, numIter);
    
    codeword = [ls(1,:), ls(2,:), ls(3,:)];

    % if hard decision we need to map to bipolar (0 1 to -1 1)
    % if soft decision we need to invert (*-1)

    corrected_bits=turboDec(1-2*codeword);
    
end

function deinterleaved_bits = deinterleave(bits)
    
    bits = insert_dummy(bits);
    bits=reshape(bits, 45, 32);
    
    % interleave columns
    interleave_indices = [1,17,9,25,5,21,13,29,3,19,11,27,7,23,15,31,2,18,10,26,6,22,14,30,4,20,12,28,8,24,16,3];
    deinterleave_indices=zeros(1, length(bits));
    for i=1:length(bits)
        deinterleave_indices(interleave_indices(i))=i;
    end
    deinterleaved_bits=bits(:, deinterleave_indices);

    % rows to vector

    deinterleaved_bits=deinterleaved_bits.';
    deinterleaved_bits=deinterleaved_bits(:).';
end

function dummy_bits = insert_dummy(bits)
    % insert dummy bits (zeros) at the beginning of every 44 bit batch
    % (for the last batch insert in the end of it not beginning)
    batch_len=44;
    last_batch = bits(end-batch_len+1:end);
    bits = bits(1:end-batch_len);
    
    % dummy bit
    val = 0;

    % Calculate final length
    num_inserts = floor(numel(bits) / batch_len);
    final_len = numel(bits) + num_inserts;

    % Preallocate with the value to be inserted
    result = repmat(val, 1, final_len);

    % Create a mask for where the original data goes
    mask = mod(1:final_len, batch_len+1) ~= 0;
    result(mask) = bits;
    result=result(1:end-1); % truncate last dummy

    dummy_bits=[val, result, last_batch, val];

end

function [S, P1, P2] = deinterlace(decycled_bits)
    bits_per_subblock=1412;
    S=decycled_bits(1:bits_per_subblock);
    P1=decycled_bits(bits_per_subblock+1:2:end);
    P2=decycled_bits(bits_per_subblock+2:2:end);
end

function decycled_bits = decycle_buffer(demasked_bits)
    num_bits_post_correction_code=4236;
    packet_length=7200;
    start_idx=4148;
    postfix_length=num_bits_post_correction_code-start_idx;
    decycled_bits=demasked_bits(postfix_length+1:postfix_length+num_bits_post_correction_code);
    % later we can sum equal parts to gain snr
end

function demasked_bits = demask(raw_bits)

arguments
    raw_bits (1, 7200)
end
    seq=gen_gold_code().';
    demasked_bits=xor(raw_bits, seq);
end

function seq = gen_gold_code(Nc, L, seed)

arguments
    Nc (1,1) = 1600
    L (1,1) = 7200
    seed (1,1) = 0x12345678
end

    x1 = zeros(Nc + L + 31, 1);
    x2 = zeros(Nc + L + 31, 1);
    x2(1:32) = flip(dec2bin(seed, 32));
    x1(1) = 1;
    for n = 1:(Nc + L)
        x1(n + 31) = xor(x1(n + 3), x1(n));
        x2(n + 31) = xor(xor(x2(n + 3), x2(n + 2)), xor(x2(n+1), x2(n)));
    end
    seq = xor(x1(Nc + 1:Nc+L), x2(Nc + 1:Nc+L));
end