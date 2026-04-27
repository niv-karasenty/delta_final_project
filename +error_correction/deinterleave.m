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

        bits = error_correction.insert_dummy(bits, interleave_indices);

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