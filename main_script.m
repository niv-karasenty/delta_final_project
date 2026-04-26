clear
close all
clc

processed_bits_file_name = 'processed_bits/processed_bits12_Feb_2026_13_34_28_250.txt';
parsed_data_file_name = 'parsed_data/parsed_data12_Feb_2026_13_34_28_250.txt';
base_folder = 'processed_bits/';
processed_bits_file_names = dir('processed_bits');
processed_bits_file_names = {processed_bits_file_names(~[processed_bits_file_names.isdir]).name}';
coords = [];

for i = 1
    curr_file_name = append(base_folder, string(processed_bits_file_names(i)));
    curr_file_text = fileread(curr_file_name(1));
    curr_file_bits = de2bi(sscanf(curr_file_text, '%2x')).';
    curr_file_bits = curr_file_bits(:);
    information = info_parsing(curr_file_bits, curr_file_name);
    writestruct(information, (extractBetween(curr_file_name,42,53) + '.json'));

    figure;
    title('drone coordinates')
    geoscatter([information.app_lat, information.home_lat], [information.app_long, information.home_long], 'filled');
    geolimits([information.app_lat-0.05, information.app_lat+0.05], [information.app_long-0.05, information.app_long+0.05])
    geobasemap streets;
end


