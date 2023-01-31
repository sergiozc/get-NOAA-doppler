clear;
close all;
clc;

Fs1 = 60e3;
filename = 'C:\Users\javil\Desktop\MASTER\SAC\P4\data_full.raw';
fid = fopen(filename,'rb');
xFM = fread(fid, inf, 'single');
xFM = xFM(1:2:end) + 1i*xFM(2:2:end);
fclose(fid);

figure;
plot(real(xFM(1:5000:end)),imag(xFM(1:5000:end)),'b.');
xlabel('In-phase'); ylabel('Q-phase');

figure;
step = fix(0.25*Fs1);
window = fix(0.5*Fs1);
Nfft = 2^nextpow2(window);
ini = round(6*Fs1);
fin = round(10*Fs1);
[S, f, t] = specgram(xFM(ini:fin), Nfft, Fs1, window, window-step);
S = abs(S(2:Nfft*30000/Fs1,:)); % # magnitude in range 0<f<=30000 Hz.
S = S/max(S(:)); % # normalize magnitude so that max is 0 dB.
% S = max(S, 10^(-40/10)); % # clip below -40 dB.
% S = min(S, 10^(-3/10)); % # clip above -3 dB.
imagesc (t, f, log(S)); % # display in log scale
set (gca, "ydir", "normal"); % # put the 'y' direction in the correct direction
xlabel('Time (s)');ylabel('Frequency (Hz)');

% Demodular señal FM
mFM = angle(xFM(2:end).*conj(xFM(1:end-1)));
mFM = mFM - mean(mFM);mFM = mFM./max(mFM);
Fs2 = 11025;
mFM = resample(mFM,Fs2,Fs1); % Señal mFM muestreada ahora a 11025 Hz
mFM = (mFM - mean(mFM))./max(mFM - mean(mFM));
Lf = round(0.5*Fs2); Nfft=2.^nextpow2(Lf);
figure;
pwelch(mFM,Lf,0.5,Nfft,Fs2);

% Demodular señal AM
mAM = abs(mFM);
[B,A]=butter(4,1200/(Fs2/2)); % La señal AM tiene un ancho de banda de 1.2kHz aprox
mAM=filter(B,A,mAM);
Fs3 = 4160; % frecuencia de palabra ("pixel") 4160 words/second
mAM = resample(mAM,Fs3,Fs2); % Señal mAM muestreada ahora a 4160 Hz
t=0:1/Fs3:(length(mAM)-1)/Fs3;
figure; plot(t,mAM)

%% Actividad 1: Dibujar el mapa (bruto).
Ancho = 4160 * 0.5;                     % Calculo del numero de columnas
Largo = floor(length(mAM)/Ancho);       % Calculo del numero de filas
mAM_cutted = mAM(1:Largo*Ancho);        % Corte del vector mAM para que encaje en la matriz
Imagen = zeros(Ancho,Largo)';           % Creacion de la matriz imagen
Imagen = reshape(mAM_cutted,Ancho,Largo)';
Imagen_norm = Imagen/max(max(abs(Imagen)));
figure();
imshow(Imagen_norm)

%% Actividad 2: Dibujarlo a partir de la señal de sincronizacion, canal 
% visible y canal infrarojo.

SyncA = [-1,-1,-1,-1,1,1,-1,-1,1,1,-1,-1,1,1,-1,-1,1,1,-1,-1,1,1,-1,-1,1,1,-1,-1,1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1];
SyncB = [-1,-1,-1,-1,1,1,1,-1,-1,1,1,1,-1,-1,1,1,1,-1,-1,1,1,1,-1,-1,1,1,1,-1,-1,1,1,1,-1,-1,1,1,1,-1,-1];

Lista_visibles = [];
tolerance = 10e-10;
for i = 1:Ancho:length(mAM_cutted)
    detec_visible = filter(fliplr(SyncA),1,mAM_cutted(i:i+Ancho-1));
    if i == 1
        [max_visible,idx_visible] = max(detec_visible);
        idx_visible = idx_visible - length(SyncA);
    else
        max_visible = max(detec_visible(130:260,1));
        idx_visible = find(ismembertol(detec_visible,max_visible, tolerance))-length(SyncA);
    end
%     figure
%     plot(detec_visible)
%     title(['Visibles ' num2str(i)])
%     hold on
%     plot(idx_visible,max_visible,'*')
%     grid on
%     hold off
%     pause; 
    Lista_visibles = [Lista_visibles idx_visible];
end

Lista_infrarojos = [];
pos = 0;
for i = 1:Ancho:length(mAM_cutted)
    detec_infrarojo = filter(fliplr(SyncB),1,mAM_cutted(i:i+Ancho-1));
    if i == 1
        [max_infrarrojo,idx_infrarojo] = max(detec_infrarojo);
        idx_infrarojo = idx_infrarojo - length(SyncB);
    else
        max_infrarrojo = max(detec_infrarojo(800:1500,1));
        idx_infrarojo = find(ismembertol(detec_infrarojo,max_infrarrojo, tolerance))-length(SyncB);
    end
    
    Lista_infrarojos = [Lista_infrarojos idx_infrarojo];
%     pos = pos + 1;
%     if ismember(pos,[1221, 1222, 1223, 1231, 1238, 1241]) 
%
%       Vector con las posiciones en las que habia un error observadas.
%
%         figure
%         plot(detec_infrarojo)
%         title(['Visibles ' num2str(i)])
%         hold on
%         plot(idx_infrarojo,max_infrarrojo,'*')
%         grid on
%         pause; 
%     end 
    
end
% Ajuste para dotar de la posicion correcta dentro de la matriz mAM_cutted
% a las listas: Lista_infrarrojos y Lista_Visibles.

v_posiciones = 0:Ancho:length(mAM_cutted)-1;
Lista_infrarojos = Lista_infrarojos + v_posiciones;
Lista_visibles = Lista_visibles + v_posiciones;
diff = Lista_infrarojos - Lista_visibles;

%%
diff = Lista_infrarojos - Lista_visibles;
new_size = 1040;
M_interpolated_visible = zeros(Largo,Ancho/2);

for i = 1:1:Largo
    v_orig_visible = mAM_cutted(Lista_visibles(i):Lista_infrarojos(i));
    sample_points = linspace(1,length(v_orig_visible), new_size);
    v_interpolated_visible = interp1(1:length(v_orig_visible), v_orig_visible, sample_points, 'pchip');
    M_interpolated_visible(i,:) = v_interpolated_visible;
end
%%
M_interpolated_infrarrojo = [];
v_SyncB = Lista_visibles(2:end)-Lista_infrarojos(1:end-1);
% v_SyncB = v_SyncB + v_posiciones(end-1);
for i = 1:1:Largo-1
    v_orig_infrarrojo = mAM_cutted(Lista_infrarojos(i):Lista_visibles(i+1));
    sample_points = linspace(1,length(v_orig_infrarrojo), new_size);
    v_interpolated_infrarrojo = interp1(1:length(v_orig_infrarrojo), v_orig_infrarrojo, sample_points, 'pchip');
    M_interpolated_infrarrojo(i,:) = v_interpolated_infrarrojo;
end
M_interpolated_infrarrojo = [M_interpolated_infrarrojo; M_interpolated_infrarrojo(end,:)];
%% Dibujo de las matrices visible e infrarrojo
M_total_interpolated = [M_interpolated_visible, M_interpolated_infrarrojo];
Imagen_total = M_total_interpolated/max(max(abs(M_total_interpolated)))';
figure()
imshow(Imagen_total)
%% Decodificar algun valor de telemetria
% Tomamos la muestra de telemetria que mejor calidad tiene, aquella que se
% encuentra en el centro de la imagen, donde el efecto doppler es menor.

% Una vez se ha tomado como referencia la mitad de la matriz, se han
% ajustado los limites de forma que al dibujar telemtriaA y telemetriaB
% juntos, en la parte superior de la imagen se muestren los wedges de forma
% descendente (wedge 15 y wedge 16 aparecen en la parte superior y wedge 14 en la
% inferior)
telemetria_A = M_total_interpolated(Largo/2+47:Largo/2+128+47-1,Ancho/2-45:Ancho/2-1);
telemetria_A = telemetria_A./max(telemetria_A);
telemetria_B = M_total_interpolated(Largo/2+47:Largo/2+128+47-1,end-45:end-1);
telemetria_B = telemetria_B./max(telemetria_B);

M_telemetria = [telemetria_A, telemetria_B];

figure()
subplot(1,2,1)
imshow(telemetria_A)
title('Telemetria A')
subplot(1,2,2)
imshow(telemetria_B)
title('Telemetria B')

Wedge_16_A = M_telemetria(1:8,1:45);          % Contenedor 16 SyncA
Wedge_16_B = M_telemetria(1:8,46:end);        % Contenedor 16 SyncB
Wedge_15_A = M_telemetria(9:16,1:45);         % Contenedor 15 SyncA
Wedge_15_B = M_telemetria(9:16,46:end);       % Contenedor 15 SyncB
Wedge_rest= 0.5*(telemetria_A(17:end,:)+telemetria_B(17:end,:));

AVHRR = mean(mean(Wedge_rest(13*8+1:end,:))); % Media de los valores del contenedor 14

K = 124 * AVHRR + 90.113;
C = K - 273.15;
fprintf('La temperatura es de: %.3f K\n',K)
fprintf('La temperatura es de: %.3f Cº\n',C)



