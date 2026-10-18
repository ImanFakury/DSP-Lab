%% Part 1.1: Loopback
fs = 16000;
frameLength = 1024;
totalTime = 10;

reader = audioDeviceReader('SampleRate', fs, 'SamplesPerFrame', frameLength);
writer = audioDeviceWriter('SampleRate', fs);
outAudio1_1 = [];
disp('1/4: Loopback active. Speak now... (10s)');
tic;
while toc < totalTime
    audioIn = reader();
    writer(audioIn);
    outAudio1_1 = [outAudio1_1; audioIn];
end
release(reader); release(writer);
audiowrite('part1_1_loopback.wav', outAudio1_1, fs);
disp('Saved part1_1_loopback.wav');
pause(2);

%% Part 1.2: Echo (Delay: 150ms, Coef: 0.5)
delayMs = 150; 
echoCoef = 0.5; 
delaySamples = round(fs * (delayMs / 1000));
delayBuffer = zeros(delaySamples, 1);
reader = audioDeviceReader('SampleRate', fs, 'SamplesPerFrame', frameLength);
writer = audioDeviceWriter('SampleRate', fs);
outAudio1_2 = [];
disp('2/4: Echo (150ms, Coef: 0.5). Speak now... (10s)');
tic;
while toc < totalTime
    audioIn = reader();
    outSignal = audioIn + echoCoef * delayBuffer(1:frameLength);
    delayBuffer = [delayBuffer(frameLength+1:end); audioIn];
    writer(outSignal);
    outAudio1_2 = [outAudio1_2; outSignal];
end
release(reader); release(writer);
audiowrite('part1_2_echo_150_05.wav', outAudio1_2, fs);
disp('Saved part1_2_echo_150_05.wav');
pause(2);

%% Part 1.3: Echo (Delay: 300ms, Coef: 0.5)
delayMs = 300; 
echoCoef = 0.5; 
delaySamples = round(fs * (delayMs / 1000));
delayBuffer = zeros(delaySamples, 1);
reader = audioDeviceReader('SampleRate', fs, 'SamplesPerFrame', frameLength);
writer = audioDeviceWriter('SampleRate', fs);
outAudio1_3 = [];
disp('3/4: Echo (300ms, Coef: 0.5). Speak now... (10s)');
tic;
while toc < totalTime
    audioIn = reader();
    outSignal = audioIn + echoCoef * delayBuffer(1:frameLength);
    delayBuffer = [delayBuffer(frameLength+1:end); audioIn];
    writer(outSignal);
    outAudio1_3 = [outAudio1_3; outSignal];
end
release(reader); release(writer);
audiowrite('part1_3_echo_300_05.wav', outAudio1_3, fs);
disp('Saved part1_3_echo_300_05.wav');
pause(2);

%% Part 1.4: Echo (Delay: 150ms, Coef: 0.9)
delayMs = 150; 
echoCoef = 0.9; 
delaySamples = round(fs * (delayMs / 1000));
delayBuffer = zeros(delaySamples, 1);
reader = audioDeviceReader('SampleRate', fs, 'SamplesPerFrame', frameLength);
writer = audioDeviceWriter('SampleRate', fs);
outAudio1_4 = [];
disp('4/4: Echo (150ms, Coef: 0.9). Speak now... (10s)');
tic;
while toc < totalTime
    audioIn = reader();
    outSignal = audioIn + echoCoef * delayBuffer(1:frameLength);
    delayBuffer = [delayBuffer(frameLength+1:end); audioIn];
    writer(outSignal);
    outAudio1_4 = [outAudio1_4; outSignal];
end
release(reader); release(writer);
audiowrite('part1_4_echo_150_09.wav', outAudio1_4, fs);
disp('Saved part1_4_echo_150_09.wav');
pause(2);

%% Part 2: Fading
fs = 16000;
frameLength = 1024;
totalTime = 10;
reader = audioDeviceReader('SampleRate', fs, 'SamplesPerFrame', frameLength);
writer = audioDeviceWriter('SampleRate', fs);
outAudio2 = [];
disp('Part 2: Fading active. Speak now... (10s)');
tic;
while toc < totalTime
    audioIn = reader();
    fadeMultiplier = max(0, 1 - (toc / totalTime)); 
    fadedAudio = audioIn * fadeMultiplier;
    writer(fadedAudio);
    outAudio2 = [outAudio2; fadedAudio];
end
release(reader); release(writer);
audiowrite('part2_fading.wav', outAudio2, fs);
disp('Saved part2_fading.wav');
pause(2);

%% Part 3: Pitch Shifting
fs = 16000;
frameLength = 1024;
totalTime = 10;
reader = audioDeviceReader('SampleRate', fs, 'SamplesPerFrame', frameLength);
writer = audioDeviceWriter('SampleRate', fs);
nSemitones = 4; 
outAudio3 = [];
disp('Part 3: Pitch shifting active. Speak now... (10s)');
tic;
while toc < totalTime
    audioIn = reader();
    audioOut = shiftPitch(audioIn, nSemitones, 'LockPhase', true);
    writer(audioOut);
    outAudio3 = [outAudio3; audioOut];
end
release(reader); release(writer);
audiowrite('part3_pitch_shift.wav', outAudio3, fs);
disp('Saved part3_pitch_shift.wav');
pause(2);

%% Part 4: Spectrum Analyzer
fs = 16000;
frameLength = 1024;
totalTime = 10;
reader = audioDeviceReader('SampleRate', fs, 'SamplesPerFrame', frameLength);
figure('Name', 'Real-Time Speech Spectrum');
f_axis = (0:frameLength/2-1) * (fs / frameLength);
outAudio4 = [];
disp('Part 4: Spectrum Analyzer running. Speak now... (10s)');
tic;
while toc < totalTime
    audioIn = reader();
    Y = fft(audioIn);
    magnitude = abs(Y(1:frameLength/2));
    plot(f_axis, magnitude, 'b', 'LineWidth', 1.2);
    title('Real-Time Speech Spectrum');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    grid on;
    ylim([0 30]);
    drawnow;
    outAudio4 = [outAudio4; audioIn];
end
release(reader);
audiowrite('part4_spectrum_input.wav', outAudio4, fs);
disp('Saved part4_spectrum_input.wav');