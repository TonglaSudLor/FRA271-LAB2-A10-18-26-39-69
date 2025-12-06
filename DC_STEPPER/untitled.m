% Load the data from the .mat file
%data = load('New_Export.mat');

% Assuming the .mat file contains variables 'time' and 'data'
time = ex2{1}.Values.Time;
signal = ex2{1}.Values.Data;

% Apply FFT to the signal
N = length(signal);
Y = fft(signal);

% Compute the frequency axis
Fs = 1 / (time(2) - time(1)); % Sampling frequency
f = (0:N-1)*(Fs/N); % Frequency range

% Plot the original signal
figure;
subplot(2, 1, 1); % Create a subplot for the original signal
plot(time, signal);
title('Original Signal');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

% Plot the FFT result
subplot(2, 1, 2); % Create a subplot for the FFT
plot(f, abs(Y));
title('FFT of the Signal');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
xlim([0 Fs/2]); % Display only the positive frequencies
grid on;