%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANÁLISIS DATOS EYELINK %
%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

% La función edfmex() (descargada de https://www.sr-research.com/support/thread-54.html)
% permite abrir un archivo EDF en Matlab, generando una estructura de datos

addpath(''); %% INTRODUCIR RUTA!!
savepath;

% la estructura edfStruct_cod contiene 6 variables:
% FSAMPLE: datos de cada muestreo (filas 1 es ojo izdo y filas 2 ojo dcho)
    % time !!
    % pa (tamañao pupila)
    % gx (X Gaze position) !!
    % gy !!
    % rx (pixels per degree x)
    % ry
    % gxvel (gaze velocity x, value in degree of visual angle per sec) !!
    % gyvel !!
    % etc.

% FEVENT: datos de cada evento
    % time
    % type
        % STARTBLINK = 3 // pupil disappeared, time only
        % ENDBLINK = 4 // pupil reappeared, duration data
        % STARTSACC = 5 // start of saccade, time only
        % ENDSACC = 6 // end of saccade, summary data
        % STARTFIX = 7 // start of fixation, time only
        % ENDFIX = 8 // end of fixation, summary data
        % FIXUPDATE = 9 // update within fixation, summary data for interval
        % STARTEVENTS = 17 (inicio del trial)!!
        % ENDEVENTS = 18 (fin del trial)!!
        % MESSAGEEVENT = 24 // user-definable text: IMESSAGE structure
        % BUTTONEVENT = 25 // button state change: IOEVENT structure
        % INPUTEVENT = 28 // change of input port: IOEVENT structure
        % LOST_DATA_EVENT = 0x3F // NEW: Event flags gap in data stream
    
    % read (flags which items were included)
    % sttime (comienzo del evento)
    % entime (fin del evento)
    % gstx (gaze starting point x)
    % gsty
    % genx (gaze ending point x)
    % geny
    % gavx (gaze averages x)
    % gavy
    % averl (accumulated average velocity)
    % pvel (accumulated peak velocity)
    % message (any string)
    % condestring (type of event)

% IOEVENT (button input or other simple events)

% RECORDINGS: holds information about a recording block in an EDF file.
% A RECORDINGS structure is present at the start of recording and the
% end of recording. Conceptually a RECORDINGS structure is similar to
% the START and END lines inserted in an EyeLink ASC file.
    % time
    % sample_rate
    % eflags
    % sflags
    % state: 1 (start of a recording block); 0 (end of a recording block)

% HEADER
% FILENAME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Sujetos a incluir y resolución de pantalla
todos = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 18]; % Lista de sujetos
h_res = 1919;                  % Resolución horizontal
v_res = 1079;                  % Resolución vertical

dataFolder_cod = '.\Data Cod';
dataFolder_rec = '.\Data Rec';

% Contador global de ensayos para codificación
trialIdx_cod = 1;
trialIdx_rec = 1;

for subj = 1:length(todos)
    s = todos(subj);  % Número de sujeto actual
    
    %%%%%%%%%%%%%%%%%%
    %% CODIFICACIÓN %%
    %%%%%%%%%%%%%%%%%%
    cod_folder = '.\listas\';
    cod_pattern = fullfile(cod_folder, [sprintf('%02d', s) '_*lista.mat']);
    lista_file = dir(cod_pattern);
    if isempty(lista_file)
        error('No se encontró lista para el sujeto %02d', s);
    end
    load(fullfile(cod_folder, lista_file.name), 'lista_def', 'lista_def_orden');

    % Cargar EDF
    filenameEdf_cod = sprintf('%02d_cod.edf', s);
    edfStruct_cod = edfmex(filenameEdf_cod);
        % Detectar canal de ojo válido por variabilidad en tamaño pupilar
        pupL = edfStruct_cod.FSAMPLE.pa(1, :);
        pupR = edfStruct_cod.FSAMPLE.pa(2, :);
        % El canal con mayor desviación típica indica el ojo grabado pq el
        % ojo q no se graba tiene siempre el mismo tamaño pupilar
        if std(pupL) >= std(pupR)
            eyeIdx = 1;  % ojo izquierdo
        else
            eyeIdx = 2;  % ojo derecho
        end

    % Filtrar y limpiar eventos
    filtEvents = edfStruct_cod.FEVENT([edfStruct_cod.FEVENT.type] ~= 24);
    keepFields = {'type','sttime','entime','gstx','gsty','genx','geny','codestring'};
    cleanedEvents = rmfield(filtEvents, setdiff(fieldnames(filtEvents), keepFields));
    for j = 1:length(cleanedEvents)
        cleanedEvents(j).duration = cleanedEvents(j).entime - cleanedEvents(j).sttime;
    end

    % Tiempos de grabación y eventos de inicio/fin trial
    rec_times = [edfStruct_cod.RECORDINGS.time];
    allTypes = [cleanedEvents.type];
    trialEvents = find(ismember(allTypes, [17,18]));

    % Preprocesado: juntar genx/geny/duration de todos los eventos
    prepro.gx = [cleanedEvents.genx];
    prepro.gy = [cleanedEvents.geny];
    prepro.duration = [cleanedEvents.duration];
    type8Idx = [cleanedEvents.type] == 8;

    % Reiniciar estructuras por sujeto
    clear fixData_cod;
    contFix = 1;
    nTrials_cod = length(edfStruct_cod.RECORDINGS)/2;

    for i = 1:nTrials_cod
        rec_idx = (i-1)*2 + 1;
        start_t = rec_times(rec_idx);
        end_t = rec_times(rec_idx + 1);

        % Extraer nombre de ítem y categoría
        nombre_item = cell2mat(lista_def{1, i});
        [~, name, ~] = fileparts(nombre_item);
        category = regexp(name, '[a-zA-Z]+', 'match', 'once');

        % Nombre de fondo y condición
        nombre_fondo = cell2mat(lista_def(2, i));
        % Cargar imágenes para visualización
        img_cuadro = imread(['.\imagenes_jpg_definitivo\', category, '\', nombre_item]);
        img_fondo = imread(['.\fondos\', nombre_fondo]);
        cond = lista_def_orden(i, 1);

        % EXTRAER FIJACIONES PREPROCESADAS
        idxStart = trialEvents(rec_idx);
        idxEnd = trialEvents(rec_idx + 1);

        trial.gx = prepro.gx(idxStart:idxEnd);
        trial.gy = prepro.gy(idxStart:idxEnd);
        trial.duration = prepro.duration(idxStart:idxEnd);
        validFix = type8Idx(idxStart:idxEnd);
        trial.gx = trial.gx(validFix);
        trial.gy = trial.gy(validFix);
        trial.duration = trial.duration(validFix);

        % Filtrar fuera de pantalla
        inB = trial.gx >= 0.001 & trial.gx <= h_res & trial.gy >= 0.001 & trial.gy <= v_res;
        trial.gx = trial.gx(inB);
        trial.gy = trial.gy(inB);
        trial.duration = trial.duration(inB);

        % Definir AOI
        x0 = 710; y0 = 290;
        square_size = min(1210 - 710, 790 - 290);

        %%%%%%%%%%%%%%%%%%%%%%%
        % Extracción de datos %
        %%%%%%%%%%%%%%%%%%%%%%%
        % Índices para fixData_cod
        N = length(trial.gx);
        startFix = contFix;
        endFix = startFix + N - 1;

        % POBLAR fixData_cod
        for k = 1:N
            idx = startFix + k - 1;
            fixData_cod(idx).trial = i;
            fixData_cod(idx).item = nombre_item;
            fixData_cod(idx).fondo = nombre_fondo;
            fixData_cod(idx).categ = category;
            fixData_cod(idx).gx = trial.gx(k);
            fixData_cod(idx).gy = trial.gy(k);
            fixData_cod(idx).duration = trial.duration(k);
            fixData_cod(idx).isInArea = trial.gx(k) >= x0 & trial.gx(k) <= x0+square_size & ...
                                        trial.gy(k) >= y0 & trial.gy(k) <= y0+square_size;
            fixData_cod(idx).cond = cond;
        end

        % EXTRAER MÉTRICAS PARA finalMatrix_cod
        inArea = [fixData_cod(startFix:endFix).isInArea];
        durations = [fixData_cod(startFix:endFix).duration];

        finalMatrix_cod(trialIdx_cod).fase = 'cod';
        finalMatrix_cod(trialIdx_cod).suj = sprintf('%02d', s);
        finalMatrix_cod(trialIdx_cod).trial = i;
        finalMatrix_cod(trialIdx_cod).item = nombre_item;
        finalMatrix_cod(trialIdx_cod).categ = category;
        finalMatrix_cod(trialIdx_cod).fondo = nombre_fondo;
        finalMatrix_cod(trialIdx_cod).condTag = cond;
        finalMatrix_cod(trialIdx_cod).stimType = NaN;

        if cond >= 10
            finalMatrix_cod(trialIdx_cod).condicion = 'DF';
        else
            finalMatrix_cod(trialIdx_cod).condicion = 'MF';
        end

        finalMatrix_cod(trialIdx_cod).totalFix = N;
        finalMatrix_cod(trialIdx_cod).itemFix = sum(inArea);
        finalMatrix_cod(trialIdx_cod).fondoFix = N - sum(inArea);
        finalMatrix_cod(trialIdx_cod).durMedia = mean(durations);
        finalMatrix_cod(trialIdx_cod).tr = NaN;
        finalMatrix_cod(trialIdx_cod).respRaw = NaN;
        finalMatrix_cod(trialIdx_cod).respTag = NaN;
        finalMatrix_cod(trialIdx_cod).resp = NaN;


        % Actualizar contadores
        contFix = endFix + 1;
        trialIdx_cod = trialIdx_cod + 1;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % VISUALIZACIÓN (opcional) %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        vis = 0;
        if vis == 1
            % DATOS BRUTOS para plot
            start_idx = find(edfStruct_cod.FSAMPLE.time >= start_t, 1);
            end_idx = find(edfStruct_cod.FSAMPLE.time >= end_t, 1);
            gx_raw = edfStruct_cod.FSAMPLE.gx(eyeIdx, start_idx:end_idx);
            gy_raw = edfStruct_cod.FSAMPLE.gy(eyeIdx, start_idx:end_idx);
            in_b = gx_raw>=0.001 & gx_raw<=h_res & gy_raw>=0.001 & gy_raw<=v_res;
            gx_plot = gx_raw(in_b);
            gy_plot = gy_raw(in_b);

            % Figura
            figure;
            imagesc([0 h_res], [0 v_res], img_fondo);
            set(gca, 'YDir', 'reverse'); axis off; hold on;
            imagesc([x0 x0+square_size], [y0 y0+square_size], img_cuadro);
            rectangle('Position', [x0, y0, square_size, square_size], 'EdgeColor', 'r', 'LineWidth', 2);
            plot(gx_plot, gy_plot, 'r-');

            %5. Datos PREPROCESADOS de mirada con tamaño proporcional logarítmico a la duración
            trial.duration = double(trial.duration); % Asegura que es tipo double
            logDur = log(trial.duration);       % escala logarítmica
            logDur = logDur - min(logDur) + 1; % asegurar que todos sean positivos
            markerSizes = logDur / max(logDur) * 200; % escalar al tamaño deseado (ajusta 200 si hace falta)
            scatter(trial.gx, trial.gy, markerSizes, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', 'none');

            xlim([0 h_res]); ylim([0 v_res]); axis equal; hold off;
        end
    end

    % Guardar datos de fijaciones para codificación
    save(fullfile(dataFolder_cod, sprintf('cod_fixData_%02d.mat', s)), 'fixData_cod');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%
    %% RECUPERACIÓN %%
    %%%%%%%%%%%%%%%%%%
    rec_folder = '.\respuestas\';
    rec_pattern = fullfile(rec_folder, [sprintf('%02d', s), '*_results_probe.mat']);
    lista_file = dir(rec_pattern);
    if isempty(lista_file)
        error('No se encontró lista para el sujeto %02d', s);
    end
    rec_fileName= [rec_folder, dir(rec_pattern).name];
    load(rec_fileName);

    % Cargar EDF
    filenameEdf_rec = sprintf('%02d_rec.edf', s);
    edfStruct_rec = edfmex(filenameEdf_rec);
        % Detectar canal de ojo válido por variabilidad en tamaño pupilar
        pupL = edfStruct_rec.FSAMPLE.pa(1, :);
        pupR = edfStruct_rec.FSAMPLE.pa(2, :);
        % El canal con mayor desviación típica indica el ojo grabado pq el
        % ojo q no se graba tiene siempre el mismo tamaño pupilar
        if std(pupL) >= std(pupR)
            eyeIdx = 1;  % ojo izquierdo
        else
            eyeIdx = 2;  % ojo derecho
        end

    % Filtrar y limpiar eventos
    filtEvents = edfStruct_rec.FEVENT([edfStruct_rec.FEVENT.type] ~= 24);
    keepFields = {'type','sttime','entime','gstx','gsty','genx','geny','codestring'};
    cleanedEvents = rmfield(filtEvents, setdiff(fieldnames(filtEvents), keepFields));
    for j = 1:length(cleanedEvents)
        cleanedEvents(j).duration = cleanedEvents(j).entime - cleanedEvents(j).sttime;
    end

    % Tiempos de grabación y eventos de inicio/fin trial
    rec_times = [edfStruct_rec.RECORDINGS.time];
    allTypes = [cleanedEvents.type];
    trialEvents = find(ismember(allTypes, [17,18]));

    % Preprocesado: juntar genx/geny/duration de todos los eventos
    prepro.gx = [cleanedEvents.genx];
    prepro.gy = [cleanedEvents.geny];
    prepro.duration = [cleanedEvents.duration];
    type8Idx = [cleanedEvents.type] == 8;

    % Reiniciar estructuras por sujeto
    clear fixData_rec;
    contFix_rec = 1;
    nTrials_rec = length(edfStruct_rec.RECORDINGS)/2;

    for i = 1:nTrials_rec
        rec_idx = (i-1)*2 + 1;
        start_t = rec_times(rec_idx);
        end_t = rec_times(rec_idx + 1);

        % Extraer la imagen del ensayo
        nombre_item = cell2mat(results.imagen{1, i});

        % Eliminar la extensión
        [~, name, ~] = fileparts(nombre_item);  % name = 'bank1'

        % Extraer Nombre de la categoría
        category = regexp(name, '[a-zA-Z_]+', 'match');
        category = category{1};
        category = regexp(category, '[a-zA-Z]+', 'match');
        category = strjoin(category, ''); % Une los elementos sin espacio

        img_cuadro = imread(['.\imagenes_jpg_definitivo\', category, '\' nombre_item]);

        % Extraer el fondo del ensayo
        nombre_fondo = cell2mat(results.fondo_asignado(1, i));
        img_fondo = imread(['.\fondos\', nombre_fondo]);
        cond = results.trigger(1, i);

        % Extraer respuesta del ensayo
        if results.res_key(1,i) == 49
            resp = 1;
        elseif results.res_key(i) == 50
            resp = 2;
        elseif results.res_key(i) == 51
            resp = 3;
        elseif results.res_key(i) == 0
            resp = NaN;
        else
            resp = 'error';
        end

        % EXTRAER FIJACIONES PREPROCESADAS
        idxStart = trialEvents(rec_idx);
        idxEnd = trialEvents(rec_idx + 1);

        trial.gx = prepro.gx(idxStart:idxEnd);
        trial.gy = prepro.gy(idxStart:idxEnd);
        trial.duration = prepro.duration(idxStart:idxEnd);
        validFix = type8Idx(idxStart:idxEnd);
        trial.gx = trial.gx(validFix);
        trial.gy = trial.gy(validFix);
        trial.duration = trial.duration(validFix);

        % Filtrar fuera de pantalla
        inB = trial.gx >= 0.001 & trial.gx <= h_res & trial.gy >= 0.001 & trial.gy <= v_res;
        trial.gx = trial.gx(inB);
        trial.gy = trial.gy(inB);
        trial.duration = trial.duration(inB);

        % Definir AOI
        x0 = 710; y0 = 290;
        square_size = min(1210 - 710, 790 - 290);

        %%%%%%%%%%%%%%%%%%%%%%%
        % Extracción de datos %
        %%%%%%%%%%%%%%%%%%%%%%%
        % Índices para fixData_rec
        N  = length(trial.gx);
        startFix = contFix_rec;
        endFix = startFix + N - 1;

        % POBLAR fixData_rec
        for k = 1:N
            idx = startFix + k - 1;
            fixData_rec(idx).trial = i;
            fixData_rec(idx).item = nombre_item;
            fixData_rec(idx).fondo = nombre_fondo;
            fixData_rec(idx).categ = category;
            fixData_rec(idx).gx = trial.gx(k);
            fixData_rec(idx).gy = trial.gy(k);
            fixData_rec(idx).duration = trial.duration(k);
            fixData_rec(idx).isInArea = trial.gx(k) >= x0 & trial.gx(k) <= x0+square_size & ...
                                        trial.gy(k) >= y0 & trial.gy(k) <= y0+square_size;
            fixData_rec(idx).cond = cond;
            fixData_rec(idx).respuesta = resp;
            fixData_rec(idx).tr = results.res_tr(1, i);
        end

        % EXTRAER MÉTRICAS PARA finalMatrix_rec
        inArea = [fixData_rec(startFix:endFix).isInArea];
        durations = [fixData_rec(startFix:endFix).duration];

        finalMatrix_rec(trialIdx_rec).fase = 'rec';
        finalMatrix_rec(trialIdx_rec).suj = sprintf('%02d', s);
        finalMatrix_rec(trialIdx_rec).trial = i;
        finalMatrix_rec(trialIdx_rec).item = nombre_item;
        finalMatrix_rec(trialIdx_rec).categ = category;
        finalMatrix_rec(trialIdx_rec).fondo = nombre_fondo;
        finalMatrix_rec(trialIdx_rec).condTag = cond;

        if cond == 10
            finalMatrix_rec(trialIdx_rec).stimType = 'target';
            finalMatrix_rec(trialIdx_rec).condicion = 'MF';
        elseif cond == 20
            finalMatrix_rec(trialIdx_rec).stimType = 'target';
            finalMatrix_rec(trialIdx_rec).condicion = 'DF';
        elseif cond == 15
            finalMatrix_rec(trialIdx_rec).stimType = 'lure';
            finalMatrix_rec(trialIdx_rec).condicion = 'MF';
        elseif cond == 25
            finalMatrix_rec(trialIdx_rec).stimType = 'lure';
            finalMatrix_rec(trialIdx_rec).condicion = 'DF';
        elseif cond == 30
            finalMatrix_rec(trialIdx_rec).stimType = 'foil';
            finalMatrix_rec(trialIdx_rec).condicion = NaN;
        end

        finalMatrix_rec(trialIdx_rec).totalFix = N;
        finalMatrix_rec(trialIdx_rec).itemFix = sum(inArea);
        finalMatrix_rec(trialIdx_rec).fondoFix = N - sum(inArea);
        finalMatrix_rec(trialIdx_rec).durMedia = mean(durations);
        finalMatrix_rec(trialIdx_rec).tr = results.res_tr(1, i);
        finalMatrix_rec(trialIdx_rec).respRaw = resp;
        
        if isnan(resp)
                finalMatrix_rec(trialIdx_rec).respTag = NaN;
                finalMatrix_rec(trialIdx_rec).resp = NaN;
        elseif ismember(cond, [10, 20]) % target (old)
            if resp == 1
                finalMatrix_rec(trialIdx_rec).respTag = 1;
                finalMatrix_rec(trialIdx_rec).resp = 'hit';
            elseif resp == 2
                finalMatrix_rec(trialIdx_rec).respTag = 5; % similar response to target
                finalMatrix_rec(trialIdx_rec).resp = 'Sr2T';
            elseif resp == 3
                finalMatrix_rec(trialIdx_rec).respTag = 6; % new response to target
                finalMatrix_rec(trialIdx_rec).resp = 'Nr2T';
            end
        elseif ismember(cond, [15, 25]) % lure
            if resp == 2
                finalMatrix_rec(trialIdx_rec).respTag = 2; % lure correct rejection
                finalMatrix_rec(trialIdx_rec).resp = 'LCR';
            elseif resp == 1
                finalMatrix_rec(trialIdx_rec).respTag = 3; % lure false alarm (target)
                finalMatrix_rec(trialIdx_rec).resp = 'LFA';
            elseif resp == 3 
                finalMatrix_rec(trialIdx_rec).respTag = 7; % new response to lure
                finalMatrix_rec(trialIdx_rec).resp = 'Nr2L';
            end
        elseif cond == 30
            if resp == 3
                finalMatrix_rec(trialIdx_rec).respTag = 4; % foil correct rejection
                finalMatrix_rec(trialIdx_rec).resp = 'FCR';
            elseif resp == 1
                finalMatrix_rec(trialIdx_rec).respTag = 8; % old response to foil
                finalMatrix_rec(trialIdx_rec).resp = 'Or2F';
            elseif resp == 2 
                finalMatrix_rec(trialIdx_rec).respTag = 9; % similar response to foil
                finalMatrix_rec(trialIdx_rec).resp = 'Sr2F';
            end
        end

        % Actualizar contadores
        contFix_rec = endFix + 1;
        trialIdx_rec = trialIdx_rec + 1;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % VISUALIZACIÓN (opcional) %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        vis = 0;
        if vis == 1
            % DATOS BRUTOS para plot
            start_idx = find(edfStruct_rec.FSAMPLE.time >= start_t, 1);
            end_idx = find(edfStruct_rec.FSAMPLE.time >= end_t, 1);
            gx_raw = edfStruct_rec.FSAMPLE.gx(eyeIdx, start_idx:end_idx);
            gy_raw = edfStruct_rec.FSAMPLE.gy(eyeIdx, start_idx:end_idx);
            in_b = gx_raw>=0.001 & gx_raw<=h_res & gy_raw>=0.001 & gy_raw<=v_res;
            gx_plot = gx_raw(in_b);
            gy_plot = gy_raw(in_b);

            % Figura
            figure;
            imagesc([0 h_res], [0 v_res], img_fondo);
            set(gca, 'YDir', 'reverse'); axis off; hold on;
            imagesc([x0 x0+square_size], [y0 y0+square_size], img_cuadro);
            rectangle('Position', [x0, y0, square_size, square_size], 'EdgeColor', 'r', 'LineWidth', 2);
            plot(gx_plot, gy_plot, 'r-');

            %5. Datos PREPROCESADOS de mirada con tamaño proporcional logarítmico a la duración
            trial.duration = double(trial.duration); % Asegura que es tipo double
            logDur = log(trial.duration);       % escala logarítmica
            logDur = logDur - min(logDur) + 1; % asegurar que todos sean positivos
            markerSizes = logDur / max(logDur) * 200; % escalar al tamaño deseado (ajusta 200 si hace falta)
            scatter(trial.gx, trial.gy, markerSizes, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', 'none');

            xlim([0 h_res]); ylim([0 v_res]); axis equal; hold off;
        end
    end

    % Guardar datos de fijaciones para recificación
    save(fullfile(dataFolder_rec, sprintf('rec_fixData_%02d.mat', s)), 'fixData_rec');



end
save(fullfile(dataFolder_cod, sprintf('cod_finalMatrix_%02d.mat', s)), 'finalMatrix_cod');
save(fullfile(dataFolder_rec, sprintf('rec_finalMatrix_%02d.mat', s)), 'finalMatrix_rec');