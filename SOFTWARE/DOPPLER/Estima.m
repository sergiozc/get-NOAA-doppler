function [MSE, R2, MAE] = Estima(Imagen_original,Imagen_estimada)
% Funcion que recibe como parametros la imagen original (obtenida tras
% sincronizcar con los pulsos de sincronizacion SyncA y SyncB) y la imagen
% interpolada.
M_X = Imagen_original;
M_X_est = Imagen_estimada;
% Se calculan tres estimadores diferentes %
MSE = mean((M_X - M_X_est).^2);
R2 = 1 - sum((M_X - M_X_est).^2)/sum((M_X - mean(M_X_est)).^2);
MAE = mean(abs(M_X - M_X_est));
% Se muestran por la terminal %
disp(['MSE = ', num2str(mean(MSE))]);
disp(['R2 = ', num2str(mean(R2))]);
disp(['MAE = ', num2str(mean(MAE))]);
