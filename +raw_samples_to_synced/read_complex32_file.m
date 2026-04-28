function iq = read_complex32_file(fname)
    fid = fopen(fname, 'rb');
    raw = fread(fid, inf, 'float32=>double');
    fclose(fid);
    iq = raw(1:2:end) + 1j*raw(2:2:end);
end
