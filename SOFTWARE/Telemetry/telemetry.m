clear all;
close all;
clc;


APT_image = imread('prueba.png');
figure(1)
imshow(APT_image);
%Situamos dónde está la banda de telemetría en la imagen APT
telemetry_band = APT_image(:, 1016);

%Creamos las porciones de telemetría según el estándar APT. De la 1 a la 9
%son siempre las mismas, de la 10 a la 16 son variables y se vuelve a
%repetir el patrón de 1-9
wedges_tel = [31 63 95 127 159 191 224 255 0 128 128 128 128 128 128 128 31 63 95 127 159 191 224 255 0];

%Haciendo la correlación vemos dónde comienza el patrón
[correlate, k] = xcorr(telemetry_band, wedges_tel);
figure(2);
plot(k, correlate);