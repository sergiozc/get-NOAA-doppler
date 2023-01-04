%% WAV TO IMAGE %%
% Decodificacion APT y corrección del efecto Doppler %

clc, clear all;
close all;

%% Carga de la señal de audio %%
[NOAA, fs] = audioread("pruebas_wav/090729 1428 noaa-18 8bit.wav");

T = 1 / fs;                      % Periodo de muestreo
t = ((0:length(NOAA)-1))*T';     % Vector de tiempo [s]

%% Decodificacion APT %
% 1. Detección del mensaje envolvente usando un filtro pasa-bajos 
% y una rectificación de la señal.

max_amplitud = max([max(NOAA), abs(min(NOAA))]);
NOAA_norm = NOAA./max_amplitud;

figure(1)
plot(t, NOAA_norm)
title('Señal de audio NOAA normalizada')
grid on
ylabel('Amplitud')
xlabel('Tiempo [s]')
xlim([t(1) t(end)])

% 2. Deteccion del mensaje envolvente y normalizacion

NOAA_norm = NOAA_norm - mean(NOAA_norm);
[B,A] = butter(9, 1000/(fs/2),"low");
envolvente = abs(NOAA_norm);            % Obtencion de la envolvente
envolvente_suavizada = filter(B,A, envolvente);      % Detector de envolvente para obtener el mensaje
envolvente_suavizada = envolvente_suavizada - mean(envolvente_suavizada);
envolvente_suavizada_normalizada = envolvente_suavizada/max(envolvente_suavizada);

figure(2)
plot(t, envolvente_suavizada_normalizada)
title('Detección de envolvente: Mensaje')
grid on
ylabel('Amplitud')
xlabel('Tiempo [s]')
xlim([t(1) t(end)])

%% 3. Correlacion cruzada del mensaje con pulso de sincronizacion esperado

t_sinc = (0:T:1/160);       % Tamaño del pulso de sincronizacion
f_sinc = 1040;              % Frecuencia de los pulsos de sincronizacion A
pulso_sinc = square(f_sinc*t_sinc*2*pi);

syncA = conv(envolvente_suavizada_normalizada,fliplr(pulso_sinc),'same');
% Graficamos la correlación
figure(3);
plot(t,syncA);
title('Correlación Cruzada: Sync A y Envolvente Normalizada');
grid on
xlim([80 90])

%% 4. Identificacion de los puntos de inicio de cada linea

lineas = floor(length(syncA)*2/fs);
% Se multiplica el tamaño de syncA*2 debido a que  cada línea de imagen 
% es seguida por un patrón de sincronización Sync B, que dura el mismo 
% tiempo que el patrón Sync A. Por lo tanto, cada línea de imagen ocupa 
% el doble del tiempo que el patrón Sync A, y al multiplicar por dos el 
% tamaño de syncA se asegura de contar tanto el patrón Sync A como el 
% patrón Sync B correspondiente a cada línea de imagen. Es importante 
% tener en cuenta que la variable lines solo proporciona una estimación 
% aproximada del número de líneas de imagen presentes en la señal.

tam = floor(.5*fs);

% La variable tam se utiliza para determinar la longitud en muestras de 
% cada línea de imagen en la señal APT recibida. Se define como el 
% resultado de la función floor(.5*fs), lo que equivale a la mitad de la 
% frecuencia de muestreo fs.

% La razón por la que se utiliza la mitad de la frecuencia de muestreo es 
% porque cada línea de imagen dura aproximadamente 0.5 segundos 
% (la mitad del tiempo que el patrón Sync A y Sync B combinados). 
% Al utilizar la mitad de la frecuencia de muestreo se asegura de contar 
% suficientes muestras de cada línea de imagen para poder procesarla 
% adecuadamente.

for i = 1:lineas
    [H,I] = max(syncA((i-1)*tam+1:i*tam));
    list(i) = I + tam*i;
end

% La variable list es un vector que almacena los puntos de inicio de cada 
% línea de imagen en la señal recibida. Cada punto de inicio se determina 
% buscando el punto con mayor amplitud en el rango de syncA correspondiente
% a cada línea.

% La variable H almacena la amplitud del punto con mayor amplitud en el 
% rango de syncA correspondiente a la línea actual, mientras que la 
% variable I almacena la posición de ese punto en el rango de syncA. 
% La posición del punto de inicio de la línea se almacena en list sumando 
% la posición del punto con mayor amplitud (I) a la longitud de la línea 
% en muestras (len) multiplicada por el índice del bucle for (l).

%% 5. Interpolación de los puntos de inicio de línea si hay alguno que 
% esté espaciado incorrectamente.

% Ahora se pretende mejorar la precisión de los puntos de inicio de línea
% determinados anteriormente. Para ello realizamos un proceso de 
% interpolacion. En el cual se compara la distancia entre los puntos de 
% inicio de línea aproximados con un valor esperado de 2s (correspondiente
% a la duración de un patron de SyncA y SyncB combinados). 
% Si la distancia entre dos puntos de inicio de lista esta dentro de un 
% margen de error +/-5 muestras, se consideran correctamente espaciados y 
% se almacenan.

% Si la distancia es mayor, se interpola para determinar el punto de inicio
% de linea más preciso.

v_diferencias = [];
for i = 5:(length(list)-1)
    v_diferencias(i) = list(i) - list(i-4);
end

% Encontramos el primer punto de inicio de fila correctamente espaciado
cuenta = 1;
start = 0;
while start == 0
    if v_diferencias(cuenta) > (2*fs-5) && v_diferencias(cuenta) < (2*fs+5)
        start = list(cuenta);
    end
    cuenta = cuenta + 1;
end
% Inicializamos la variable que almacena el número de puntos de inicio de 
% fila incorrectamente espaciados
badcount = 0;
% Almacenamos el último punto de inicio de fila correctamente espaciado
goodindex = cuenta;
% Interpolamos los puntos de inicio de fila incorrectamente espaciados
Error = 5;
for k = cuenta:(length(list)-1)
    if v_diferencias(k) > (2*fs-Error) && v_diferencias(k) < (2*fs+Error)
        % Si el punto de inicio de fila está correctamente espaciado, 
        % lo añadimos a la lista de puntos de inicio de fila correctos
        goodlist(k-cuenta+1) = list(k);
        % Reiniciamos el contador de puntos de inicio de fila 
        % incorrectamente espaciados
        badcount = 0;
         % Almacenamos el último punto de inicio de fila correctamente 
         % espaciado
        goodindex = k;
    else
        % Si el punto de inicio de fila está incorrectamente espaciado, 
        % aumentamos el contador de puntos de inicio de fila 
        % incorrectamente espaciados
        badcount = badcount + 1;
        % Interpolamos el punto de inicio de fila utilizando el último 
        % punto de inicio de fila correctamente espaciado y el contador 
        % de puntos de inicio de fila incorrectamente espaciados
        goodlist(k-cuenta+1) = list(goodindex) + floor((fs/2)*badcount);
    end
end

%% 6. Construccion de la matriz de datos
% Calculamos el número de columnas de la imagen
colums = ceil(fs/2);
% Calculamos el número de filas de la imagen
rows = floor((length(envolvente)-start)/colums);
% Si el número de filas es par, eliminamos las tres últimas filas
if (rows/2-floor(rows/2)) == 0
    rows = rows - 4;
end
% Almacenamos la señal que se ha enviado en una matriz
Imagen_Bruta = zeros(rows,colums);
for l = 1:rows-1
    Imagen_Bruta(l, 1:tam) = envolvente(goodlist(l):goodlist(l)+tam-1);
end
% Creamos una imagen a partir de la señal almacenada en la matriz
image = mat2gray(Imagen_Bruta);
% Mostramos la imagen en pantalla
figure(4);
imshow(image);
title('Imagen recibida');

%% 7. Remuestreo y relación de aspecto 1:1

% Remuestrea la señal en cada fila para que la imagen tenga el número correcto
% de puntos de datos para que la relación de aspecto sea 1:1

% Estos valores de P y Q están elegidos de forma que fs_resampled sea
% entero, para cualquier otra fs habría que recalcularlos!
P = 1664;
Q = 2205;
fs_resampled = fs*P/Q;

for k=1:rows
M(k,1:(fs_resampled/2)+1)=resample(Imagen_Bruta(k,1:colums),1664,2205);
end

% Normaliza los puntos de datos entre 0 y 255 para la imagen
minM=min(min(M));
maxM=max(max(M));
range=(maxM-minM);
Map=M./range;
minMap=min(min(Map));
Map=Map-minMap;

% Cambia el contraste de la imagen para que se vea mejor
loop=1;
scale=0;

while (loop==1)
    Map=Map*255*.25^scale;
    figure(5)
    imagesc(Map);
    axis image;
    colormap(gray);
    disp('Introduzca un valor entre -3 y 3 para el contraste de la imagen');
    scale=input(':');
        if scale>=-3 && scale<=3
            loop=0;
        end
end

% Saves the image
disp('Introduzca el nombre del archivo de imagen');
name=input(':','s');
print(figure(5), '-dpng', name);

