function iq = read_complex32_file(fname)
    pwd
    fid = fopen(fname, 'rb');
    if fid < 0
        error('drone_id_demod:fileOpen', 'Cannot open file: %s', fname);
    end
    raw = fread(fid, inf, 'float32=>double');
    fclose(fid);
    if mod(numel(raw), 2) ~= 0
        error('drone_id_demod:oddLen', 'File length is odd, not interleaved I/Q.');
    end
    iq = raw(1:2:end) + 1j*raw(2:2:end);
end