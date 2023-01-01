
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% Check Script for NOAA signals %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
clear all;
close all;

% Experimental signal
[exp, Fs1] = audioread("grabaciones/NOAA15_5min.wav");
% Theorical signal (from web)
[teo, fs] = audioread("pruebas_wav/090729 1428 noaa-18.wav");

T1 = 1 / Fs1;
T2 = 1 / fs;
t1 = (0:length(exp)-1) * T1;
t2 = (0:length(teo)-1) * T2;


%% Testing the experimental signal

% It is necessary to enhance the experimental signal in order to display the
%APT image correctly (increasing the amplitude)
exp = exp .* 20;
%audiowrite("grabaciones/NOAA15_5min_amplificada.wav", exp, Fs1);

% Signals in the time domain
figure(1);
plot(t2, teo);
hold on
plot(t1, exp);
legend({'theorical', 'experimental'});
title('APT signal time domain');
xlabel('Time(s)');
ylabel('Amplitude');

% Signals in the frequency domain
figure(2);
[Pxx, Fxx] = pwelch(exp,4096,2048,4096,Fs1, 'centered','power');
plot(Fxx, 10*log10(Pxx));
title('Experimental');
xlim([-Fs1/2 Fs1/2]);
xlabel('Frequency (Hz)');
ylabel('Amplitude (dB)');

figure(3);
[Pxx, Fxx] = pwelch(teo,4096,2048,4096,Fs2, 'centered','power');
plot(Fxx, 10*log10(Pxx));
title('Theorical');
xlim([-Fs2/2 Fs2/2]);
xlabel('Frequency (Hz)');
ylabel('Amplitude (dB)');
% We can identify the subcarrier at 2.4 kHz which contains the main
% information about the image (APT Video Signal).

% Multiplying the signal with a -2.4 kHz local oscilator, we obtain the
% base band signal of the subcarrier
exp100kHz = resample(exp, 8, 3);
Fs3 = 100e3;
T3 = 1 / Fs3;
t3 = (0:length(exp100kHz)-1) * T3;
LO = cos(2 * pi * (-2.4e3) * t3)';
BB = exp100kHz .* LO;

% figure(4);
% [Pxx, Fxx] = pwelch(BB,4096,2048,4096,Fs3, 'centered','power');
% plot(Fxx, 10*log10(Pxx));
% xlim([-Fs3/2 Fs3/2]);
% title('Base Band Subcarrier');
% xlabel('Frequency (Hz)');
% ylabel('Amplitude (dB)');


%Low pass filter to purge the armonics
[A, B] = butter(4,2e3/(Fs3/2)); %[b,a] = butter(nth,fc/(fs/2));
%freqz(A, B);
APT_image = filter(B, A, BB);
APT_image = resample(APT_image, 1, 10); Fs4 = 10e3;

figure(5);
[Pxx, Fxx] = pwelch(APT_image,4096,2048,4096,Fs4, 'centered','power');
plot(Fxx, 10*log10(Pxx));
title('APT Video signal');
xlim([-Fs4/2 Fs4/2]);
xlabel('Frequency (Hz)');
ylabel('Amplitude (dB)');
%From this moment, we could build the APT image with this information






