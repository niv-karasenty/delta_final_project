clear
close all
clc

base_folder = 'raw_bits/';
raw_bits_names = dir('raw_bits');
raw_bits_names = {raw_bits_names(~[raw_bits_names.isdir]).name}';
coords = [];

% for i = 1
%     curr_file_name = append(base_folder, string(raw_bits(i)));
%     curr_file_text = fileread(curr_file_name(1));
%     curr_file_bits = de2bi(sscanf(curr_file_text, '%2x')).';
%     curr_file_bits = curr_file_bits(:);
%     information = info_parsing(curr_file_bits, curr_file_name);
%     writestruct(information, (extractBetween(curr_file_name,42,53) + '.json'));
% 
%     figure;
%     title('drone coordinates')
%     geoscatter([information.app_lat, information.home_lat], [information.app_long, information.home_long], 'filled');
%     geolimits([information.app_lat-0.05, information.app_lat+0.05], [information.app_long-0.05, information.app_long+0.05])
%     geobasemap streets;
% end


raw_hex=fileread("raw_bits/raw_bits_12_Feb_2026_09_30_39_442.txt");
raw_bits = error_correction.hex_to_binary(raw_hex);

information = process_bits(raw_bits);
geoscatter([information.app_lat, information.home_lat], [information.app_long, information.home_long], 'filled');
geolimits([information.app_lat-0.05, information.app_lat+0.05], [information.app_long-0.05, information.app_long+0.05])
geobasemap streets;

%% Functions
function data = process_bits(raw_bits)
arguments (Input)
    raw_bits (1,7200) % all bits from message
end

arguments (Output)
    data % Data file of all needed information
end

[corrected_bits, ~] = error_correction.correct_bits(raw_bits);
corrected_bits = corrected_bits(1:91*8); % Cut only information bits
corrected_bits = flip(reshape(corrected_bits, 8, []), 1);
corrected_bits = corrected_bits(:);

data = info_parsing(corrected_bits, '09_30_40_676');
end


