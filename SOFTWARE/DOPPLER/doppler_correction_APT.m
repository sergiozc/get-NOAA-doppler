clear all;
close all;
clc;

% Se guarda la imagen. Cada fila y columna corresponden a las coordenadas
%X e Y respectivamente
I = imread('noaa18-doppler.png');
imshow(I);
%Se aprecia el efecto doppler en las curvaturas del eje x debido a las
%diferencias de longitudes de las filas de la imagen
