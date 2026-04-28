clear
close all
clc

fs=10e6;

path = 'raw_samples/';
listing = dir(path); % Get all contents
% Filter out items that are directories
raw_sample_files = listing(~[listing.isdir]); 
% Extract just the names into a cell array
raw_sample_files={raw_sample_files.name};
raw_sample_files=strcat(path,raw_sample_files);

for k=1
    synced_samples=raw_samples_to_synced.drone_id_demod(raw_sample_files{k}, fs).';

    % Get information from synced samples
    raw_bits = get_raw_bits(synced_samples, 1, 1);

    [information, is_valid] = process_bits(raw_bits, raw_sample_files{k});
    information.crc_valid = is_valid;

    % Plot a nice map
    geoscatter([information.app_lat, information.home_lat], [information.app_long, information.home_long], 'filled');
    geolimits([information.app_lat-0.05, information.app_lat+0.05], [information.app_long-0.05, information.app_long+0.05])
    geobasemap streets;
end



%% Functions
function raw_bits = get_raw_bits(samples, p, q)
arguments (Input)
    samples(:,:) % Synced samples array
    p (1,1) % Resampled nominator
    q (1,1) % Resamples denominator
end

arguments (Output)
    raw_bits (1,:) % Raw bits with errors
end

% QPSK
M = 4; % QPSK order
ini_phase = 1*p/4;

symbols = samples(:); % Return to a vector form

raw_symbols = pskdemod(symbols, M, ini_phase, 'gray');

% decimal to binary
raw_bits = de2bi(raw_symbols).';
raw_bits = raw_bits(:);

end

% Procces bits, error correction
function [data, is_valid] = process_bits(raw_bits, file_name)
arguments (Input)
    raw_bits (1,7200) % all bits from message
    file_name % Current file name
end

arguments (Output)
    data % Data file of all needed information
    is_valid % The code is validated using crc 24
end

corrected_bits = error_correction.correct_bits(raw_bits);

% Check corrected bits using crc 24
is_valid = ~error_correction.crc_24_check(corrected_bits);

corrected_bits = corrected_bits(1:91*8); % Cut only information bits

% flip bits in each byte
corrected_bits = flip(reshape(corrected_bits, 8, []), 1);
corrected_bits = corrected_bits(:);

data = info_parsing(corrected_bits, file_name);
end
