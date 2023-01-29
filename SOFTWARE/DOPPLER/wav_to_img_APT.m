%% WAV TO IMAGE: DOPPLER CORRECTION
%% AUTHORS: JAVIER LOBATO MARTÍN, SERGIO ZAPATA CAPARRÓS, ANDRÉS BIEDMA
clear all
close all
clc


%
[x,Fs2] = audioread('audio_antenaorig.wav'); %We read the audio file
%[x,Fs2] = audioread('29_01_2023_NOAA19.wav'); %We read the audio file


% AM Demodulation
max_amp = max([max(x), abs(min(x))]); % find the maximum amplitude
x = x./max_amp; % normalize the input signal
x=x-mean(x); %substract the mean
mAM = abs(x);

[B,A]=butter(9,1000/(Fs2/2));   % AM Signal is filtered with 1.2 kHz cutoff frequency
mAM=filter(B,A,mAM);
Fs3 = 4160;     % frequency of word ("pixel")    4160 words/second
mAM_init = resample(mAM,Fs3,Fs2);      % We resample to 4160 Hz
t_init = 0:1/Fs3:(length(mAM)-1)/Fs3;

%Oversample is performed so the Doppler Correction is as accurate as
%possible
oversamp = 5;          % We oversample with oversample factor 'oversamp'
Fs3 = oversamp*Fs3;    
mAM = resample(mAM,Fs3,Fs2);      % Signal mAM oversampled to oversamp * 4160 Hz
t=0:1/Fs3:(length(mAM)-1)/Fs3;

figure; 
plot(t,mAM)
title('Temporal representation of APT signal')



% APARTADO 1: IMAGE REPRESENTATION WITHOUT PULSE SYNCHRONIZATION

resto = mod(length(mAM_init),2080); %We obtain the remainder to eliminate it from the array

filas = floor(length(mAM_init)/2080); %Number of complete rows

APT = mAM_init(1:length(mAM_init)-resto); %Array gets shortened


APT2 = reshape(APT,[2080,filas]); %Rows / columns format is switched because of the functioning of Matlab's reshape
APT2 = APT2'; % We make up for the switch

for i = 1:size(APT2,1) 
    
    minAPT2=min(min(APT2));
    maxAPT2 = max(APT2(i,:))/255;   
    APT2(i,:) = APT2(i,:)./maxAPT2;     %We normalize over 255

end

figure(2)
imshow(APT2,[0, 255])
title('APT IMAGE WITHOUT SYNCRHONIZATION')

%% IMAGE WITH USAGE OF SYNCHRONIZATION PULSES

% Now we obtain the image using the syncrhonization pulses, so we can tell
% the beginning of every line. The syncrhonization pulse is created and
% correlated with the original signal, obtaining the beginning of every
% line.


T = 1/Fs3; 
t=[0:T:1/160]; %syncA duration
cA=(square(1040*t*(2*pi))); %syncA, frequency 1040 Hz

hA=conv(transpose(cA),mAM(1:length(mAM))); % Correlation is obtained
syncA=hA(length(cA):length(hA)); % Tails are eliminated

figure(3)
stem(cA)
title('syncA syncrhonization pulse')

figure(4)
plot(syncA)
title('Correlation function using syncA')
xlim([5.6e5, 6e5])
%Peaks show beginning of every line


%Number of rows is estimated:
filas = floor(length(syncA)*2/Fs3); %2 is used because we receive 2 lines per second
len = floor(0.5*Fs3); %Row length in samples

%This loop saves the beginning of every line (in samples)

for i=1:filas

    [maximos,posmax] = max(syncA((i-1)*len+1:i*len)); %maximum of every line
    listamax(i) = posmax + i*len; % saved in array

end



% We use a a reference the length stated in the standard

len_syncA = 2080*oversamp; %Standard length should be 2080 * oversamp

% Loop shows length of every line
for k = 2:length(listamax)

    longitud_linea(k) = listamax(k)-listamax(k-1);

end

% We get the variation of length for every line
figure(6)
stem(longitud_linea)
title('Length of rows')
ylim([10398, 10402])

vector_referencia = linspace(1,len_syncA,len_syncA);
numerador_decimado = length(vector_referencia);


%Following loop performs the Doppler correction. Every line is compared to
%the standard length. If length is larger, decimation is performed. If
%length is the same, line remains untouched. If lenght is shorter,
%interpolation is performed.
vector_actual = [];
for j = 2:length(listamax)-2
    
    if (listamax(j)-listamax(j-1)) < len_syncA %Length shorter than standard
        
        vector_actual = mAM(listamax(j-1)+1:listamax(j));
        APT_syncA(j-1,:) = interp1(vector_actual,vector_referencia,'linear');%Interpolate

    elseif (listamax(j)-listamax(j-1)) > len_syncA %Length is larger than standard

        vector_actual = mAM(listamax(j-1)+1:listamax(j));
        APT_syncA(j-1,:) = resample(vector_actual,numerador_decimado,length(vector_actual));

    elseif (listamax(j)-listamax(j-1)) == len_syncA %Length is as expected

        vector_actual = mAM(listamax(j-1)+1:listamax(j));
        APT_syncA(j-1,:) = vector_actual(:);
    
    end
end


%Values get normalized between 0 and 255 so dynamic range is correct.
%Downsampling is performed so rows are 2080 pixels each.

for i = 1:size(APT_syncA,1) %Esto son las líneas de APT_syncA
    
    APT_syncA_resamp(i,:) = resample(APT_syncA(i,:),1,oversamp); % Decimate
    minAPT=min(min(APT_syncA_resamp));
    maxAPT = max(APT_syncA_resamp(i,:))/255;   
    APT_syncA_resamp(i,:) = APT_syncA_resamp(i,:)./maxAPT;     %Normalize by 255

end


figure(7)
imshow(APT_syncA_resamp,[0,255])


%% PARTE 3: TELEMETRY OBTENTION

%As an addition, we can also obtaing telemetry of the signal

[altura,anchura] = size(APT_syncA_resamp);

%We take an arbitrary portion of the image.
telemetry_A = APT_syncA_resamp(altura/4+47:altura/4+128+47-1,anchura/2-45:anchura/2-1);
telemetry_A = telemetry_A./max(telemetry_A); % Normalized

telemetry_B = APT_syncA_resamp(altura/4+47:altura/4+128+47-1,end-45:end-1);
telemetry_B = telemetry_B./max(telemetry_B);

telemetry = [telemetry_A, telemetry_B]; 

figure(8)
subplot(1,2,1)
imshow(telemetry_A)
title('Telemetry A')
subplot(1,2,2)
imshow(telemetry_B)
title('Telemetry B')


Porcion16_A = telemetry(1:8,1:45);          % Porción 16 Telemetría A
Porcion16_B = telemetry(1:8,46:end);        % Porción 16 Telemetría B
porcion15_A = telemetry(9:16,1:45);         % Porción 15 Telemetría A
porcion15_B = telemetry(9:16,46:end);       % Porción 15 Telemetría B
resto_porciones = 0.5*(telemetry_A(17:end,:)+telemetry_B(17:end,:));

media_resto = mean(mean(resto_porciones(13*8+1:end,:))); % Media de los valores del contenedor 14

%Temperature is obtained kelvin and celsius
T_K = 124 * media_resto + 90.113;
T_C = T_K - 273.15;
fprintf('Temperature in Kelvin is: %.3f K\n',T_K)
fprintf('Temperature in Celsius is: %.3f Cº\n',T_C)
