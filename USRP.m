centerFreq = 2.4295e9;
targetFreqs=[2.4295e9];
% [2.3995, 2.4145, 2.4295, 2.4445, 2.4595];
% [5.7965, 5.7765, 5.7565]
fs = 15e6;
threshold=-10;

rx = comm.SDRuReceiver(...
    'Platform',             'B210', ...
    'SerialNum',            '3591273', ... 
    'CenterFrequency',      centerFreq, ...
    'MasterClockRate',      fs, ...
    'SampleRate',           fs, ...
    'Gain',                 20, ...
    'OutputDataType',       'double', ...
    'SamplesPerFrame', 362);

scope = spectrumAnalyzer(...
    'SampleRate',           fs, ...
    'CenterFrequency',      centerFreq, ...
    'SpectrumType',         'Power density', ...
    'YLimits',              [-120 -20], ...
    'Title',                'USRP B210 Real-time Spectrum');

showNotification = true;

disp('Starting signal detection... Press Ctrl+C to stop.');


while true
    [data, len] = rx();
    

    if len > 0
        scope(data);

        nfft = length(data);
        psd = 10*log10(abs(fftshift(fft(data))).^2 / nfft);
        freqVector = linspace(-fs/2, fs/2, nfft) + centerFreq;

        for i = 1:length(targetFreqs)
            [~, idx] = min(abs(freqVector - targetFreqs(i)));

            if psd(idx) > threshold
                fprintf('!!! Signal detected at %.4f GHz | Power: %.2f dB !!!\n', ...
                    targetFreqs(i)/1e9, psd(idx));
            end
        end
    end
end


release(rx);
release(scope);