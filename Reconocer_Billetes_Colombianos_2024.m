%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%------- RECONOCIMIENTO DE BILLETES COLOMBIANOS ---------------------------
%------- Por: Sebastian Orozco    sebasorosco14@gmail.com ----- -----------
%-------      Estudiantes Facultad de Ingenieria en Telecomunicaciones ----
%------- Curso Procesamiento Digital de Imágenes --------------------------
%------- V4 Mayo de 2024--------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%--1. Inicializo el sistema -----------------------------------------------
%--------------------------------------------------------------------------

clear all, close all, clc

%--------------------------------------------------------------------------
%-- 2. Lectura de la imagen para posterior tratamiento y segmentacion  ----
%--------------------------------------------------------------------------

% PARA EL USO DE LA WEBCAM ES NECESARIA LA APLICACION "DROIDCAM" PARA
% CAPTURAR LA IMAGEN, LAS PRUEBAS (NIVELES DE UMBRAL DEFINIDOS) SON
% POSIBLES USANDO UN MOTOROLA G6 Y UNA ILUMINACION GENERAL CON REFUERZO DE
% UNA LAMPARA LED

a = webcam(2); % Leer la imagen de la camara del celular (en este caso se usa la webcam 2 ya que es una app para capturar con el celular y no con la webcam del PC)

% ciclo para leer cierta cantidad de fotogramas antes de parar el programa
valor_total = 0;  % variable para hacer la suma total de dinero que se detecte en la imagen
figure('Units', 'centimeters', 'Position', [0, 0, 20, 15]);
for i = 1:130    
    imagen = snapshot(a); imagen_gris = rgb2gray(imagen);  % toma una instantanea de la camara y la pasa a escala de grises
    b=255-imagen_gris;  % invertir los valores de la imagen en escala de grises
    l=graythresh(b);   % sacar el umbral de grises 
    c=imbinarize(b,l-0.05);   % binarizar la imagen en base al umbral 
    ee=strel('square',4);   % elemento estructurante tipo cuadrado (4x4)
    d=imopen(c,ee);    % operacion morfologica open (erode-->dilate)
    f=~d;
    N = 3; % numero de billetes a detectar
    imagen_final = bwareafilt(f, N); %filtra la imagen f en base al area (busca las N areas mas grandes) 
    imagen_objeto = imagen_final; %copia de la imagen
    
%--------- Visualizar cada segmento por separado---------------------------

    imagenEtiquetada = bwlabel(imagen_final); % etiqueta los objetos conectados en la imagen
    numSegmentos = max(imagenEtiquetada(:)); 
    numeros = cell(1,3); % arreglo para guardar las imagenes de los numeros detectados
    val = {}; % arreglo para gusrdar los numeros detectador por correlacion
    for j = 1:numSegmentos
        segmento = imagenEtiquetada == j; % Crear una imagen con solo el segmento actual
        segmento=uint8(segmento)*255;  % cambio de formato de la imagen
        h=imagen_gris;  % copia de la imagen a escala de grises
        h(segmento==0)=0;
        b=255-h;
        l=graythresh(b);   % sacar el umbral de grises
        c=imbinarize(b,l-0.26);   % binarizar la imagen en base al umbral  
        ee=strel('square',2);   % elemento estructurante tipo cuadrado
        d=imopen(c,ee);    % operacion morfologica open (erode-->dilate)
        
        
%----------------- Extraer cada billete ----------------------------------
        
        flag = 1; % bandera para cuando alguna region no tenga el tamaño adecuado no se procese
        region_props = regionprops(~d, 'BoundingBox'); % Calcular el delimitador de los objetos en la imagen (tipo rectangulo)
        if ~isempty(region_props)
            bounding_box1 = region_props.BoundingBox; % Obtener las coordenadas del cuadro delimitador
            x = floor(bounding_box1(1));  % coordenada X inicial
            y = floor(bounding_box1(2));  % coordenada Y inicial
            ancho = ceil(bounding_box1(3));  % ancho del cuadro
            alto = ceil(bounding_box1(4));   % alto del cuadro
            y1=int64(y+alto-1);   % calcular coordenada Y final
            x1=int64(x+ancho-1);  % calcular coordenada X final
            if abs(x-x1) > 600 || abs(y-y1) > 200  % si la region corresponde con el tamaño deseado aproximadamente
                flag = 0;
                imagen_recortada = d(y+1:y1, x+1:x1);   % recorte de la imagen 'd' con las coordenadas
                backup = imagen_recortada;
                imagen_recortada = imresize(imagen_recortada,4);  % funcion para redimensionar la imagen recortada (aumenta en un factor de escala de 4)
            else
                flag = 1;  % se activa la bandera para evitar procesar esa imagen basura
            end
        end  
        
% ---Segmentar las áreas para obtener solo la parte de los numeros --------

        if flag == 0
            imagen_segmentada1 = bwareaopen(imagen_recortada, 10000); % definir areas por encima de 1200 pixeles
            imagen_segmentada2 = bwareaopen(imagen_recortada, 40000);  % definir areas por encima de 6000 pixeles
        
            imagen_segmentada = imagen_segmentada1 - imagen_segmentada2; % lograr eliminar espacios que puedan interferir con la segmentacion del numero
    
            filas = 1:660;  % filas necesarias para obtener la esquina superior izquierda
            columnas = 10:700; % columnas necesarias para obtener la esquina superior izquierda
            
            imagenRecortada = imagen_segmentada(filas, columnas, :); % recorte de la imagen que contiene el numero

            numeros{j} = imagenRecortada;  % almacena el digito segmentado para psterior grafiacion

            
%--------------------------------------------------------------------------
%-- 3. Reconocimiento de caracteres  --------------------------------------
%--------------------------------------------------------------------------

%------------------ Deteccion del primer digito ---------------------------
            
            etiquetas = bwlabel(imagenRecortada);  % detecta regiones conectadas
            region_props = regionprops(etiquetas, 'BoundingBox');  % aplica el rectangulo BoundingBox
            
            hold on;
            
            primer_digito = false;  % bandera de control para segmentar el primer digito de cada numero obtenido
            numel_regionprops = numel(region_props);  % calcula la cantidad de regiones en la imagen
            for k = 1:numel_regionprops
                
                bounding_box = region_props(k).BoundingBox; % obtiene las coordenadas del bounding box
                
                x = floor(bounding_box(1)); % recorta cada digito del segmento obtenido
                y = floor(bounding_box(2));
                ancho = ceil(bounding_box(3));  % ancho del rectangulo
                alto = ceil(bounding_box(4));   % alto del rectangulo

                if ancho > 75 && alto > 150 && alto < 400 % area aproximada de los digitos
                    region_recortada = imagenRecortada(y+1:y+alto-1, x+1:x+ancho-1);  % recorta el digito delimitado

                    if ~primer_digito
                        num = region_recortada;  % Almacenar solo el primer digito que cumple el minimo de area
                        primer_digito = true;  % cambia la bandera para no guardar los demas digitos
                    end
                else
                    numel_regionprops = numel_regionprops - 1;  % la region detectada no es un digito
                end 
            end

%----------------------- Correlacion --------------------------------------

            valores_corr = [];  % almacena los valores de correlacion en base a unos digitos base
            if primer_digito == true
                for l = 1:3  % leer los digitos base para hacer la correlacion (el 1, el 2 y el 5)
                    if l == 1
                        ee = imread('ee3-1.bmp');ee=uint8(ee)*255;  % se lee la imagen y se convierte a RGB
                    elseif l == 2
                        ee = imread('ee3-2.bmp');ee=uint8(ee)*255; % se lee la imagen y se convierte a RGB
                    elseif l == 3
                        ee = imread('ee3-5.bmp');ee=uint8(ee)*255; % se lee la imagen y se convierte a RGB
                    end
                    
                    [filas_ref, columnas_ref] = size(num);  % obtiene las dimensiones del digito obtenido
                    [filas_obj, columnas_obj] = size(imbinarize(ee)); % obtiene las dimensiones del digito base
                    
                    escala_filas = filas_obj / filas_ref;  % calcula la escala de la imagen de referencia respecto a la imagen objetivo
                    escala_columnas = columnas_obj / columnas_ref;
                    
                    imagen_referencia_bin_redimensionada = imresize(num, [filas_obj, columnas_obj]); % redimensiona la imagen de referencia para que tenga el mismo tamaño que la imagen real
                    
                    if numel_regionprops == 1 && l == 1  
                        valores_corr = [valores_corr, 0];  % si solo hay una region y se quiere hacer la correlacion con el 1 se le da un valor de 0, ya que ningun billete tiene solo un 1 (mil pesos)
                    elseif numel_regionprops == 1 && l == 2 || l == 3  % si solo hay una region se hace la correlacion con el 2 o el 5 para determinar si son 2 mil o 5 mil pesos
                        correlacion = normxcorr2(imbinarize(ee), imagen_referencia_bin_redimensionada); % realiza la correlación
                        valores_corr = [valores_corr, max(abs(correlacion(:)))];
                        %[max_corr_value, max_corr_index] = max(abs(correlacion(:)));
                    elseif numel_regionprops == 2  % si hay 2 regiones es porque pueden ser 10 mil, 20 mil o 50 mil, se debe hacer la correlacion con los 3 digitos
                        correlacion = normxcorr2(imbinarize(ee), imagen_referencia_bin_redimensionada); % realiza la correlación
                        valores_corr = [valores_corr, max(abs(correlacion(:)))];
                        %[max_corr_value, max_corr_index] = max(abs(correlacion(:)));
                    elseif numel_regionprops == 3 && l == 1  % si hay 3 regiones es porque es el de 100 mil
                        valores_corr = [100 0 0];
                    end
    
                
                end

                
                m = find(valores_corr==max(valores_corr));  % encuentra el indice donde la correlacion es mayor (m=1 fue con el 1, m=2 fue con el 2, m=3 fue con el 5)
                if m == 1 && numel_regionprops == 1       % compara si la correlacion mayor fue con el 1 y solo hay una region detectada (mil -> no existe)
                    disp('numero invalido')
                elseif m == 1 && numel_regionprops == 2   % compara si la correlacion mayor fue con el 1 y hay dos regiones detectadas (10 mil)
                    disp('10 mil')
                    valor_total=valor_total+10;
                    val = {val{:}, '10'};
                elseif m == 1 && numel_regionprops == 3   % compara si la correlacion mayor fue con el 1 y hay tres regiones detectadas (100 mil)
                    disp('100 mil')
                    valor_total=valor_total+100;
                    val = {val{:}, '100'};
                elseif m == 2 && numel_regionprops == 1   % compara si la correlacion mayor fue con el 2 y hay una region detectada (2 mil)
                    disp('2 mil')
                    valor_total=valor_total+2;
                    val = {val{:}, '2'};
                elseif m == 2 && numel_regionprops == 2   % compara si la correlacion mayor fue con el 2 y hay dos regiones detectadas (20 mil)
                    disp('20 mil')
                    valor_total=valor_total+20;
                    val = {val{:}, '20'};
                elseif m == 2 && numel_regionprops == 3   % compara si la correlacion mayor fue con el 2 y hay tres regiones detectadas (200 mil -> no existe)
                    disp('numero invalido')
                elseif m == 3 && numel_regionprops == 1   % compara si la correlacion mayor fue con el 5 y hay una region detectada (5 mil)
                    disp('5 mil')
                    valor_total=valor_total+5;
                    val = {val{:}, '5'};
                elseif m == 3 && numel_regionprops == 2   % compara si la correlacion mayor fue con el 5 y hay dos regiones detectadas (50 mil)
                    disp('50 mil')
                    valor_total=valor_total+50;
                    val = {val{:}, '50'};
                elseif m == 3 && numel_regionprops == 3   % compara si la correlacion mayor fue con el 5 y hay tres regiones detectadas (500 mil -> no existe)
                    disp('numero invalido')
                end
                hold off;
            
            end
        end

    end
    
    if flag == 0
        titulo = sprintf('Dinero total en la iamgen : %d mil pesos', valor_total);
        subplot(2, 3, [1,2,3]); imshow(imagen_gris); title(titulo);
        if length(val) == 3
            titulo1 = sprintf('Primer numero: %s', val{1});
            subplot(2, 3, 4); imshow(numeros{1}); title(titulo1);
            titulo2 = sprintf('Segundo numero: %s', val{2});
            subplot(2, 3, 5); imshow(numeros{2}); title(titulo2);
            titulo3 = sprintf('Tercer numero: %s', val{3});
            subplot(2, 3, 6); imshow(numeros{3}); title(titulo3);
        elseif length(val) == 2
            titulo1 = sprintf('Primer numero: %s', val{1});
            subplot(2, 3, 4); imshow(numeros{1}); title(titulo1);
            titulo2 = sprintf('Segundo numero: %s', val{2});
            subplot(2, 3, 5); imshow(numeros{2}); title(titulo2);
        elseif length(val) == 1
            titulo1 = sprintf('Primer numero: %s', val{1});
            subplot(2, 3, 4); imshow(numeros{1}); title(titulo1);
        end
        disp('el dinero total en la imagen es: ')
        disp(valor_total)
        disp(val)
        valor_total = 0;
        %pause
    end
   
end

%--------------------------------------------------------------------------
%----------------------  FIN  ---------------------------------------------
%--------------------------------------------------------------------------
