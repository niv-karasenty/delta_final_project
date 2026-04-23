function is_valid = CRC_check(bits)
% Checking crc code
arguments (Input)
    bits % input bits
end

arguments (Output)
    is_valid (1,1) % Shows wether the validation of the packet
end


crc_obj = crcConfig(Polynomial='z^16 + z^11 + z^4 + 1', InitialConditions=[0 1 0 0 1 0 0 1 0 1 1 0 1 1 0 0]);
[num_of_err, is_valid] = crcDetect(bits.', crc_obj);
is_valid = ~is_valid;
end