% Part 2 (correction code):
% goldcode de-masking -> cyclic buffer extraction -> de-interlacing ->
% de-interleaving -> viterbi -> bits

clc;
close all;
clear;

raw_hex=fileread("raw_bits_12_Feb_2026_09_30_39_442.txt");
raw_bits = hex_to_binary(raw_hex);
corrected_bits=correct_bits(raw_bits);

test_hex = fileread("processed_bits12_Feb_2026_09_30_39_442.txt");
test_bits=hex_to_binary(test_hex);


biterr(test_bits, corrected_bits(1:728))


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
    corrected_bits=deinterleave(S);
    % ls=[S; P1; P2];
    % for i = 1:3
    %     ls(i,:) = deinterleave(ls(i,:));
    % end
    % 
    % % g(d) = [1, (1 + d + d^2 + d^3)/(1+d^2+d^3)]
    % % in octal representation of the poly vectors we get [17, 13]
    % % where 17 is for the parity path and 13 is for the feedback
    % 
    % CodeGenerator=[17, 13];
    % ConstraintLength=4; % max_degree+1 which is the number of shift registers
    % FeedbackConnection=17; % denominator (parity path) octal
    % 
    % trellis = poly2trellis(ConstraintLength,CodeGenerator,FeedbackConnection);
    % interlv_indices=mod((43*(1:1408) + 88 * (1:1408).^2), 1408)+1;
    % interlv_indices(interlv_indices<=0)
    % numIter=6;
    % turboDec = comm.TurboDecoder(trellis, interlv_indices, numIter);
    % 
    % codeword = [ls(1,:), ls(2,:), ls(3,:)];
    % 
    % % if hard decision we need to map to bipolar (0 1 to -1 1)
    % % if soft decision we need to invert (*-1)
    % 
    % corrected_bits=turboDec(1-2*codeword).';
    
end

function interleaved_bits = interleave(bits)

interleave_indices = [1,17,9,25,5,21,13,29,3,19,11,27,7,23,15,31,2,18,10,26,6,22,14,30,4,20,12,28,8,24,16,32];

dummy_val=-1;
bits=[dummy_val*ones(1,28), bits];

% to rows in matrix

bits=reshape(bits, 32, []).';

% interleave
interleaved_bits=bits(:, interleave_indices);

% flatten

interleaved_bits=reshape(interleaved_bits, 1, []);

% remove dummy

interleaved_bits(interleaved_bits==dummy_val)=[];

end

function deinterleaved_bits = deinterleave(bits)
    
    interleave_indices = [1,17,9,25,5,21,13,29,3,19,11,27,7,23,15,31,2,18,10,26,6,22,14,30,4,20,12,28,8,24,16,32];


    bits = insert_dummy(bits, interleave_indices);
    bits=reshape(bits, 45, []);
    
    % deinterleave columns
    deinterleave_indices=zeros(1, length(interleave_indices));
    for i=1:length(interleave_indices)
        deinterleave_indices(interleave_indices(i))=i;
    end
    deinterleaved_bits=bits(:, deinterleave_indices);

    % rows to vector

    deinterleaved_bits=deinterleaved_bits.';
    deinterleaved_bits=deinterleaved_bits(:).';

    % remove 28 dummy values

    deinterleaved_bits=deinterleaved_bits(29:end);
end

function res = insert_dummy(bits, interleave_indices)
    % supposing no cols interleaving
    % we would need to slice the first 28 cols
    % to groups of 44 and add one dummy bit at the beginning
    % and for the last 4 cols (size 45) take them raw (no need to add anything)
    
    % because we do have cols interleaving, we could initialize a binary vector
    % [1]*28 + [0]*4 and apply the cols interleaving on it,
    % and then our function will work this way:
    % if the vector has 1:
    % take the next 44 bits and also add dummy bit in beginning
    % else take the next 45 bits
    
    dummy_val=-1;
    
    to_add_dummy=[ones(1, 28), zeros(1,4)];

    to_add_dummy=to_add_dummy(interleave_indices);
    
    res=zeros(1,1440);
    j = 1;
    for i=1:length(to_add_dummy)
        if to_add_dummy(i)==1
            batch = bits(j:j+43); % take next 44 bits
            batch = [dummy_val, batch]; % add dummy
            res(45*(i-1)+1 : 45*(i-1)+45)=batch;
            j = j+44;
        else
            batch = bits(j:j+44); % take next 45 bits
            res(45*(i-1)+1 : 45*(i-1)+45)=batch;
            j = j+45;
        end

    end

end


function [S, P1, P2] = deinterlace(decycled_bits)
    bits_per_subblock=1412;
    S=decycled_bits(1:bits_per_subblock);
    P1=decycled_bits(bits_per_subblock+1:2:end);
    P2=decycled_bits(bits_per_subblock+2:2:end);
end

function decycled_bits = decycle_buffer(demasked_bits)
    num_bits_post_correction_code=4236;
    start_idx=4149;
    packet_len=7200;
    decycled_bits = [demasked_bits(start_idx:end), demasked_bits(1:num_bits_post_correction_code - (packet_len-start_idx+1))];
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
    x2(1:32) = flip(dec2bin(seed, 32)-'0');
    x1(1) = 1;
    for n = 1:(Nc + L)
        x1(n + 31) = xor(x1(n + 3), x1(n));
        x2(n + 31) = xor(xor(x2(n + 3), x2(n + 2)), xor(x2(n+1), x2(n)));
    end
    seq = xor(x1(Nc + 1:Nc+L), x2(Nc + 1:Nc+L));
end


function bits = hex_to_binary(hex)
    
    % convert to array such that each element is 2 chars (Byte)
    hex=regexp(hex, '.{1,2}', 'match');
    
    bits = de2bi(hex2dec(hex), 'left-msb');
    
    % flatten
    bits = reshape(bits.', 1, []);

end