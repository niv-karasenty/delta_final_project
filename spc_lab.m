% Project

clc
close all
clear

%% ============================== Constants ==============================
FILE_NAME = "samples6.32fc";
fs = 10e6;

frequencies = [5.7965e9; 5.7765e9; 5.7565e9; 2.3995e9; 2.4145e9; 2.4295e9; 2.4445e9; 2.4595e9];

ofdm_nfft = 1024;
active_subcarriers = 213:813;
active_subcarriers_number = length(active_subcarriers);
subcarrier_spacing = 15e3;
cp_length = 72;
extended_cp_length = 80;
zc_root1 = 600;
zc_root2 = 147;

[p, q] = rat((ofdm_nfft * subcarrier_spacing) / fs);

%% ============================== Extract the samples ==============================
file_id = fopen(FILE_NAME, 'rb');
samples = fread(file_id, inf, 'float32');
samples = samples(1:2:end) + 1i*samples(2:2:end);
fclose(file_id);

samples = resample(samples, p, q);

%samples = samples(1.2e5:1.6e5); %?
%samples = samples(11.1e5:11.4e5);%2
%samples = samples(9.2e5:9.4e5);%3
%samples = samples(1.4e5:1.51e5); %4
%samples = samples(4.78e5:4.88e5); %5
samples = samples(9.43e5:9.55e5); %6
%samples = samples(2.1e5:2.205e5); %7

samples_size = length(samples);
T = samples_size / fs;
t = time_line(T, fs);

%% ============================== Basic plots ==============================
%plot(real(samples));
[freqs, amplitudes] = signal_fft(samples, fs);
%plot(freqs, abs(amplitudes))

%% ============================== Synchronization ==============================
zcseq_signal1 = create_zc_signal(zc_root1, active_subcarriers, active_subcarriers_number, cp_length, ofdm_nfft);
zcseq_signal2 = create_zc_signal(zc_root2, active_subcarriers, active_subcarriers_number, cp_length, ofdm_nfft);

range = -3000:100:-1400;
correlations = zeros(1, length(range));
for i = 1 : length(range)
    [c1, ~] = xcorr(zcseq_signal1 .* exp(2*pi*1j*range(i)*((0:length(zcseq_signal1)-1)/fs).'), samples);
    [c2, ~] = xcorr(zcseq_signal2 .* exp(2*pi*1j*range(i)*((0:length(zcseq_signal2)-1)/fs).'), samples);
    correlations(i) = max(abs(c2)) + max(abs(c1));
    disp(range(i))
end
[~, i] = max(correlations);
freq_offset = -range(i);

zcseq_signal1 = zcseq_signal1 .* exp(2*pi*1i*freq_offset*((0:length(zcseq_signal1) - 1)/fs)).';
zcseq_signal2 = zcseq_signal2 .* exp(2*pi*1i*freq_offset*((0:length(zcseq_signal2) - 1)/fs)).';

samples_offset1 = find_samples_offset(zcseq_signal1, samples) + 1;
samples_offset2 = find_samples_offset(zcseq_signal2, samples);

samples_offset2 - samples_offset1

%% ============================== Example with one symbol ==============================
symbol_signal = samples(samples_offset2-1095:samples_offset2);

symbol_signal = symbol_signal .* exp(2*pi*1j*freq_offset.*((0:length(symbol_signal)-1)/fs)).';

symbol_signal = symbol_signal(1:end - cp_length);
symbol = fftshift(fft(symbol_signal));
symbol = symbol(active_subcarriers);
scatterplot(symbol);

%% ============================== Functions ==============================
function t = time_line(T, fs); t = 0:1/fs:T-1/fs; end

function [freqs, amplitudes] = signal_fft(y, fs)
    freqs = linspace(-fs/2, fs/2, length(y));
    amplitudes = fftshift(fft(y)) / fs;
end

function offset = find_phase_offset(x, y); offset = mean(x .* conj(y)) / abs(mean(x .* conj(y))); end

% function offset = find_frequency_offset(x, y, fs)
%     combined = y .* conj(x);
%     [~, i] = max(abs(fft(combined)));
%     N = length(combined);
%     f_axis = (0:N-1)*(fs/N);
%     offset = f_axis(i);
%     if offset > fs/2, offset = offset - fs; end
% end
% 

function offset = find_samples_offset(x, y)
    if length(x) > length(y); [c, ~] = xcorr(x, y); else; [c, ~] = xcorr(y, x); end
    long_length = max(length(x), length(y));
    short_length = min(length(x), length(y));
    valid_c = c(long_length:long_length + (long_length - short_length));
    [~, offset] = max(valid_c);
    offset = offset - 1;
end

function max_correlation = find_frequency_offset(x, y, fs)
    range = -5000:100:5000;
    correlations = zeros(1, length(range));
    for i = 1 : length(range)
        [c, ~] = xcorr(x .* exp(2*pi*1j*range(i)*((0:length(x)-1)/fs).'), y);
        correlations(i) = max(abs(c));
    end
    [~, i] = max(correlations);
    max_correlation = range(i);
end

function zcseq_signal = create_zc_signal(zc_root, active_subcarriers, active_subcarriers_number, cp_length, ofdm_nfft)
    zcseq = zadoffChuSeq(zc_root, active_subcarriers_number);
    zcseq = [zeros(min(active_subcarriers) - 1, 1); zcseq; zeros(ofdm_nfft - max(active_subcarriers), 1)];
    zcseq_signal = ifft(ifftshift(zcseq));
    %zcseq_signal = [zcseq_signal; zcseq_signal(1:cp_length)];
end