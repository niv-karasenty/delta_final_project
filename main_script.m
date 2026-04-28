clear
close all
clc

base_folder = 'synced_samples/';
synced_samples_name = dir('synced_samples');
synced_samples_name = {synced_samples_name(~[synced_samples_name.isdir]).name}';

raw_hex=fileread("raw_bits/raw_bits_12_Feb_2026_09_30_39_442.txt");
raw_bits = error_correction.hex_to_binary(raw_hex);

for i = 1
    curr_samples_file_name = append(base_folder, string(synced_samples_name(i)));
    file_id = fopen(curr_samples_file_name, 'rb');
    raw_samples = fread(file_id, inf, 'float32');
    raw_samples = raw_samples(1:2:end) + 1j*raw_samples(2:2:end);
    fclose(file_id);

    raw_bits = demodulate_samples(raw_samples, 1, 1);
end

information = process_bits(raw_bits, curr_samples_file_name);
geoscatter([information.app_lat, information.home_lat], [information.app_long, information.home_long], 'filled');
geolimits([information.app_lat-0.05, information.app_lat+0.05], [information.app_long-0.05, information.app_long+0.05])
geobasemap streets;

%% Functions
function raw_bits = get_raw_bits(samples, p, q)
arguments (Input)
    samples(1,:) % Synced samples array
    p (1,1) % Resampled nominator
    q (1,1) % Resamples denominator
end

arguments (Output)
    raw_bits (1,:) % Raw bits with errors
end



end

function data = process_bits(raw_bits, file_name)
arguments (Input)
    raw_bits (1,7200) % all bits from message
    file_name % Current file name
end

arguments (Output)
    data % Data file of all needed information
end

[corrected_bits, ~] = error_correction.correct_bits(raw_bits);
corrected_bits = corrected_bits(1:91*8); % Cut only information bits

% flip bits in each byte
corrected_bits = flip(reshape(corrected_bits, 8, []), 1);
corrected_bits = corrected_bits(:);

data = info_parsing(corrected_bits, file_name);
end
