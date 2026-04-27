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
