clc;
clear all;
close all;

%%%%%%%%%%%%% This script implements the APT decoding %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% algorithm and achieve a doppler %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% correction due to the sync A pulses %%%%%%%%%%%%%%%%%%%%%%%%%


[teo, fs] = audioread("pruebas_wav/090729 1428 noaa-18.wav");

T2 = 1 / fs;
t2 = (0:length(teo)-1) * T2;


% Automatic Picture Transmission (APT) Decoding
max_amplitude = max([max(teo), abs(min(teo))]); % find the maximum amplitude
x = teo./max_amplitude; % normalize the input signal
x=x-mean(x); %substract the mean
[B,A] = butter(9,1000/(fs/2),'low'); %lowpass filter
ensig=abs(x);  %%Rectifies the AM signal                   
out=filter(B,A,ensig);  %%Preforms the smothing function in Envelope detection
out=out-mean(out);%% Remove any DC                 
y=out/max(out);%%Normalizes the message signal

t=[0:T2:1/160];%%Length of the sync wave form in time at the 
%%sampling freq
cA=(square(1040*t*(2*pi)));%%Creates the expected sync pulse

hA=conv(transpose(cA),y(1:length(y)));%%Preforms the correlation
syncA=hA(length(cA):length(hA));%%Removes the convolution tails
%Es el equivalente a quitar por la izquierda y por la derecha un número de
%muestras igual a cA, para que se quede con eln num de muestras de y

figure(1);
plot(syncA);
xlim([3.88e6 3.896e6]);
title('Cross correlation Sync A');

lines=floor(length(syncA)*2/fs);%%Determines the number of possible rows 
%%in the picture
len=floor(.5*fs);%%Determines the length in samples of each line
%This is 0.5 because the rate of transmission is 2 lines per second

%%Finds the largest point in the correlation to determine where each row
%%starts
for l=1:lines;
    [H,I]=max(syncA((l-1)*len+1:l*len)); %Coge línea a línea usando el n de muestras de cada linea
    list(l)=I+len*l;   % se almacena en una lista la posición en la que está el máximo de la corr
end

%%Determines the spacing between the current end of the sync wave and
%%the end of the sync wave four lines previous to the current position 
test(1:4)=[0, 0, 0, 0];
for l=5:(length(list)-1)
    test(l)=list(l)-list(l-4);
end
%Esto no entiendo por qué es cada cuatro líneas. Es mirar si el espaciado
%con la línea de hace dos segundos es correcto. Puede ser arbitrario¿?

%%Determines the first detected sync pulse with the correct spacing.  start
%%determines where the first sample of the first line is.
count=1;
start=0;
while(start==0)
    if test(count)>(2*fs-5) %por qué es el doble de la frecuencia de muestreo
        if test(count)<(2*fs+5)
            start=list(count);
        end
    end
   count=count+1;
end

badcount=0; %%refers to the number of incorrectly spaced detected sync pulses
goodindex=count;%%list of the index points for each row
for k=count:(length(list)-1)
    if test(k)>(2*fs-5) && test(k)<(2*fs+5) %%Checks to see if the index is 
%%correctly spaced from the index value 2 seconds before
            goodlist(k-count+1)=list(k);%%If so adds the value to the list
            badcount=0;%%Resets the number of badcounts
            goodindex=k;%%Saves the last known good index
    else
        %%If false the number of badcounts is increased by one
        badcount=badcount+1;
        %%The value of the bad index is interpolated from the last known
        %%good value
        goodlist(k-count+1)=list(goodindex)+floor((fs/2)*badcount);
    end
end

%Amago de explicación: Creo que lo que hace es: arbitrariamente elige la
%separación de 4 líneas que son dos segundos. Determina si ese margen es
%correcto dándole una holgura de 5 muestras. A continuación, determina qué
%filas tienen la separación correcta y las que no la tienen, la interpola
%a partir de la última fila correcta conocida. Con esta interpolación
%elimina el efecto Doppler de la imagen.


%%determines the length of each row due to the sampling frequency
colums=ceil(fs/2);
%%determines the number of rows from the data
rows=floor((length(y)-start)/colums);
if (rows/2-floor(rows/2))==0
    rows=rows-3;
end
%%Creates a matrix of the signal that was sent using the interpolated index
for l=1:rows-1
raw(l,1:5513)=y(goodlist(l):goodlist(l)+colums-1);
end
%No sé por qué usa 5513

%%Resamples the signal in each row so that the picture will have the right
%%number of data points so that the aspect ratio is 1:1
% for k=1:length(goodlist)
%     M(k,1:4161)=resample(raw(k,1:colums),1664,2205);
% end
M = raw;
% fs=4160;%%New sampling frequency
%%Contrast Loop so that the signal will have the right amount of contrast
%%for the user.
% loop=1;
% scale=0;
% while (loop==1)
% %%Normalizes the data points between 0 and 255 for the image
% minM=min(min(M));
% maxM=max(max(M));
% range=(maxM-minM);
% Map=M./range;
% minMap=min(min(Map));
% Map=Map-minMap;
% Map=Map*255*.25^scale;
figure(2)
imagesc(M);
axis image;
colormap(gray);