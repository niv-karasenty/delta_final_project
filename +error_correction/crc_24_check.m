function err = crc_24_check(bit_vec, poly)

arguments
    bit_vec (1,:)
    poly="z^24 + z^23 + z^18 + z^17 + z^14 + z^11 + z^10 + z^7 + z^6 + z^5 + z^4 + z^3 + z + 1"
end

crcConf = crcConfig(Polynomial=poly);
[~, err] = crcDetect(logical(bit_vec).', crcConf);

end