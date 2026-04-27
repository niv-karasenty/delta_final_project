function raw_bits = demodulate_samples(samples, p, q)
% Demodulating synchronized samples
arguments (Input)
    samples % samples, in the time domain
    p % Resample nominator
    q % Resample denominator
end

arguments (Output)
    raw_bits % Bits after demodulating
end

fs = 15.36e6; % Current sample freq
cp_len = 72; % Samples of cp
special_cp_len = 80; % samples of cp in symbols 1 and 9
fft_size = 1024;
rel_samples = (213:813);
rel_samples(300) = []; 

% QPSK
M = 4; % QPSK order
ini_phase = 1*p/4;



% Resample samples to be in the correct format
samples = resample(samples, q, p); % Invert the resample proccess

% Remove first symbol
first_symbol_len = fft_size + special_cp_len; % Length of the first symbol
samples = samples(first_symbol_len+1:end);


symbol_len = fft_size + cp_len;
% samples(symbol_len*5+1:symbol_len*6) = []; % 6th symbol is a pilot
% samples(symbol_len*3+1:symbol_len*4) = []; % 4th symbol is a pilot

% Remove cyclic longer prefix in 9th symbol
samples(end-7:end) = [];

ofdm_matrix = reshape(samples, [], 8); % Each ofdm symbol has it's own column

% Remove pilot symbols
ofdm_matrix(:, [3,5]) = []; % We removed the first symbol so the pilot

% Remove cyclic prefix
ofdm_matrix(end-cp_len+1:end,:) = [];

fft_matrix = fftshift(fft(ofdm_matrix, fft_size)); % Get the symbols in the freq domain

% Cut relevant samlpes
fft_matrix = fft_matrix(rel_samples,:);

symbols = fft_matrix(:); % Return to a vector form

raw_bits = pskdemod(symbols, M, ini_phase, 'gray', 'OutputType', 'bit');
% raw_bits = dpskdemod(symbols, M, ini_phase, 'gray', 'OutputType', 'bit');
end