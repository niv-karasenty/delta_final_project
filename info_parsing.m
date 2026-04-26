function ret_struct = info_parsing(info_bits, file_name)
% Parsing information from bits after trying to correct them
arguments (Input)
    info_bits % Bits to run on
    file_name % Name of the file we run on
end 

arguments (Output)
    ret_struct % Returns all needed information
end

    info_bits = info_bits(1:91*8);
    to_degrees = 174533;
    crc_valid = CRC_check(info_bits)

    info_bits = reshape(info_bits, 8, []).'; % Organize rows as bits
    big_endian_rows = [(8:23) (70:89)];
    big_endian_info_bits = info_bits(big_endian_rows,:); % Only Big endian bytes included

    % Information parsing
    packet_length = bi2de(info_bits(1,:)); % Little endian

    Version = bi2de(info_bits(3,:));

    Sequence_number = bi2de(flip(reshape(info_bits(4:5,:).', 1, [])), 2, 'left-msb');

    % state_info = bi2de(reshape(info_bits(6:7,:), 1, []), 2, "right-msb");
    state_info = flip(reshape(flip(info_bits(6:7,:), 1).', 1, [])).';
    velocity_north_valid = state_info(14);
    velocity_east_valid = state_info(15);
    velocity_up_valid = state_info(16);

    serial_number = strip(char(bin2dec(char(flip(big_endian_info_bits(1:16,:), 2) + '0')).'));


    longitude =bi2de(flip(reshape(info_bits(24:27,:).', 1, [])), 2, 'left-msb') / to_degrees;
    latitude = bi2de(flip(reshape(info_bits(28:31,:).', 1, [])), 2, 'left-msb') / to_degrees;

    altitude = bi2de(flip(reshape(info_bits(32:33,:).', 1, [])), 2, 'left-msb');

    height = bi2de(flip(reshape(info_bits(34:35,:).', 1, [])), 2, 'left-msb');

    if (velocity_east_valid)
        velocity_east = typecast(int16(bi2de(flip(reshape(info_bits(36:37,:).', 1, [])), 2, 'left-msb')), 'int16');
    else
        velocity_east = 0;
    end
    if (velocity_north_valid)
        velocity_north = typecast(uint16(bi2de(flip(reshape(info_bits(38:39,:).', 1, [])), 2, 'left-msb')), 'int16');
    else
        velocity_north = 0;
    end
    if (velocity_up_valid)
        velocity_up = typecast(uint16(bi2de(flip(reshape(info_bits(40:41,:).', 1, [])), 2, 'left-msb')), 'int16');
    else
        velocity_up = 0;
    end

    epoch_time = bi2de(flip(reshape(info_bits(44:51,:).', 1, [])), 2, 'left-msb') / 1e3; % Epoch time in seconds
    date_time = datetime(epoch_time, 'ConvertFrom', 'posixtime', 'TimeZone', 'local');

    app_latitude = bi2de(flip(reshape(info_bits(52:55,:).', 1, [])), 2, 'left-msb')/ to_degrees;
    app_longitude = bi2de(flip(reshape(info_bits(56:59,:).', 1, [])), 2, 'left-msb') / to_degrees;

    home_latitude = bi2de(flip(reshape(info_bits(60:63,:).', 1, [])), 2, 'left-msb') / to_degrees;
    home_longitude = bi2de(flip(reshape(info_bits(64:67,:).', 1, [])), 2, 'left-msb') / to_degrees;

    device_type = bi2de(info_bits(68,:));

    UUID_length = bi2de(info_bits(69,:));
    UUID = strip(char(bin2dec(char(flip(big_endian_info_bits(17:end,:), 2) + '0')).'));

    crc_code = dec2hex(bi2de(flip(reshape(info_bits(90:91,:).', 1, [])), 2, 'left-msb'));

    ret_struct = struct('file_name', file_name, 'packet_length', packet_length, 'Version', Version, 'Sequence_number', Sequence_number, 'state_info', state_info, ...
        'serial_number', serial_number,'long', longitude, 'lat', latitude, 'alt', altitude, 'height', height, 'velocity_east', velocity_east, 'velocity_up', velocity_up, ...
        'velocity_north', velocity_north, 'current_time', date_time, 'app_lat', app_latitude, 'app_long', app_longitude, 'home_lat', home_latitude, 'home_long', ...
        home_longitude, 'device_type', device_type, 'UUID_len', UUID_length, 'UUID', UUID, 'CRC_code', crc_code, 'crc_valid', crc_valid);

end