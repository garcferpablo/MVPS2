clear

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CREAR LISTA DE ESTÍMULOS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% primero establecemos si queremos generar una nueva lista de estímulos o
% reutilizar una lista ya generada (buscamos usar la misma en todos los
% participantes)
random = 0; %input('Escribe "1" si quieres generar un nuevo set de imágenes: ') == 1;

% semilla del generador basada en hora actual, asegurando secuencia aleatoria distinta en cada llamada a randperm.
rng('shuffle')

% añadimos el directorio de los fondos
directoriof='.\fondos\';
cd(directoriof) 

path_images=genpath('.\fondos\'); 
addpath(path_images)

% añadimos la ruta de las imagenes
directorio='.\imagenes_jpg_definitivo\';
cd(directorio)

path_images=genpath('.\imagenes_jpg_definitivo\');
addpath(path_images)

%% Cargar o generar configuraciones
if random
    % Generar nuevas asociaciones
    carpetasf = dir(directoriof);
    car_f = carpetasf(3:end);
    car_f = car_f(randperm(length(car_f)));

    carpetas1 = dir(directorio);
    car_a = carpetas1(3:end);
    car_a = car_a(randperm(length(car_a)));

    if input('Escribe "1" si quieres guardar este nuevo set: ') == 1
        save('..\config_fijos.mat', 'car_f', 'car_a');
    end
else
    % Cargar asociaciones fijas
    load('..\config_fijos.mat');
end

%%% cogemos las que vamos a utilizar como old, sim, y new
ejem6=car_a(1:60); %30 categ para old y 30 para sim
ejem_new=car_a(61:90); %30 categ para news

%%%%%%% NEW %%%%%%%
for i=1:length(ejem_new) % recorre las carpetas 7 a 9 (versión larga 61 a 90)
    ejemplares_new=dir([directorio ejem_new(i).name]); %cogemos sólo los nombres
    ejemplares_new=ejemplares_new(3:end);%selecciona del tercero en adelante
    cat_new=randperm(length(ejemplares_new));%desordena los ejemplares new
    new{i,1}=ejemplares_new(cat_new(1)).name; %selecciona un ítem de la categoría al azar
end
new=[new new]; %duplica la columna para mantener la estructura



%%%%%%% ASIGNACIÓN FIJA DE ÍTEMS Y FONDOS %%%%%%%
orden_rand = randperm(60); %orden aleatorio de presentación de cada categ

%%%%%%% MISMO FONDO (old y similar) %%%%%%%
for i=1:30
    idx = orden_rand(i);
    ejemplares_6 = dir(fullfile(directorio, ejem6(idx).name));
    ejemplares_6 = ejemplares_6(3:end);
    cat_6=[1, 2, 3, 4, 5, 6, 7];  % coge siempre las mismas - en orden

    % Orden fijo intracategorial (siempre mismo 1º, 2º, 3º ítem)
    old_6_1{i,1}= ejemplares_6(cat_6(1)).name;
    old_6_2{i,1}= ejemplares_6(cat_6(2)).name;
    old_6_3{i,1}= ejemplares_6(cat_6(3)).name;
    similar_6{i,1}=ejemplares_6(cat_6(6)).name;

    fondo{i} = car_f(idx).name;
end

% combinar items "old" en una lista (los q se presentarán en la codif)
lista=[old_6_1;old_6_2;old_6_3]; %ej:lista=[(piano3,...);(piano4,...);(piano6,...)]
% repetir lista de fondos para asociar cada item a un fondo
fondo_lista=[fondo fondo fondo]; %ej:fondo_lista=[(fondo34,...);(fondo34,...);(fondo34,...)]

% Generación de índices para reordenación
o = 1:30;
orden=repmat(o,1,3); %índice de cada categoría (ej:los pianos tendrán el 1)
tri(1:30)=1;tri(31:60)=2;tri(61:90)=3; %índice de cada trial (piano3=1, piano4=2...)

rp=randperm(90);
rp_or=orden(rp);% orden aleatorio de presentación de categorías (cada una sale 3 veces)

%extraer índice de presentación para cada categoría
for i=1:30
    [a, b]=find(rp_or==i); % 'a' solo se usa porque find() devuelve dos salidas (fila y columna)
    IA(i,1)=b(1); IA_2(i,1)=b(2); IA_3(i,1)=b(3);
end
orden_perm=[IA;IA_2;IA_3];

%asignar el nuevo orden a 'lista_6_0'
for i=1:90
    lista_6_0{1,orden_perm(i)}=lista(i,1);
    lista_6_0{2,orden_perm(i)}=cell2mat(fondo_lista(i));
    tri_6_0(orden_perm(i))=tri(i);
end

% variable probe_6_0 para condición MISMO FONDO 
probe_6_0=[old_6_1 similar_6];%primer ítem presentado/categoría y 1 lure/categoría (para recuperación)


%%%%%%% DISTINTO FONDO (old y similar) %%%%%%%
for i=31:60
    idx = orden_rand(i);
    ejemplares_6 = dir(fullfile(directorio, ejem6(idx).name));
    ejemplares_6= ejemplares_6(3:end);
    cat_6=[1, 2, 3, 4, 5, 6, 7];  % coge siempre las mismas - en orden

    % Orden fijo intracategorial (siempre mismo 1º, 2º, 3º ítem)
    old_6_1{i-30,1}=ejemplares_6(cat_6(1)).name;
    old_6_2{i-30,1}=ejemplares_6(cat_6(2)).name;
    old_6_3{i-30,1}=ejemplares_6(cat_6(3)).name;
    similar_6{i-30,1}=ejemplares_6(cat_6(6)).name;

    fondo{i-30}=car_f(idx).name;
end

% Se repite el proceso de reordenación para esta condición
lista=[old_6_1;old_6_2;old_6_3];
fondo_lista=[fondo fondo fondo];
o=1:30;
orden=repmat(o,1,3);
tri(1:30)=1;tri(31:60)=2;tri(61:90)=3;
rp= randperm(90);
rp_or=orden(rp);

for i=1:30
    [a, b]=find(rp_or==i);
    IA(i,1)=b(1); IA_2(i,1)=b(2); IA_3(i,1)=b(3);
end
orden_perm=[IA;IA_2;IA_3];
for i=1:90
    lista_6_1{1,orden_perm(i)}=lista(i,1); % imagen
    lista_6_1{2,orden_perm(i)}=cell2mat(fondo_lista(i)); % fondo
    tri_6_1(orden_perm(i))=tri(i); % etiqueta de posición
end

% Se crea la variable 'probe_6_1' para la condición DISTINTO FONDO
probe_6_1=[old_6_1 similar_6]; %(primer ítem presentado/categoría y 1 lure/categoría (para recuperación))
 
% Se combinan estímulos de ambas condiciones y los 'new', formando la matriz final de probes  
probe=[probe_6_0;probe_6_1;new]';  %%%archivo que tengo que guardar para presentar en la recuperación

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ASIGNACIÓN FINAL DE FONDOS A LA PRESENTACIÓN %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Se crean dos condiciones (0 y 1) para asignar fondos de dos tipos
   
i0=1; % contador para la condición "distinto fondo"
i1=1; % contador para la condición "mismo fondo"

fondo_z(1:90)=zeros;fondo_z(91:180)=ones; % 90 ensayos con código 0 (mismo fondo) y 90 con código 1 (distinto fondo)
al=randperm(180); % baraja los índices del 1 al 180
fondo_orden=fondo_z(al); %reordena aleatoriamente los códigos 0 y 1

% Bucle para asignar definitivamente el ítem y el fondo correspondiente a
% cada ensayo
for i=1:180

    % MISMO FONDO (0): toma item y fondo de lista_6_0
    if fondo_orden(i)==0
        lista_def{1,i}=lista_6_0{1,i0}; % imagen
        lista_def{2,i}=lista_6_0{2,i0}; % fondo correspondiente
        lista_def_orden(i,1)=tri_6_0(i0); % guarda el índice de presentación
        i0=i0+1; % incrementa el contador para la condición

    % DISTINTO FONDO (1): toma item y fondo de lista_6_1
    elseif fondo_orden(i)==1
        lista_def{1,i}=lista_6_1{1,i1};
        lista_def{2,i}=lista_6_1{2,i1};

        %multiplica x10 el índice del item para diferenciar la condición
        lista_def_orden(i,1)=tri_6_1(i1)*10; % índices multiplos de 10-> DISTINTO FONDO

        i1=i1+1;
    end
end

cd ..

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BLOQUE PRINCIPAL: CONFIGURACIÓN DEL EXPERIMENTO CON PSYCHTOOLBOX %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try

    % Introducir datos del participante
    sname=input('Introduzca iniciales del participante: ','s'); %lg, op, rt, ....
    subj=input('Introduzca número de participante: ','s'); %01, 02, 03...
    trial=input('Introduzca el ensayo desde el que empezamos: ','s'); %empezamos en el 1, si se para, nos fijamos en la i e iniciamos desde esa la siguiente vez
    
    % guardamos la lista definitiva de estímulos, la ordenación y los probes 
    % en un archivo
    save(['.\listas\' subj '_' sname '_lista'], 'lista_def','lista_def_orden','probe');
    
    % se define el nombre del archivo donde se guardaran los resultados de
    % la codificacion
    results_file=['.\listas\' subj '_' sname '_cod_res'];

    %% Configuracion y visualizacion usando Psychtoolbox

    rng('shuffle') % Re-incicializa el generador de numeros aleatorios

    % Cierra todas las ventanas y figuras abiertas
    sca;
    close all;
    % clearvars; %limpia todas las variables del workspace

    % Bring the Command Window to the front if it is already open
    if ~IsOctave; commandwindow; end

    % Initialize PsychSound for calibration/validation audio feedback
    InitializePsychSound(); %ELIMINAR?

    % Establece los parametros predeterminados de psychtoolbox
    PsychDefaultSetup(2);

    %% STEP 1: INITIALIZE EYELINK CONNECTION; OPEN EDF FILE; GET EYELINK TRACKER VERSION

    % Initialize EyeLink connection (dummymode = 0) or run in "Dummy Mode" without an EyeLink connection (dummymode = 1);
    dummymode = 0;

    % Optional: Set IP address of eyelink tracker computer to connect to.
    % Call this before initializing an EyeLink connection if you want to use a non-default IP address for the Host PC.
    %Eyelink('SetAddress', '10.10.10.240');

    EyelinkInit(dummymode); % Initialize EyeLink connection
    status = Eyelink('IsConnected');
    if status < 1 % If EyeLink not connected
        dummymode = 1;
    end

    % Open dialog box for EyeLink Data file name entry. File name up to 8 characters
    %      prompt = {'Enter EDF file name (up to 8 characters)'};
    %      dlg_title = 'Create EDF file';
    %      def = {subj '_' sname}; % Create a default edf file name
    %      answer = inputdlg(prompt, dlg_title, 1, def); % Prompt for new EDF file name
    % Print some text in Matlab's Command Window if a file name has not been entered
    %      if  isempty(answer)
    %          fprintf('Session cancelled by user\n')
    %          error('Session cancelled by user'); % Abort experiment (see cleanup function below)
    %      end
    edfFile = [subj,'_cod']; % Save file name to a variable
    % Print some text in Matlab's Command Window if file name is longer than 8 characters
    if length(edfFile) > 8
        fprintf('Filename needs to be no more than 8 characters long (letters, numbers and underscores only)\n');
        error('Filename needs to be no more than 8 characters long (letters, numbers and underscores only)');
    end

    % Open an EDF file and name it
    failOpen = Eyelink('OpenFile', edfFile);
    if failOpen ~= 0 % Abort if it fails to open
        fprintf('Cannot create EDF file %s', edfFile); % Print some text in Matlab's Command Window
        error('Cannot create EDF file %s', edfFile); % Print some text in Matlab's Command Window
    end

    % Get EyeLink tracker and software version
    % <ver> returns 0 if not connected
    % <versionstring> returns 'EYELINK I', 'EYELINK II x.xx', 'EYELINK CL x.xx' where 'x.xx' is the software version
    ELsoftwareVersion = 0; % Default EyeLink version in dummy mode
    [ver, versionstring] = Eyelink('GetTrackerVersion');
    if dummymode == 0 % If connected to EyeLink
        % Extract software version number.
        [~, vnumcell] = regexp(versionstring,'.*?(\d)\.\d*?','Match','Tokens'); % Extract EL version before decimal point
        ELsoftwareVersion = str2double(vnumcell{1}{1}); % Returns 1 for EyeLink I, 2 for EyeLink II, 3/4 for EyeLink 1K, 5 for EyeLink 1KPlus, 6 for Portable Duo
        % Print some text in Matlab's Command Window
        fprintf('Running experiment on %s version %d\n', versionstring, ver );
    end
    % Add a line of text in the EDF file to identify the current experimemt name and session. This is optional.
    % If your text starts with "RECORDED BY " it will be available in DataViewer's Inspector window by clicking
    % the EDF session node in the top panel and looking for the "Recorded By:" field in the bottom panel of the Inspector.
    preambleText = sprintf('RECORDED BY Psychtoolbox demo %s session name: %s', mfilename, edfFile);
    Eyelink('Command', 'add_file_preamble_text "%s"', preambleText);


    %% STEP 2: SELECT AVAILABLE SAMPLE/EVENT DATA
    % See EyeLinkProgrammers Guide manual > Useful EyeLink Commands > File Data Control & Link Data Control

    % Select which events are saved in the EDF file. Include everything just in case
    Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
    % Select which events are available online for gaze-contingent experiments. Include everything just in case
    Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,BUTTON,FIXUPDATE,INPUT');
    % Select which sample data is saved in EDF file or available online. Include everything just in case
    if ELsoftwareVersion > 3  % Check tracker version and include 'HTARGET' to save head target sticker data for supported eye trackers
        Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,RAW,AREA,HTARGET,GAZERES,BUTTON,STATUS,INPUT');
        Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');
    else
        Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,RAW,AREA,GAZERES,BUTTON,STATUS,INPUT');
        Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
    end

    %% STEP 3: OPEN GRAPHICS WINDOW

    % obtiene los numeros de pantalla disponibles
    screens = Screen('Screens');
    Screen('Preference', 'SkipSyncTests', 1) % Se saltan las pruebas de sincronización (útil para pruebas rápidas) %% Cuidado 1 o 0
    screenNumber = max(screens); % Selecciona el monitor externo, si está disponible

    % Define los colores básicos a utilizar
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    grey = white / 2;
    inc = white - grey;

     % Carga el fixation point
    fixpPath = 'fixTarget.jpg';
    fixpMatrix = imread(fixpPath);

    % Abre una ventana de presentación en la pantalla seleccionada
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

    % Obtiene el tamaño de la ventana y otros parametros importantes
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    width=screenXpixels;
    height=screenYpixels;
    ifi = Screen('GetFlipInterval', window);  % intervalo de refresco de la pantalla
    [xCenter, yCenter] = RectCenter(windowRect); % coordenadas del centro de la pantalla

    % activa el alpha-blending para q las lineas se dibujen de forma suave
    % (anti-aliasing)
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    HideCursor % oculta el cursor

    %      % Open experiment graphics on the specified screen
    %      if isempty(screenNumber)
    %          screenNumber = max(Screen('Screens')); % Use default screen if none specified
    %      end
    %      window = Screen('OpenWindow', screenNumber, [128 128 128]); % Open graphics window
    %      Screen('Flip', window);
    %      % Return width and height of the graphics window/screen in pixels
    %      [width, height] = Screen('WindowSize', window);


    %% STEP 4: SET CALIBRATION SCREEN COLOURS/SOUNDS; PROVIDE WINDOW SIZE TO EYELINK HOST & DATAVIEWER; SET CALIBRATION PARAMETERS; CALIBRATE

    % Provide EyeLink with some defaults, which are returned in the structure "el".
    el = EyelinkInitDefaults(window);
    % set calibration/validation/drift-check(or drift-correct) size as well as background and target colors.
    % It is important that this background colour is similar to that of the stimuli to prevent large luminance-based
    % pupil size changes (which can cause a drift in the eye movement data)
    el.calibrationtargetsize = 3;% Outer target size as percentage of the screen
    el.calibrationtargetwidth = 0.7;% Inner target size as percentage of the screen
    el.backgroundcolour = [128 128 128];% RGB grey
    el.calibrationtargetcolour = [0 0 0];% RGB black
    % set "Camera Setup" instructions text colour so it is different from background colour
    el.msgfontcolour = [0 0 0];% RGB black

    % Use an image file instead of the default calibration bull's eye targets.
    % Commenting out the following two lines will use default targets:
    el.calTargetType = 'image';
    el.calImageTargetFilename = [pwd '/' 'fixTarget.jpg'];

    % Set calibration beeps (0 = sound off, 1 = sound on)
    el.targetbeep = 0;  % sound a beep when a target is presented
    el.feedbackbeep = 0;  % sound a beep after calibration or drift check/correction

    % You must call this function to apply the changes made to the el structure above
    EyelinkUpdateDefaults(el);

    % Set display coordinates for EyeLink data by entering left, top, right and bottom coordinates in screen pixels
    Eyelink('Command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1); % 0, 0 (esq sup izq) y width-1, height-1 (esq inf dcha)
    
    %Eyelink('Command','screen_pixel_coords = %ld %ld %ld %ld', 20, 20, width-20, height-20)
    
    % Write DISPLAY_COORDS message to EDF file: sets display coordinates in DataViewer
    % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Pre-trial Message Commands
    Eyelink('Message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);

    %Eyelink('Message', 'DISPLAY_COORDS %ld %ld %ld %ld', 20, 20, width-20, height-20);
    
    % Set number of calibration/validation dots and spread: horizontal-only(H) or horizontal-vertical(HV) as H3, HV3, HV5, HV9 or HV13
    Eyelink('Command', 'calibration_type = HV5'); % horizontal-vertical 5-points

    % Allow a supported EyeLink Host PC button box to accept calibration or drift-check/correction targets via button 5
    Eyelink('Command', 'button_function 5 "accept_target_fixation"');
    % Hide mouse cursor
    HideCursor(screenNumber);
    % Start listening for keyboard input. Suppress keypresses to Matlab windows.
    % ListenChar(-1);
    Eyelink('Command', 'clear_screen 0'); % Clear Host PC display from any previus drawing
    % Put EyeLink Host PC in Camera Setup mode for participant setup/calibration
    EyelinkDoTrackerSetup(el);


    %Cargar instrucciones
    Instrucciones_imagen=imread('.\instrucciones_imagenes\codificacion_tarea.jpg');
    [s1, s2, s3] = size(Instrucciones_imagen);
    imageTexture = Screen('MakeTexture', window,Instrucciones_imagen);
    Screen('DrawTexture', window, imageTexture, [], [], 0);
    Screen('Flip', window);
    KbStrokeWait;
    WaitSecs(2) %cambiar a 2

    for i= str2num(trial):length(lista_def)  % lista_def tiene combinación de imágenes y fondos que vamos a presentar 180 ensayos

        if i > 1
            tiempo_total=toc;
        end

        % STEP 5.1: START TRIAL; SHOW TRIAL INFO ON HOST PC; SHOW BACKDROP IMAGE AND/OR DRAW FEEDBACK GRAPHICS ON HOST PC; DRIFT-CHECK/CORRECTION

        % Write TRIALID message to EDF file: marks the start of a trial for DataViewer
        % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Defining the Start and End of a Trial
        Eyelink('Message', 'TRIALID %d', i);
        % Write !V CLEAR message to EDF file: creates blank backdrop for DataViewer
        % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Simple Drawing
        Eyelink('Message', '!V CLEAR %d %d %d', el.backgroundcolour(1), el.backgroundcolour(2), el.backgroundcolour(3));
        % Supply the trial number as a line of text on Host PC screen
        Eyelink('Command', 'record_status_message "TRIAL %d/%d"', i, length(lista_def));

        %%%%%%%%%%%%% PARA HACER DESCANSOS
        %          if i==240 ||i==720
        %              descanso_imagen=imread('.\instrucciones_imagenes\codificacion_descanso.jpg');
        %              [s1, s2, s3] = size(descanso_imagen);
        %              imageTexture = Screen('MakeTexture', window, descanso_imagen);
        %              Screen('DrawTexture', window, imageTexture, [], [], 0);
        %              Screen('Flip', window);
        %              KbStrokeWait;
        %          if i==10  % dejamos un descanso a la mitad
        %              descanso_mitad=imread('.\instrucciones_imagenes\descanso_mitad.jpg');
        %              [s1, s2, s3] = size(descanso_imagen);
        %              imageTexture = Screen('MakeTexture', window, descanso_mitad);
        %              Screen('DrawTexture', window, imageTexture, [], [], 0);
        %              Screen('Flip', window);
        %              KbStrokeWait;
        %          end


        % Draw graphics on the EyeLink Host PC display. See COMMANDS.INI in the Host PC's exe folder for a list of commands
        Eyelink('SetOfflineMode');% Put tracker in idle/offline mode before drawing Host PC graphics and before recording
        Eyelink('Command', 'clear_screen 0'); % Clear Host PC display from any previus drawing
        % Optional: Send an image to the Host PC to be displayed as the backdrop image over which
        % the gaze-cursor is overlayed during trial recordings.
        % See Eyelink('ImageTransfer?') for information about supported syntax and compatible image formats.
        % Below, we use the new option to pass image data from imread() as the imageArray parameter, which
        % enables the use of many image formats.
        % [status] = Eyelink('ImageTransfer', imageArray, xs, ys, width, height, xd, yd, options);
        % xs, ys: top-left corner of the region to be transferred within the source image
        % width, height: size of region to be transferred within the source image (note, values of 0 will include the entire width/height)
        % xd, yd: location (top-left) where image region to be transferred will be presented on the Host PC
        % This image transfer function works for non-resized image presentation only. If you need to resize images and use this function please resize
        % the original image files beforehand

        % --- MOSTRAR FONDO ---
        theFondo = imread(lista_def{2,i}); %carga el fondo para el ensayo
        % theFondo = imread(cell2mat(fondo_lista{i})); %opcion para cargar la imagen desde fondo_lista        
        fondoName = lista_def{2,i};
        fondoInfo = imfinfo(fondoName); % Get background file info
        [s1, s2, s3] = size(theFondo);
        fondoTexture = Screen('MakeTexture', window, theFondo);
        %dibuja el fondo en una region fija de la pantalla (se especifica 
        %una resolucion fija)
        Screen('DrawTexture', window, fondoTexture, [], [0 0 1920 1080], 0);
        

        % --- MOSTRAR ITEM (estimulo) ---
        theImage = imread(cell2mat(lista_def{1,i}));
        imgName = cell2mat(lista_def{1,i});
        fondoName = lista_def{2,i};

        [s1, s2, s3] = size(theImage);

        %verifica q la imagen no sea demasiado grande para la pantalla
        if s1 > screenYpixels || s2 > screenYpixels
            disp('ERROR! Image is too big to fit on the screen');

            sca;
            return;
        end

        imgInfo = imfinfo(imgName); % Get image file info
        imageTexture = Screen('MakeTexture', window, theImage);
        Screen('DrawTexture', window, imageTexture, [], [], 0);
        
        transferStatus = Eyelink('ImageTransfer', theImage, 0, 0, 0, 0, round(width/2-imgInfo.Width/2), round(height/2-imgInfo.Height/2));
        if dummymode == 0 && transferStatus ~= 0 % If connected to EyeLink and image transfer fails
            fprintf('Image transfer Failed\n'); % Print some text in Matlab's Command Window
        end

        
        % --- Mensajes para DataViewer ---
        Eyelink('Message', '!V IMGLOAD CENTER %s %d %d', imgName, width/2, height/2); % Imagen
        

        %Optional: draw feedback box and lines on Host PC interface instead of (or on top of) backdrop image.
        % Coordenadas del área de interés (la imagen cuadrada)
        Eyelink('Command', 'draw_box %d %d %d %d 15', round(width/2-imgInfo.Width/2), round(height/2-imgInfo.Height/2), round(width/2+imgInfo.Width/2), round(height/2+imgInfo.Height/2));
       


        %STEP 5.2: START RECORDING

        % Put tracker in idle/offline mode before recording. Eyelink('SetOfflineMode') is recommended
        % however if Eyelink('Command', 'set_idle_mode') is used allow 50ms before recording as shown in the commented code:
        % Eyelink('Command', 'set_idle_mode');% Put tracker in idle/offline mode before recording
        % WaitSecs(0.05); % Allow some time for transition
        Eyelink('SetOfflineMode');% Put tracker in idle/offline mode before recording
        Eyelink('StartRecording'); % Start tracker recording
        %%%%%%%%WaitSecs(0.1); % Allow some time to record a few samples before presenting first stimulus

        % STEP 5.3: PRESENT STIMULUS; CREATE DATAVIEWER BACKDROP AND INTEREST AREA

        Screen('Flip', window);
        


        % Write message to EDF file to mark the start time of stimulus presentation.
        Eyelink('Message', 'STIM_ONSET');
        % Write !V IMGLOAD message to EDF file: provides instructions for DataViewer so it will show trial stimulus as backdrop
        Eyelink('Message', '!V IMGLOAD FILL %s %d %d', fondoInfo.Filename, width/2, height/2);
        % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Image Commands
        Eyelink('Message', '!V IMGLOAD CENTER %s %d %d', imgInfo.Filename, width/2, height/2);

        % Write !V IAREA message to EDF file: creates interest area around image in DataViewer
        % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Interest Area Commands
        Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 1, round(width/2-imgInfo.Width/2), round(height/2-imgInfo.Height/2), round(width/2+imgInfo.Width/2), round(height/2+imgInfo.Height/2),'IMAGE_IA');


        FlushEvents('keyDown');
        res_key = 0;
        res_tr = 0;
        time=0;
        t1 = GetSecs;
        while time < 2.5         % maximum wait time: 1.5 s CAMBIAR
            err = Eyelink('CheckRecording');
            if(err ~= 0)
                fprintf('EyeLink Recording stopped!\n');
                % Transfer a copy of the EDF file to Display PC
                Eyelink('SetOfflineMode');% Put tracker in idle/offline mode
                Eyelink('CloseFile'); % Close EDF file on Host PC
                Eyelink('Command', 'clear_screen 0'); % Clear trial image on Host PC at the end of the experiment
                WaitSecs(0.1); % Allow some time for screen drawing
                % Transfer a copy of the EDF file to Display PC
                transferFile(edfFile, el, dummymode, window, height); % See transferFile function below)
                error('EyeLink is not in record mode when it should be. Unknown error. EDF transferred from Host PC to Display PC, please check its integrity.');
            end
            [keyIsDown,t2,keyCode] = KbCheck;    % determine state of keyboard
            time = t2-t1;
            if (keyIsDown)      % has a key been pressed
                key = KbName(find(keyCode));            % find key's name
                res_key = (find(keyCode));            % find key's nameres_key = key;
                res_tr = time;
                temp = KbName(find(keyCode));
                temp=temp(1)
                % Write message to EDF file to mark the spacebar press time
                Eyelink('Message', 'KEY_PRESSED');
                if strcmp(temp,'q')
                    Screen('CloseAll');
                    ShowCursor;
                    error('Program interrumpted.');
                    break;
                end
                %             break;
            end
        end




        % %Presentar 'blanckscreen' con fix point
        % fixpTexture = Screen('MakeTexture', window, fixpMatrix);
        % [fixpHeight, fixpWidth, ~] = size(fixpMatrix);
        % dstRect = CenterRectOnPointd([0 0 fixpWidth fixpHeight], xCenter, yCenter);
        % Screen('FillRect', window, grey);
        % Screen('DrawTexture', window, fixpTexture, [], dstRect);
        % Screen('Flip', window);
        
        % % Write message to EDF file to mark time when blank screen is presented
        % Eyelink('Message', 'BLANK_SCREEN');
        % Write !V CLEAR message to EDF file: creates blank backdrop for DataViewer
        % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Simple Drawing
        Eyelink('Message', '!V CLEAR %d %d %d', el.backgroundcolour(1), el.backgroundcolour(2), el.backgroundcolour(3));

        % Stop recording eye movements at the end of each trial
        WaitSecs(0.1); % Add 100 msec of data to catch final events before stopping
        Eyelink('StopRecording'); % Stop tracker recording

        %Perform a drift check/correction.
        %Optionally provide x y target location, otherwise target is presented on screen centre
        EyelinkDoDriftCorrection(el, round(width/2), round(height/2)); 

        %WaitSecs(1); %Cambiar a 1

        tic

        if i > 1
            resultados.tiempo_ensayo(i-1)=tiempo_total;
        end

        resultados.ejemplar(i)=lista_def(i);resultados.lista_def_orden(i)=lista_def_orden(i);resultados.res_key(i)=res_key; resultados.tr(i)=res_tr;
        save (results_file, 'resultados')

        % STEP 5.5: CREATE VARIABLES FOR DATAVIEWER; END TRIAL

        % Write !V TRIAL_VAR messages to EDF file: creates trial variables in DataViewer
        % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Trial Message Commands
        Eyelink('Message', '!V TRIAL_VAR iteration %d', i); % Trial iteration
        Eyelink('Message', '!V TRIAL_VAR image %s', imgInfo.Filename); % Image name and path   
        Eyelink('Message', '!V TRIAL_VAR bothimages %s', fondoName); % fondo
        Eyelink('Message', '!V TRIAL_VAR cond %d', lista_def_orden(i)); % Condicion    

        WaitSecs(0.001); % Allow some time between messages. Some messages can be lost if too many are written at the same time
        
        % Eyelink('Message', '!V TRIAL_VAR rt %d', reactionTime); % Reaction time
        
        % Write TRIAL_RESULT message to EDF file: marks the end of a trial for DataViewer
        % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Defining the Start and End of a Trial
        Eyelink('Message', 'TRIAL_RESULT 0');
        WaitSecs(0.01); % Allow some time before ending the trial

        % Clear Screen() textures that were initialized for each trial iteration
        Screen('Close', imageTexture);
        clear tiempo_total
    end

    %% STEP 6: CLOSE EDF FILE. TRANSFER EDF COPY TO DISPLAY PC. CLOSE EYELINK CONNECTION. FINISH UP

    % Put tracker in idle/offline mode before closing file. Eyelink('SetOfflineMode') is recommended.
    % However if Eyelink('Command', 'set_idle_mode') is used, allow 50ms before closing the file as shown in the commented code:
    % Eyelink('Command', 'set_idle_mode');% Put tracker in idle/offline mode
    % WaitSecs(0.05); % Allow some time for transition
    Eyelink('SetOfflineMode'); % Put tracker in idle/offline mode
    Eyelink('Command', 'clear_screen 0'); % Clear Host PC backdrop graphics at the end of the experiment
    WaitSecs(0.5); % Allow some time before closing and transferring file
    Eyelink('CloseFile'); % Close EDF file on Host PC
    % Transfer a copy of the EDF file to Display PC
    transferFile(edfFile, el, dummymode, window, height); % See transferFile function below

    % cargamos imagen de despedida
    despedida_imagen=imread('.\instrucciones_imagenes\despedida_imagen.jpg');
    [s1, s2, s3] = size(despedida_imagen);
    imageTexture = Screen('MakeTexture', window, despedida_imagen);
    Screen('DrawTexture', window, imageTexture, [], [], 0);
    Screen('Flip', window);
    KbStrokeWait;

    sca;
    % % flush(s) %esto genera error si no estamos conectados al puerto
    % delete(s)
    % clear s
catch
    % Print error message and line number in Matlab's Command Window
    psychrethrow(psychlasterror);
    % ListenChar(0);
    sca;
end


cleanup;


