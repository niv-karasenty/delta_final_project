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
