function bits = hex_to_binary(hex)
    
    % convert to array such that each element is 2 chars (Byte)
    hex=regexp(hex, '.{1,2}', 'match');
    
    bits = de2bi(hex2dec(hex), 'left-msb');
    
    % flatten
    bits = reshape(bits.', 1, []);

end