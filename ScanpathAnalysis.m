addpath('.\MultiMatch-master');
savepath;

todos = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16]; % Lista de sujetos
dataFolder_cod = '.\Data Cod';
dataFolder_rec = '.\Data Rec';
dataFolder_SP = '.\Data Scanpath';

vectSim = {};  
dirSim  = {};  
lenSim  = {};  
posSim  = {};  
durSim  = {};

matrixIdx = 1;

for subj = 1:length(todos)
    s = todos(subj);  % Número de sujeto actual

    load(fullfile(dataFolder_cod, ['cod_fixData_',sprintf('%02d', s), '.mat']));
    load(fullfile(dataFolder_rec, ['rec_fixData_',sprintf('%02d', s), '.mat']));
    
    % Eliminamos los foils (news) pq no hay codif con q compararlos !!
    fixData_rec = fixData_rec([fixData_rec.cond] ~= 30);

    C = {fixData_rec.categ};    % C es ahora un 1×N cell-array de char vectors
    categories = unique(C, 'stable');

    for cat = 1:length(categories)
        
        % → codTrials es un 1×M cell con los M ensayos de 'cat'
        % → codIDs(k) indica el valor de .trial para codTrials{k}
        [recTrials, recIDs] = splitFixByCategory(fixData_rec, categories(cat));   
        recTrial = recTrials{1, 1};

        % Mantener solo los campos deseados
        keepFields = {'gx', 'gy', 'duration'};
        recTrial = rmfield(recTrial, setdiff(fieldnames(recTrial), keepFields));

        % Convertir las estructuras a matrices nx3 para codTrial
        recTrialArray = [vertcat(recTrial.gx), vertcat(recTrial.gy), vertcat(recTrial.duration)];

        % Ahora para la codificación
        [codTrials, codIDs] = splitFixByCategory(fixData_cod, categories(cat));
        
        % Extraer los ensayos
            % Primero contrastar con lista_def para que no colapse en caso
            % de que haya ensayos perdidos
            lista_folder = '.\listas\';
            listaPattern = fullfile(lista_folder, [sprintf('%02d', s) '_*lista.mat']);
            lista_file = dir(listaPattern);
            load(fullfile(lista_folder, lista_file.name), 'lista_def');
            
            items = lista_def(1,:);
            items = [items{:}];          % Convierte de cell de cells a cell de chars/strings
            items = string(items);       % Convierte a string array (ya no es cell)
            catName = categories{cat};

            % patrón: ^categoría + dígitos + .jpg$
            pattern = "^" + catName + "\d+\.jpg$";
            
            % regexpi ignora diferencias de caso, así casa .jpg, .JPG, .Jpg, etc.
            matches = regexpi(items, pattern, 'match', 'once');  
            
            % máscara lógica de los que sí coinciden exactamente
            mask = ~cellfun(@isempty, matches);
            
            % esos índices en lista_def son tus trial numbers
            trialNums = find(mask);                % p.ej. [2 5 10]

            if numel(trialNums) ~= 3 % Avisar de cuando pase esto
                error('Sujeto %02d, categoría %s: Solo hay %d ensayos válidos en codificación.', ...
                    s, categories{cat}, numel(trialNums));
            end
            
        keepFields = {'gx','gy','duration'};
        % PREASIGNACIÓN de la matriz de resultados:
        %   - 3 filas: una por cada uno de los 3 trials "definidos" según lista_def
        %   - 5 columnas: las 5 métricas que devuelve doComparison
        r_cod = nan(3, 5);

        for k = 1:3
            tn = trialNums(k);
            idx = find(codIDs == tn, 1);
            if ~isempty(idx)
                ct = codTrials{1, idx};
                ct = rmfield(ct, setdiff(fieldnames(ct), keepFields));
                arr = [vertcat(ct.gx), vertcat(ct.gy), vertcat(ct.duration)];

                % **Nuevo chequeo**: al menos dos fijaciones en ambos scanpaths
                if size(recTrialArray,1) < 2 || size(arr,1) < 2
                    r_cod(k,:) = nan(1,5);  % insuficientes fijaciones → NaNs
                else
                    r_cod(k,:) = doComparison(recTrialArray, arr); % COMPARACIÓN DE SCANPATHS A PARES
                end
            else
                r_cod(k,:) = nan(1,5);
            end
        end
    
    % Desempaquetamos
    r_cod1 = r_cod(1, :);
    r_cod2 = r_cod(2, :);
    r_cod3 = r_cod(3, :);

        % Añadir código de respuesta (solo está en finalMatrix_rec)
        load(".\Data Rec\rec_finalMatrix_16.mat");
            trialNum = recIDs(1);
            % máscaras para cada campo
            mask_s = strcmp({finalMatrix_rec.suj}, sprintf('%02d', s));
            mask_cat = strcmp({finalMatrix_rec.categ}, categories{cat});
            mask_tr = [finalMatrix_rec.trial] == trialNum;
            
            % máscara combinada
            mask = mask_s & mask_cat & mask_tr;
            
            % extraer respTag y condicion
            respTag_val = finalMatrix_rec(mask).respTag; %código de respuesta (hit, LCR, LFA...)
            cond_val = finalMatrix_rec(mask).condicion; % condición (MF/DF)

            category =categories{cat};

        % Almacenar los resultados de comparación en una matriz
        vectSim(matrixIdx, :) = {s, category, cond_val, respTag_val, r_cod1(1), r_cod2(1), r_cod3(1)};
        dirSim(matrixIdx, :) = {s, category, cond_val, respTag_val, r_cod1(2), r_cod2(2), r_cod3(2)};
        lenSim(matrixIdx, :) = {s, category, cond_val, respTag_val, r_cod1(3), r_cod2(3), r_cod3(3)};
        posSim(matrixIdx, :) = {s, category, cond_val, respTag_val, r_cod1(4), r_cod2(4), r_cod3(4)};
        durSim(matrixIdx, :) = {s, category, cond_val, respTag_val, r_cod1(5), r_cod2(5), r_cod3(5)};
        matrixIdx = matrixIdx + 1;
    end
end

% Guarda cada matriz en su propio .mat
save(fullfile(dataFolder_SP, 'vectorSimilarity.mat'), 'vectSim');
save(fullfile(dataFolder_SP, 'directionSimilarity.mat'), 'dirSim');
save(fullfile(dataFolder_SP, 'lengthSimilarity.mat'), 'lenSim');
save(fullfile(dataFolder_SP, 'positionSimilarity.mat'), 'posSim');
save(fullfile(dataFolder_SP, 'durationSimilarity.mat'), 'durSim');

