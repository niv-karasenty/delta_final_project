function is_valid = CRC_check(bits)
% Checking crc code
arguments (Input)
    bits (:,1) % input bits
end

arguments (Output)
    is_valid (1,1) % Shows wether the validation of the packet 0 - invalid, 1 - valid
end

init_cond = dec2bin(hex2dec('0x496C'), 16) - '0';
crc_obj = crcConfig(Polynomial='x^16 + x^11 + x^4 + 1', InitialConditions=init_cond.', DirectMethod=1, ReflectInputBytes=1, ReflectChecksums=0);
[~, is_valid] = crcDetect(bits, crc_obj);
is_valid = ~is_valid;
end
