% Configuración de directorios de imágenes
clear();
rng('shuffle')

directorio='.\imagenes_jpg_definitivo\';
cd(directorio)

path_images=genpath('.\imagenes_jpg_definitivo\');
addpath(path_images)

% Introducimos datos para recuperar la lista del participante
sname=input('Introduzca las iniciales del participante: ','s');
subj=input('Introduzca el número de participante: ','s');
load(['.\listas\' subj '_' sname '_lista']);

% Obtener lista de fondos usados en codificación
fondos_usados = unique(lista_def(2, :)); % Fondos que ya aparecieron en codificación

% Generar lista completa de fondos disponibles
directorio_fondos = '.\fondos\';
carpetas_fondos = dir(directorio_fondos); % Lista de archivos y carpetas en fondos
todos_fondos = {carpetas_fondos(3:end).name}; % omite las entradas '.' y '..'
fondos_nuevos = setdiff(todos_fondos, fondos_usados); % Fondos no usados previamente

%% CONFIGURACIÓN DE LAS CONDICIONES DE RECUPERACIÓN
tr=ones(1,30)*0; % 30 ensayos mismo fondo
tr(31:60)=ones(1,30)*1; % 30 ensayos distinto fondo
tr(61:90)=ones(1,30)*9; % 30 new
tr=tr'; %trasponer

% Variable auxiliar para escoger entre los 2 ítems por categoría (0->old y
% 1-> sim; en el caso de los new ambos ítems son iguales)
o_s=zeros(1,90);
o_s([1:15 31:45 61:75])=ones;

% Aleatorización
per=randperm(90);
orden_probe=tr(per); % orden aleatorio de condiciones (mismo/distinto/new)
orden_sim=o_s(per); % orden aleatorio para seleccionar entre ítems (old/sim)

% Segmentar variable 'probe' de la codificación
% probe = [probe_6_0 (mismo); probe_6_1 (distinto); new]
probe_1=probe(:,1:30); % mismo fondo que en codificacion
probe_2=probe(:,31:60);% distinto fondo que en codificacion
probe_3=probe(:,61:90);% new con distinto fondo que en codificacion

i1=1; %contador para probe_1 (mismo)
i2=1; %contador para probe_2 (distinto)
i3=1; %contador para probe_3 (new)

% Para los fondos nuevos disponibles
fondos_disponibles = fondos_nuevos;
fondos_usados_recuperacion = []; % Para registrar los fondos asignados

for i=1:90
    num=orden_sim(i); %aleatoriza selección de ítem 0 (old) o el 1 (sim)
    fondo_actual = '';

    if orden_probe(i)==0
        if num==0
            imagen{i}=probe_1(1,i1); %old

            % Buscar el fondo correspondiente en lista_def
            imagen_folder = strsplit(char(probe_1(1, i1)), '\');  % Convertir a cadena y dividir
            imagen_name = imagen_folder{end};  % Nombre de la imagen
            lista_imagenes = cellfun(@char, lista_def(1, :), 'UniformOutput', false);  % Convertimos las celdas a char
            [~, idx] = ismember(imagen_name, lista_imagenes);  % Encuentra la posición de la imagen
            if idx > 0
                fondo_asignado{i} = lista_def{2, idx};  % Asignar el fondo correspondiente
            end
            trigger(i)=10; %mismo fondo OLD

        elseif num==1
            imagen{i}=probe_1(2,i1); %similar
            imagen_folder = strsplit(char(probe_1(1, i1)), '\');  % Convertir a cadena y dividir
            imagen_name = imagen_folder{end};  % Nombre de la imagen
            lista_imagenes = cellfun(@char, lista_def(1, :), 'UniformOutput', false);  % Convertimos las celdas a char
            [~, idx] = ismember(imagen_name, lista_imagenes);  % Encuentra la posición de la imagen
            if idx > 0
                fondo_asignado{i} = lista_def{2, idx};  % Asignar el fondo correspondiente
            end
            trigger(i)=15; %mismo fondo que su carpeta de objetos, pero es un SIMILAR
        end
        i1=i1+1;
    elseif orden_probe(i)==1
        if num==0
            imagen{i}=probe_2(1,i2); %old
            trigger(i)=20; %distinto fondo OLD

            % Asignar un fondo nuevo sin repetir
            fondo_asignado{i} = fondos_disponibles{randi(length(fondos_disponibles))};  % Fondo nuevo aleatorio
            % Eliminar el fondo asignado de la lista de fondos disponibles
            fondos_disponibles(strcmp(fondos_disponibles, fondo_asignado{i})) = [];

        elseif num==1
            imagen{i}=probe_2(2,i2); %similar
            % Asignar un fondo nuevo sin repetir
            fondo_asignado{i} = fondos_disponibles{randi(length(fondos_disponibles))};  % Fondo nuevo aleatorio
            % Eliminar el fondo asignado de la lista de fondos disponibles
            fondos_disponibles(strcmp(fondos_disponibles, fondo_asignado{i})) = [];

            trigger(i)=25; %distinto fondo SIMILAR
        end
        i2=i2+1;
    elseif orden_probe(i)==9
        imagen{i}=probe_3(1,i3);
        % Asignar un fondo nuevo sin repetir
        fondo_asignado{i} = fondos_disponibles{randi(length(fondos_disponibles))};  % Fondo nuevo aleatorio
        % Eliminar el fondo asignado de la lista de fondos disponibles
        fondos_disponibles(strcmp(fondos_disponibles, fondo_asignado{i})) = [];

        trigger(i)=30; %new
        i3=i3+1;
    end

end

%%%% guardar las imagenes que se presentan%%%
save (['.\respuestas\' subj '_' sname '_archivos_probe'], 'trigger','imagen', 'fondo_asignado');
sca;
close all;

%Esto se tira una vez, si se para el experimento y hay que volver a empezar, no volvemos a
%ejecutar esto, porque nos generaria un nuevo conjunto de fondos diferentes
%asociados a las imagenes, y no podriamos luego unir correctamente los
%resultados


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BLOQUE PRINCIPAL: CONFIGURACIÓN DEL EXPERIMENTO CON PSYCHTOOLBOX %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Empezamos el test (si se nos para por algun motivo, volvemos a iniciar desde aqui)

rng('shuffle')

% Cargamos directorios de imagenes y fondos
directorio='.\imagenes_jpg_definitivo\';
cd(directorio)

path_images=genpath('.\imagenes_jpg_definitivo\');
addpath(path_images)

directorio_fondos = '.\fondos\';
path_fondos=genpath('.\fondos\');
addpath(path_fondos)

try

    % Introducimos los datos para cargar la lista
    run=input('Introduzca el run: ','s'); % El primer run es 01, si hay que volver a iniciar el experimento ponemos 02, 03... segun cuantas veces se nos pare
    trial=input('Introduzca el ensayo desde el que empezamos: ','s'); % empezamos en el 1, pero si se para en la i 38 (por ejemplo), cuando hagamos el run 02, aqui empezamos en 38

    % Nos carga el sujeto y su archivo para guardar resultados
    load(['.\respuestas\' subj '_' sname '_archivos_probe']);
    results_file=['.\respuestas\' subj '_' sname '_' run '_results_probe'];

    % Here we call some default settings for setting up Psychtoolbox
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
    %edfFile = [subj '_' sname]; % Save file name to a variable
    edfFile = [subj,'_rec'];

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
    Screen('Preference', 'SkipSyncTests', 1) % Se saltan las pruebas de sincronización (útil para pruebas rápidas)
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
    el.calImageTargetFilename = ['../fixTarget.jpg'];

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


    %% CARGAR INSTRUCCIONES
    instrucciones_imagen = imread('.\instrucciones_imagenes\recuperacion_tarea.jpg');
    [s1, s2, s3] = size(instrucciones_imagen);
    imageTexture = Screen('MakeTexture', window,instrucciones_imagen);
    Screen('DrawTexture', window, imageTexture, [], [], 0);
    Screen('Flip', window);
    KbStrokeWait;

    %%Empieza experimento
    for i=str2num(trial):length(probe)

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
        Eyelink('Command', 'record_status_message "TRIAL %d/%d"', i, length(imagen));

        %     if i==240 %la mitad de la tarea (480), cargamos una imagen de descanso que avisa que vamos por la mitad
        %             descanso_mitad=imread('.\instrucciones_imagenes\recuperacion_descanso.jpg');
        %             [s1, s2, s3] = size(descanso_mitad);
        %             imageTexture = Screen('MakeTexture', window, descanso_mitad);
        %             Screen('DrawTexture', window, imageTexture, [], [], 0);
        %             Screen('Flip', window);
        %             KbStrokeWait;
        %     end

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
        theImage = imread(fondo_asignado{i});
        [s1, s2, s3] = size(theImage);

        imageTexture = Screen('MakeTexture', window, theImage);
        Screen('DrawTexture', window, imageTexture, [], [0 0 1920 1080], 0);

        % --- MOSTRAR ITEM (estimulo) ---
        theImage = imread(cell2mat(imagen{i}));
        imgName = cell2mat(imagen{i});
        % Get the size of the image
        [s1, s2, s3] = size(theImage);

        %verifica q la imagen no sea demasiado grande para la pantalla.
        % See ImageRescaleDemo to see how to rescale an image.
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

        %Optional: draw feedback box and lines on Host PC interface instead of (or on top of) backdrop image.
        Eyelink('Command', 'draw_box %d %d %d %d 15', round(width/2-imgInfo.Width/2), round(height/2-imgInfo.Height/2), round(width/2+imgInfo.Width/2), round(height/2+imgInfo.Height/2));


        %STEP 5.2: START RECORDING

        % Put tracker in idle/offline mode before recording. Eyelink('SetOfflineMode') is recommended
        % however if Eyelink('Command', 'set_idle_mode') is used allow 50ms before recording as shown in the commented code:
        % Eyelink('Command', 'set_idle_mode');% Put tracker in idle/offline mode before recording
        % WaitSecs(0.05); % Allow some time for transition
        Eyelink('SetOfflineMode');% Put tracker in idle/offline mode before recording
        Eyelink('StartRecording'); % Start tracker recording
        WaitSecs(0.1); % Allow some time to record a few samples before presenting first stimulus

        % STEP 5.3: PRESENT STIMULUS; CREATE DATAVIEWER BACKDROP AND INTEREST AREA

        Screen('Flip', window);
        % Write message to EDF file to mark the start time of stimulus presentation.
        Eyelink('Message', 'STIM_ONSET');
        % Write !V IMGLOAD message to EDF file: provides instructions for DataViewer so it will show trial stimulus as backdrop
        % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Image Commands
        Eyelink('Message', '!V IMGLOAD CENTER %s %d %d', imgName, width/2, height/2);
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
                temp=temp(1);
                % Write message to EDF file to mark the spacebar press time
                Eyelink('Message', 'KEY_PRESSED');
                if strcmp(temp,'q')
                    Screen('CloseAll');
                    ShowCursor;
                    error('Program interrumpted.');
                    break;
                end
                break;
            end
        end

        %  %Presentar 'blanckscreen' con fix point
        % fixpTexture = Screen('MakeTexture', window, fixpMatrix);
        % [fixpHeight, fixpWidth, ~] = size(fixpMatrix);
        % dstRect = CenterRectOnPointd([0 0 fixpWidth fixpHeight], xCenter, yCenter);
        % disp(grey)
        % Screen('FillRect', window, grey);
        % Screen('DrawTexture', window, fixpTexture, [], dstRect);
        % Screen('Flip', window);
        %
        % % Write message to EDF file to mark time when blank screen is presented
        % Eyelink('Message', 'BLANK_SCREEN');
        % % Write !V CLEAR message to EDF file: creates blank backdrop for DataViewer
        % % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Simple Drawing
        Eyelink('Message', '!V CLEAR %d %d %d', el.backgroundcolour(1), el.backgroundcolour(2), el.backgroundcolour(3));

        % Stop recording eye movements at the end of each trial
        WaitSecs(0.1); % Add 100 msec of data to catch final events before stopping
        Eyelink('StopRecording'); % Stop tracker recording

        %Perform a drift check/correction.
        %Optionally provide x y target location, otherwise target is presented on screen centre
        EyelinkDoDriftCorrection(el, round(width/2), round(height/2));

        %WaitSecs(2); %cambiar a 2

        tic

        if i > 1
            resultados.tiempo_ensayo(i-1)=tiempo_total;
        end

        % Guardamos los resultados
        file_imagen{i}=imagen{i};
        results.res_key(i)=res_key;results.res_tr(i)=res_tr; results.trigger(i)=trigger(i);results.imagen(i)=imagen(i);results.fondo_asignado{i} = fondo_asignado{i};
        save(results_file, 'file_imagen','results')

        % STEP 5.5: CREATE VARIABLES FOR DATAVIEWER; END TRIAL

        % Write !V TRIAL_VAR messages to EDF file: creates trial variables in DataViewer
        % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Trial Message Commands
        Eyelink('Message', '!V TRIAL_VAR iteration %d', i); % Trial iteration
        Eyelink('Message', '!V TRIAL_VAR image %s', imgName); % Image name   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        WaitSecs(0.001); % Allow some time between messages. Some messages can be lost if too many are written at the same time

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

    cd('..\')
    % Transfer a copy of the EDF file to Display PC
    transferFile(edfFile, el, dummymode, window, height); % See transferFile function below


    %% Cargamos imagen de despedida
    despedida_imagen=imread('.\instrucciones_imagenes\despedida_imagen.jpg');
    [s1, s2, s3] = size(despedida_imagen);
    imageTexture = Screen('MakeTexture', window, despedida_imagen);
    Screen('DrawTexture', window, imageTexture, [], [], 0);
    Screen('Flip', window);
    KbStrokeWait;

    sca
    % delete(s)
    % clear s
catch
    % Print error message and line number in Matlab's Command Window
    psychrethrow(psychlasterror);
    % ListenChar(0);
    sca;
end

cleanup;