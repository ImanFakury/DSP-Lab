%% Part 1
[x, fs] = audioread('my_audio.m4a');
x = mean(x, 2); 
t = (0:length(x)-1) / fs; 

figure; 
plot(t, x); 
title('Audio Signal');
xlabel('t (seconds)');
ylabel('Amplitude');
grid on;
 
%% Part 2
[x_music, fs_music] = audioread('my_music.m4a');
x_music = mean(x_music, 2);

L_speech = length(x);
nfft_speech = 2^nextpow2(L_speech); 
X_speech = fft(x, nfft_speech);
f_axis_speech = (0:nfft_speech/2-1) * (fs/nfft_speech);
mag_speech = 2 * abs(X_speech(1:nfft_speech/2)) / L_speech;

L_music = length(x_music);
nfft_music = 2^nextpow2(L_music); 
X_music = fft(x_music, nfft_music);
f_axis_music = (0:nfft_music/2-1) * (fs_music/nfft_music);
mag_music = 2 * abs(X_music(1:nfft_music/2)) / L_music;

figure; 
subplot(2, 1, 1);
plot(f_axis_speech, mag_speech);
title('Spectrum of Voice Signal');
xlabel('f (Hz)');
ylabel('|X(f)|');
xlim([20 20000]); 
grid on;

subplot(2, 1, 2);
plot(f_axis_music, mag_music);
title('Spectrum of Music Signal');
xlabel('f (Hz)');
ylabel('|X(f)|');
xlim([20 20000]); 
grid on;

%% Part 3
figure;
win_len_1 = 512;
window_1 = hamming(win_len_1);
overlap_1 = round(win_len_1 / 2); 

subplot(2, 2, 1); 
spectrogram(x, window_1, overlap_1, win_len_1, fs, 'yaxis'); 
title('Hamming, Length = 512');

win_len_2 = 256;
window_2 = hamming(win_len_2);
overlap_2 = round(win_len_2 / 2);

subplot(2, 2, 2);
spectrogram(x, window_2, overlap_2, win_len_2, fs, 'yaxis');
title('Hamming, Length = 256');

window_rect = rectwin(win_len_1);

subplot(2, 2, 3);
spectrogram(x, window_rect, overlap_1, win_len_1, fs, 'yaxis');
title('Rectangular, Length = 512');

window_hann = hann(win_len_1);

subplot(2, 2, 4);
spectrogram(x, window_hann, overlap_1, win_len_1, fs, 'yaxis');
title('Hann, Length = 512');