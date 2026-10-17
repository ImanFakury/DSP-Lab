clear; clc; close all;

%% Setup & Parameters
filename = 'IQSignal.wav';
[raw_signal, fs] = audioread(filename);
complex_sig = raw_signal(:, 1) + 1i * raw_signal(:, 2);

frame_size = 1024; 
num_frames = floor(length(complex_sig) / frame_size);

audioFs = 48000;
dec_factor = floor(fs / audioFs);

h1 = fir1(64, 100000 / (fs/2)); 
h2 = fir1(64, (audioFs/2) / (fs/2)); 
h3 = fir1(64, 15000 / (audioFs/2)); 

%% Initialization
saveOLPIn1 = zeros(length(h1)-1, 1);
saveOLPIn2 = zeros(length(h2)-1, 1);
saveOLPIn3 = zeros(length(h3)-1, 1);

prev_last_phase = 0;
idx_init = 1;
audio_out = [];

%% Block Processing
for k = 1:num_frames
    idx = (k-1)*frame_size + 1 : k*frame_size;
    frame = complex_sig(idx);
    
    % Step 1: LPF IQ Signal
    [sigFilt, saveOLPIn1] = ols(h1, frame, saveOLPIn1);
    
    % Step 2: Phase Detection 
    current_phase = unwrap(angle(sigFilt));
    if k > 1
        offset = round((current_phase(1) - prev_last_phase) / (2*pi)) * 2*pi;
        current_phase = current_phase - offset;
    end
    demod = diff([prev_last_phase; current_phase]);
    prev_last_phase = current_phase(end);
    
    % Step 3: Decimation Filtering & Downsampling
    [sigDecFilt, saveOLPIn2] = ols(h2, demod, saveOLPIn2);
    
    step_idx = idx_init : dec_factor : length(sigDecFilt);
    if isempty(step_idx)
        sigDown = [];
        idx_init = idx_init - length(sigDecFilt);
    else
        sigDown = sigDecFilt(step_idx);
        idx_init = step_idx(end) - length(sigDecFilt) + dec_factor;
    end
    
    % Step 4: Audio LPF
    if ~isempty(sigDown)
        [audio_block, saveOLPIn3] = ols(h3, sigDown, saveOLPIn3);
        audio_out = [audio_out; audio_block];
    end
end

%% Plots & Output
audio_out = audio_out / max(abs(audio_out));
disp('Processing complete. Playing audio...');
sound(audio_out, audioFs);

N_out = length(audio_out);
f_axis = (-N_out/2 : N_out/2-1) * (audioFs / N_out);
spec_out = fftshift(fft(audio_out));

figure;
subplot(2,1,1);
plot((1:2000)/audioFs, audio_out(10000:11999));
title('Demodulated Audio with OLS (Time Domain)');
xlabel('Time (s)'); 
ylabel('Amplitude');
grid on;

subplot(2,1,2);
plot(f_axis, 20*log10(abs(spec_out)/max(abs(spec_out))));
title('Spectrum of Demodulated Audio');
xlabel('Frequency (Hz)'); 
ylabel('Magnitude (dB)');
xlim([-20000 20000]);
grid on;

%% Required OLS Function
function [output, saveOLPout] = ols(h, sig, saveOLPin)
    h = h(:);
    sig = sig(:);
    saveOLPin = saveOLPin(:);
    
    M = length(h);
    L = length(sig);
    N = L + M - 1;
    
    H = fft(h, N);
    X = fft([saveOLPin; sig], N);
    
    Y = H .* X;
    y_circ = ifft(Y);
    
    output = y_circ(M:end);
    saveOLPout = sig(end - M + 2 : end);
end