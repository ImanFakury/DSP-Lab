clc;
clear;
close all;

%% Part 1 & 2

fs = 8000;
T_c = 0.2;
T_s = 0.2;

chars_to_test = '123456789';

[sig_clean, total_time] = dtmf_generate(chars_to_test,T_c,T_s,fs);

soundsc(sig_clean,fs);
pause(total_time + 0.5);

audiowrite('my_dtmf_tones.wav', sig_clean, fs); 
disp('Audio successfully saved as my_dtmf_tones.wav');

%% Part 3

N = 200;
overlap = 100;
threshold = 60;

detected_string = dtmf_detect(sig_clean,fs,N,overlap,threshold);

disp(['Clean Detection: ' detected_string])

%% Part 4

chars_to_test = '1590*#2468';

[sig_test,~] = dtmf_generate(chars_to_test,T_c,T_s,fs);

snr_db = 10;

sig_noisy = awgn(sig_test,snr_db,'measured');

detected_10db = dtmf_detect(sig_noisy,fs,N,overlap,threshold);

disp(['Detection at 10 dB: ' detected_10db])

%% Threshold search at 10 dB

thresholds = 20:5:120;
num_trials = 100;

best_pd = 0;
best_threshold = threshold;

for th = thresholds

    success = 0;

    for k = 1:num_trials

        noisy_sig = awgn(sig_test,10,'measured');

        det = dtmf_detect(noisy_sig,fs,N,overlap,th);

        if strcmp(det,chars_to_test)
            success = success + 1;
        end

    end

    pd = success/num_trials;

    if pd > best_pd
        best_pd = pd;
        best_threshold = th;
    end

end

threshold = best_threshold;

disp(['Best Threshold = ' num2str(threshold)])
disp(['Pd at 10 dB = ' num2str(best_pd)])

%% Probability of Detection vs SNR

snr_range = 0:20;

num_trials = 100;

P_d = zeros(size(snr_range));

for i = 1:length(snr_range)

    success = 0;

    for k = 1:num_trials

        noisy_sig = awgn(sig_test,snr_range(i),'measured');

        det = dtmf_detect(noisy_sig,fs,N,overlap,threshold);

        if strcmp(det,chars_to_test)
            success = success + 1;
        end

    end

    P_d(i) = success/num_trials;

end

figure
plot(snr_range,P_d,'LineWidth',2)
grid on
title('Probability of Detection vs SNR')
xlabel('SNR (dB)')
ylabel('P_d')

%% 

function [sig,total_time] = dtmf_generate(chars,T_c,T_s,fs)

f_row = [697 770 852 941];
f_col = [1209 1336 1477];

keypad = ['1' '2' '3';
          '4' '5' '6';
          '7' '8' '9';
          '*' '0' '#'];

t_c = 0:1/fs:T_c-1/fs;

silence = zeros(1,round(T_s*fs));

sig = [];

for k = 1:length(chars)

    [r,c] = find(keypad == chars(k));

    tone = sin(2*pi*f_row(r)*t_c) + ...
           sin(2*pi*f_col(c)*t_c);

    sig = [sig tone silence];

end

total_time = length(sig)/fs;

end

%% 

function detected = dtmf_detect(sig,fs,N,overlap,threshold)

f_row = [697 770 852 941];
f_col = [1209 1336 1477];

keypad = ['1' '2' '3';
          '4' '5' '6';
          '7' '8' '9';
          '*' '0' '#'];

step = N - overlap;

num_frames = floor((length(sig)-N)/step) + 1;

detected = '';

last_char = '';

for k = 1:num_frames

    idx = (k-1)*step + 1 : (k-1)*step + N;

    frame = sig(idx);

    t = (0:N-1)/fs;

    W_row = zeros(1,4);

    for i = 1:4

        wc = sum(frame .* cos(2*pi*f_row(i)*t));
        ws = sum(frame .* sin(2*pi*f_row(i)*t));

        W_row(i) = sqrt(wc^2 + ws^2);

    end

    W_col = zeros(1,3);

    for i = 1:3

        wc = sum(frame .* cos(2*pi*f_col(i)*t));
        ws = sum(frame .* sin(2*pi*f_col(i)*t));

        W_col(i) = sqrt(wc^2 + ws^2);

    end

    [max_row,row_idx] = max(W_row);
    [max_col,col_idx] = max(W_col);

    if max_row > threshold && max_col > threshold

        curr_char = keypad(row_idx,col_idx);

        if isempty(last_char)

            detected = [detected curr_char];
            last_char = curr_char;

        end

    else

        last_char = '';

    end

end

end