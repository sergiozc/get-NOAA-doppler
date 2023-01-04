clear all;
close all;
clc;

% Se guarda la imagen. Cada fila y columna corresponden a las coordenadas
%X e Y respectivamente
APT_image = imread('noaa18-doppler.png');
figure(1)
imshow(APT_image);
%Se aprecia el efecto doppler en las curvaturas del eje x debido a las
%diferencias de longitudes de las filas de la imagen
% Tenemos que, mediante regresión lineal, estimar la longitud de cada una
% de las filas jugando con el sync A (echar un vistazo a WavToImg.m)
 
% Regresion lineal %
% Parámetros %

f0 = 137.62e6; % frecuencia de transmisión de la señal APT
v_r = 7500e3; % velocidad de la plataforma de recepción (satélite NOAA)
c = 3e8; % velocidad de la luz en el vacío
f_d = (f0 * v_r)/(c + v_r);

% Seleccionar fila de sincronización (Sync A)
Sync_A = APT_image(end,:); % Seleccionar la fila 50 de la imagen
Sync_A = double(Sync_A); % El modelo solo acepta datos tipo doble.

% Definir función de modelo para la regresión lineal
% El modelo relaciona la longitud de la fila con la frecuencia Doppler 
% y la cantidad de desplazamiento de frecuencia
model_fun = @(x,xdata) x(1) * sin(2*pi*x(2)*xdata + x(3));

% Inicializar parámetros de la regresión lineal
x0 = [50, f0, 0]; % amplitud, frecuencia y fase iniciales

% Realizar regresión lineal utilizando "lsqcurvefit"
% Sync_A es la fila de sincronización seleccionada anteriormente
% [1:length(Sync_A)] es el conjunto de datos en el eje x (índices de la fila)
[x,resnorm,residual,exitflag,output] = lsqcurvefit(model_fun, x0, [1:length(Sync_A)] ,Sync_A);

% Obtener resultados de la regresión lineal
amplitud = x(1);
frecuencia_doppler = x(2);
fase = x(3);

% Calcular cantidad de desplazamiento de frecuencia a aplicar
f_shift = frecuencia_doppler * size(APT_image,1);

% Aplicar FFT a la imagen APT
APT_FFT = fft2(APT_image);

% Desplazar componentes de frecuencia de la imagen APT utilizando "fftshift"
APT_FFT_shifted = fftshift(APT_FFT,round(f_shift));

% Aplicar IFFT a la imagen APT desplazada para obtener la imagen corregida
APT_image_corrected = ifft2(APT_FFT_shifted);

% Metricas de error % 
% Calcular métricas de evaluación de modelo
Y = Sync_A;
Ypred = APT_image_corrected(end,:);
R2 = 1 - sum((Y - Ypred).^2)/sum((Y - mean(Y)).^2);
MSE = mean((Y - Ypred).^2);
MAE = mean(abs(Y - Ypred));

% Mostrar métricas de evaluación de modelo
disp(['R2 = ', num2str(R2)]);
disp(['MSE = ', num2str(MSE)]);
disp(['MAE = ', num2str(MAE)]);

%% Mostrar imagen corregida
imshow(APT_image_corrected);






