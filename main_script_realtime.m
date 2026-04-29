usrpContinuousCapture()


    

% if len > 0
%     scope(data);
% 
%     nfft = length(data);
%     psd = 10*log10(abs(fftshift(fft(data))).^2 / nfft);
%     freqVector = linspace(-sampleRate/2, sampleRate/2, nfft) + centerFreq;
% 
%     for i = 1:length(targetFreqs)
%         [~, idx] = min(abs(freqVector - targetFreqs(i)));
% 
%         if psd(idx) > threshold
%             fprintf('!!! Signal detected at %.4f GHz | Power: %.2f dB !!!\n', ...
%                 targetFreqs(i)/1e9, psd(idx));
%         end
%     end
% end

% Plot a nice map
% figure
% geoscatter([information.app_lat, information.home_lat], [information.app_long, information.home_long], 'filled');
% geolimits([information.app_lat-0.05, information.app_lat+0.05], [information.app_long-0.05, information.app_long+0.05])
% geobasemap streets;



%% Functions
function usrpContinuousCapture()

centerFrequency  = 2.4295e9;
sampleRate       = 10e6;
samplesPerBlock  = 30000; 
gain             = 30;
numBlocks        = Inf;

radio = comm.SDRuReceiver( ...
    'Platform',           'B210', ...
    'SerialNum',          '3591273',  ... 
    'CenterFrequency',    centerFrequency, ...
    'MasterClockRate',    sampleRate*4, ... 
    'DecimationFactor',   4, ...
    'Gain',               gain, ...
    'OutputDataType',     'double', ...
    'ChannelMapping',     1); 

disp(radio);

blockIdx = 0;
try
    while blockIdx < numBlocks
        blockIdx = blockIdx + 1;

        samples = capture(radio, samplesPerBlock, 'Samples');

        % if length(samples) ~= samplesPerBlock
        %     warning('Block %d: expected %d samples, got %d', ...
        %         blockIdx, samplesPerBlock, length(samples));
        %     continue;
        % end
        symbols=raw_samples_to_synced.drone_id_demod(samples, sampleRate).';

        if ~isempty(symbols)
            disp('found data!!!!!!!!!!')
            % Get information from synced samples
            raw_bits = get_raw_bits(symbols, 1, 1);

            [information, is_valid] = process_bits(raw_bits,'');
            information.crc_valid = is_valid;
            
        else
            disp(max(abs(samples)));
        end
    end
catch ME
    fprintf('Error during capture (block %d): %s\n', blockIdx, ME.message);
    release(radio);
    rethrow(ME);
end

release(radio);
fprintf('Done. Processed %d blocks.\n', blockIdx);
end

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
