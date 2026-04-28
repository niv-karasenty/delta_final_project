% author - guni deyo haness

% Part 2 (correction code):
% goldcode de-masking -> cyclic buffer extraction -> de-interlacing ->
% de-interleaving -> viterbi -> bits

clc;
close all;
clear;

raw_prefix='raw_bits';
test_prefix='processed_bits';
raw_files=dir(fullfile('', [raw_prefix, '*']));
test_files=dir(fullfile('', [test_prefix, '*']));

rbers=1e-4:0.005:1e-1;

bers_viterbi=zeros(1, length(rbers));
bers_turbo=zeros(1, length(rbers));
bers_no_correction=zeros(1, length(rbers));
data_len=728; % 91 bytes

for i = 1:length(rbers)
    
    for j = 1:length(raw_files)

        raw_bits=hex_to_binary(fileread(raw_files(j).name));
        test_bits=hex_to_binary(fileread(test_files(j).name));


        raw_bits=bsc(raw_bits, rbers(i));
    
        [corrected_bits_viterbi, corrected_bits_turbo, not_corrected]=correct_bits(raw_bits);
    
        bers_viterbi(i)=bers_viterbi(i)+biterr(corrected_bits_viterbi(1:data_len), test_bits)/data_len;
        bers_turbo(i)=bers_turbo(i)+biterr(corrected_bits_turbo(1:data_len), test_bits)/data_len;
        bers_no_correction(i)=bers_no_correction(i)+biterr(not_corrected(1:data_len), test_bits)/data_len;

    end
    bers_viterbi(i)=bers_viterbi(i)/length(raw_files);
    bers_turbo(i)=bers_viterbi(i)/length(raw_files);
    bers_no_correction(i)=bers_no_correction(i)/length(raw_files);
end

figure
loglog(rbers, bers_no_correction);
hold on
loglog(rbers, bers_viterbi);
loglog(rbers, bers_turbo);
hold off
xlim([1e-4 1e-1])
set(gca, 'XDir','reverse')
xlabel('rber');
ylabel('uber');
legend('no correction', 'viterbi','turbo');


function [corrected_viterbi, corrected_turbo, not_corrected] = correct_bits(raw_bits)

arguments
    raw_bits (1, 7200)
end
 
    demasked_bits=demask(raw_bits);
    decycled_bits=decycle_buffer(demasked_bits);
    [S, P1, P2] = deinterlace(decycled_bits);
    deinterleaved_bit_arrays = deinterleave({S, P1, P2});
    [S, P1, P2] = deinterleaved_bit_arrays{:};

    not_corrected=S;
    corrected_viterbi=viterbi(S, P1);
    num_iters=6;
    corrected_turbo=turbo(S, P1, P2, num_iters);

end

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

function corrected_bits=turbo(S, P1, P2, num_iters)

interleave_indices = mod((43*(1:1408) + 88*(1:1408).^2),1408)+1;
% create deinterleave indices given interleave indices
deinterleave_indices=zeros(1, length(interleave_indices));
for i=1:length(interleave_indices)
    deinterleave_indices(interleave_indices(i))=i;
end

max_degree=3;
constraint_length=max_degree+1;
% 5 is standard for conv codes with rate of 1/2
tb=5*constraint_length;

trellis=poly2trellis(constraint_length, [13 15], 13);

for n=1:num_iters

    % P1
    code1=[S;P1];
    code1=code1(:).';


    % REMEMBER TO MULTIPLY IN MINUS 1 IF SOFT DEICSION
    corrected_bits1=vitdec(code1,trellis,tb,'trunc','hard');

    corrected_bits1=corrected_bits1(deinterleave_indices);

    % P2

    S_interleaved=S(interleave_indices);

    code2=[S_interleaved;P2];
    code2=code2(:).';


    % REMEMBER TO MULTIPLY IN MINUS 1 IF SOFT DEICSION
    corrected_bits2=vitdec(code2,trellis,tb,'trunc','hard');

    corrected_bits2=corrected_bits2(deinterleave_indices);

    % majority vote - old S, corrected_bits1, corrected_bits2
    S=mode([S; corrected_bits1; corrected_bits2],1);
end
corrected_bits=S;

end

function corrected_bits=turbo1(S, P1, P2, num_iters)

    interleave_indices = mod((43*(1:1408) + 88*(1:1408).^2),1408)+1;
    % create deinterleave indices given interleave indices
    deinterleave_indices=zeros(1, length(interleave_indices));
    for i=1:length(interleave_indices)
        deinterleave_indices(interleave_indices(i))=i;
    end

    max_degree=3;
    constraint_length=max_degree+1;
    % 5 is standard for conv codes with rate of 1/2
    tb=5*constraint_length;

    trellis=poly2trellis(constraint_length, [13 15], 13);

    for n=1:num_iters

        % P1
        code1=[S;P1];
        code1=code1(:).';


        % REMEMBER TO MULTIPLY IN MINUS 1 IF SOFT DEICSION
        corrected_bits1=vitdec(code1,trellis,tb,'trunc','hard');

        corrected_bits1=corrected_bits1(deinterleave_indices);

        % P2

        S_interleaved=S(interleave_indices);

        code2=[S_interleaved;P2];
        code2=code2(:).';


        % REMEMBER TO MULTIPLY IN MINUS 1 IF SOFT DEICSION
        corrected_bits2=vitdec(code2,trellis,tb,'trunc','hard');

        corrected_bits2=corrected_bits2(deinterleave_indices);

        % majority vote - old S, corrected_bits1, corrected_bits2
        S=mode([S; corrected_bits1; corrected_bits2],1);
    end
    corrected_bits=S;

end


% bits array consists S, P1, P2 and this function deinterleaves them all
function deinterleaved_bit_arrays = deinterleave(bits_array)
    
    deinterleaved_bit_arrays={NaN, NaN, NaN};
    
    interleave_indices = [1,17,9,25,5,21,13,29,3,19,11,27,7,23,15,31,2,18,10,26,6,22,14,30,4,20,12,28,8,24,16,32];
    % create deinterleave indices given interleave indices
    deinterleave_indices=zeros(1, length(interleave_indices));
    for i=1:length(interleave_indices)
        deinterleave_indices(interleave_indices(i))=i;
    end
    
    for k = 1:length(bits_array)

        bits = bits_array{k};

        bits = insert_dummy(bits, interleave_indices);

        % put as cols
        bits=reshape(bits, 45, []);
        
        % deinterleave
        deinterleaved_bits=bits(:, deinterleave_indices);
    
        % rows to vector
    
        deinterleaved_bits=deinterleaved_bits.';
        deinterleaved_bits=deinterleaved_bits(:).';
    
        % remove 28 dummy values
    
        deinterleaved_bits=deinterleaved_bits(29:end);

        deinterleaved_bits=deinterleaved_bits(1:end-4);

        % add to result array

        deinterleaved_bit_arrays{k}=deinterleaved_bits;


    end

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

    demasked_bits=demasked_bits(1:num_bits_post_correction_code);
    decycled_bits=circshift(demasked_bits, num_bits_post_correction_code-start_idx+1);

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