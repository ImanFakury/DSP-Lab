clear; clc; close all;

%% Part 1
filename = 'IQSignal.wav';
[raw_signal, fs] = audioread(filename);
I = raw_signal(:, 1);
Q = raw_signal(:, 2);
complex_sig = I + 1i * Q;

%% Part 2
N = length(complex_sig);
f_axis = (-N/2 : N/2-1) * (fs / N);
sig_spectrum = fftshift(fft(complex_sig));
figure;
plot(f_axis, 20*log10(abs(sig_spectrum)/max(abs(sig_spectrum))));
title('Spectrum of Raw IQ Signal');
xlabel('Frequency (Hz)'); 
ylabel('Magnitude (dB)');
grid on;

%% Part 3
[b_mono, a_mono] = butter(5, 15000 / (fs/2), 'low');
[b_pilot, a_pilot] = butter(4, [18500 19500] / (fs/2), 'bandpass');
[b_diff, a_diff] = butter(4, [23000 53000] / (fs/2), 'bandpass');
[b_rds, a_rds] = butter(4, [55000 59000] / (fs/2), 'bandpass');
[b_rds_lp, a_rds_lp] = butter(4, 2500 / (fs/2), 'low'); 

frame_size = fs * 0.1; 
num_frames = floor(length(complex_sig) / frame_size);
audio_fs = 48000; 
dec_factor = floor(fs / audio_fs);

left_audio_full = [];
right_audio_full = [];
rds_baseband_full = [];

figure; 

for k = 1:num_frames
    idx = (k-1)*frame_size + 1 : k*frame_size;
    frame = complex_sig(idx);
    
    instPhase = unwrap(angle(frame));
    demod = diff(instPhase);
    demod = demod - mean(demod); 
    demod = [demod; 0]; 
    
    %% Part 4
    if k == 1
        N_demod = length(demod);
        f_demod = (-N_demod/2 : N_demod/2-1) * (fs / N_demod);
        spec_demod = fftshift(fft(demod));
        plot(f_demod, abs(spec_demod));
        title('Spectrum of Demodulated Message (Frame 1)');
        xlabel('Frequency (Hz)'); 
        ylabel('Magnitude');
        grid on;
        drawnow;
    end
    
    %% Part 5
    L_plus_R = filter(b_mono, a_mono, demod);
    
    pilot = filter(b_pilot, a_pilot, demod);
    
    carrier_38k = pilot .^ 2; 
    carrier_38k = carrier_38k - mean(carrier_38k); 
    
    L_minus_R_mod = filter(b_diff, a_diff, demod);
    
    L_minus_R_base = L_minus_R_mod .* sign(carrier_38k);
    L_minus_R = filter(b_mono, a_mono, L_minus_R_base);
    
    Left = (L_plus_R + L_minus_R) / 2;
    Right = (L_plus_R - L_minus_R) / 2;
    
    Left_dec = decimate(Left, dec_factor);
    Right_dec = decimate(Right, dec_factor);
    
    left_audio_full = [left_audio_full; Left_dec];
    right_audio_full = [right_audio_full; Right_dec];
    
    %% Part 6
    rds_mod = filter(b_rds, a_rds, demod);
    
    carrier_57k = pilot .^ 3; 
    carrier_57k = carrier_57k - mean(carrier_57k);
    
    rds_base = rds_mod .* sign(carrier_57k);
    rds_filtered = filter(b_rds_lp, a_rds_lp, rds_base);
    
    rds_baseband_full = [rds_baseband_full; rds_filtered];
end

%% Part 5
stereo_audio = [left_audio_full, right_audio_full];
stereo_audio = stereo_audio / max(abs(stereo_audio(:))); 
disp('Playing extracted stereo audio...');
sound(stereo_audio, fs/dec_factor);
audiowrite('ExtractedAudio.wav', stereo_audio, audio_fs);

%% Part 6
rds_symbol_rate = 1187.5;
samples_per_symbol = fs / rds_symbol_rate;
step_size = max(1, round(samples_per_symbol / 2));
max_idx = length(rds_baseband_full);
rds_downsampled = rds_baseband_full(1:step_size:max_idx);

raw_bits = rds_downsampled > 0;
decoded_bits = zeros(floor(length(raw_bits)/2) - 1, 1);

for i = 1:length(decoded_bits)
    decoded_bits(i) = ~(raw_bits(2*i-1) ~= raw_bits(2*i+1));
end

message_chars = '';
for i = 1:8:(length(decoded_bits)-7)
    byte_str = sprintf('%d', decoded_bits(i:i+7));
    byte_val = bin2dec(byte_str);
    if byte_val >= 32 && byte_val <= 126
        message_chars = [message_chars, char(byte_val)];
    else
        message_chars = [message_chars, '.']; 
    end
end

disp('==================================================');
disp('              RDS EXTRACTION RESULTS              ');
disp('==================================================');
fprintf(' -> Baseband Samples Processed: %d\n', length(rds_baseband_full));
fprintf(' -> Demodulated RDS Bits:       %d\n', length(decoded_bits));
fprintf(' -> Decoded Bytes (Blocks):     %d\n', floor(length(decoded_bits)/8));
disp('--------------------------------------------------');

disp('First 64 Bits (Formatted):');
bit_string = sprintf('%d', decoded_bits(1:min(64, length(decoded_bits))));
formatted_bits = regexprep(bit_string, '(.{8})', '$1 ');
fprintf('    %s\n', formatted_bits);
disp('--------------------------------------------------');

disp('Extracted ASCII Stream (Garbage masked with ''.''):');
max_print = min(150, length(message_chars)); 
for i = 1:50:max_print
    chunk_end = min(i+49, max_print);
    fprintf('    %s\n', message_chars(i:chunk_end));
end
disp('==================================================');