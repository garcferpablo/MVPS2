function [figure2, table2, sigComparisons2] = uncorrectedTotalFix(S)
% uncorrectedTotalFix crea una figura representando el número medio de fijaciones total
% en cada fase (recuperación y 3 codificaciones) según la categoría de respuesta,
% y devuelve una tabla con esas medias por sujeto y tipo de respuesta.
%
% Entradas:
%   - S: struct array con campos
%        .suj       (string o char)
%        .categ     (string o char)
%        .condTag   (numeric; 30 = "Novel CR", 1=Enc1,2=Enc2,3=Enc3)
%        .respTag   (1=Hit,2=LCR,3=LFA)
%        .totalFix  (numeric)
%
% Salidas:
%   - figure1: handle de la figura
%   - table1 : tabla con columnas
%       Subject, RespTag, MeanRec, meanCod1, meanCod2, meanCod3

    %% 1) Carga de datos de codificación
    load('.\Data Cod\cod_finalMatrix_18.mat');
    C = finalMatrix_cod;

    %% 2) Extraer variables de S
    nT = numel(S);
    Subject = cell(nT,1);
    RespTag = nan(nT,1);
    Condition = nan(nT,1);
    Category = cell(nT,1);
    RecFix = nan(nT,1);
    % Ahora necesitamos 3 columnas de codificación
    CodFix = nan(nT,3);

    for i = 1:nT
        Subject{i} = S(i).suj;
        RespTag(i) = S(i).respTag;
        Condition(i) = S(i).condTag;
        Category{i} = S(i).categ;
        RecFix(i) = S(i).totalFix;
        if S(i).condTag ~= 30
            % Seleccionar sólo las tres fases de codificación para el mismo sujeto y categoría
            sujVec = {C.suj}';
            categVec = {C.categ}';
            %condVec = [C.condTag]';
            mask = strcmp(sujVec, S(i).suj) & strcmp(categVec, S(i).categ);

            E = C(mask);
            if numel(E) >= 3
                CodFix(i,1:3) = [E(1).totalFix, E(2).totalFix, E(3).totalFix];
            else
                CodFix(i,:) = NaN;
                warning('Menos de 3 codificaciones para %s/%s', S(i).suj, S(i).categ);
            end
        end
    end

    %% 3) Montar tabla larga
    tbl = table(...
      categorical(Subject), Category, RespTag, Condition, RecFix, CodFix(:,1), CodFix(:,2), CodFix(:,3), ...
      'VariableNames',{'Subject','Category','RespTag','Condition','RecFix','CodFix1','CodFix2','CodFix3'});

    %% 4) Medias por sujeto × respuesta
    subjs = unique(tbl.Subject);
    resps = unique(tbl.RespTag); resps = resps(~isnan(resps));
    nS = numel(subjs);
    nR = numel(resps);
    meanRec  = nan(nS,nR); % matriz (suj x categoría de respuesta)
    meanCod1 = nan(nS,nR);
    meanCod2 = nan(nS,nR);
    meanCod3 = nan(nS,nR);
    for i = 1:nS
        for j = 1:nR
            sel = tbl.Subject==subjs(i) & tbl.RespTag==resps(j);
            meanRec(i,j)  = mean(tbl.RecFix(sel),'omitnan');
            meanCod1(i,j) = mean(tbl.CodFix1(sel),'omitnan');
            meanCod2(i,j) = mean(tbl.CodFix2(sel),'omitnan');
            meanCod3(i,j) = mean(tbl.CodFix3(sel),'omitnan');
        end
    end

    %% 5) Tabla de salida
    [SS,RR] = ndgrid(subjs,resps);
    table1 = table(SS(:), RR(:), ...
                   meanRec(:), meanCod1(:), meanCod2(:), meanCod3(:), ...
                   'VariableNames',{'Subject','RespTag','MeanRec','meanCod1','meanCod2','meanCod3'});

    %% 6) Medias generales y SEM
    grandMeanRec  = mean(meanRec,1,'omitnan');
    grandmeanCod1 = mean(meanCod1,1,'omitnan');
    grandmeanCod2 = mean(meanCod2,1,'omitnan');
    grandmeanCod3 = mean(meanCod3,1,'omitnan');

    semRec  = std(meanRec,0,1,'omitnan')  ./ sqrt(nS);
    semEnc1 = std(meanCod1,0,1,'omitnan') ./ sqrt(nS);
    semEnc2 = std(meanCod2,0,1,'omitnan') ./ sqrt(nS);
    semEnc3 = std(meanCod3,0,1,'omitnan') ./ sqrt(nS);

    %% 7) Matrices para bar grouped
    % filas = fases (1=NovelCR, 2=Enc1,3=Enc2,4=Enc3) × columnas = respuestas (Hit,LCR,LFA)
    Y = [grandMeanRec; grandmeanCod1; grandmeanCod2; grandmeanCod3];
    E = [semRec; semEnc1; semEnc2; semEnc3];

    phaseLabels = {'Rec','Cod 1','Cod 2','Cod 3'};
    responseLabels = {'Hit','LCR','LFA', 'FCR', 'Sr2T', 'Nr2T', 'Nr2L', 'FFA', 'Sr2F'};

    %% 8) Plot - barras agrupadas con SEM
    figure1 = figure('Position',[100 100 900 500]);
    set( figure1, ...
        'DefaultAxesFontName','Times New Roman', ...
        'DefaultTextFontName','Times New Roman' );
    hb = bar(Y,'grouped');
    hold on

    [ngroups, nbars] = size(Y);
    groupwidth = min(0.8, nbars/(nbars+1.5));

    baseColors = [...
    rgb('lime');         % 1 Hit
    rgb('blue');        % 2 LCR
    rgb('red');   % 3 LFA
    rgb('sandyBrown');  % 4 FCR
    rgb('yellow');       % 5 Sr2T
    rgb('orange');       % 6 Nr2T
    rgb('gold');         % 7 Nr2L
    rgb('rosyBrown');    % 8 FFA
    rgb('khaki')];       % 9 Sr2F

    % Aplicar colores a cada barra
    for k = 1:numel(hb)
        hb(k).FaceColor = 'flat';
        hb(k).CData = repmat(baseColors(k,:), size(Y,1), 1);
        hb(k).FaceAlpha = 0.5;
    end

    %lineas de error
    for k = 1:nbars
        x = (1:ngroups) - groupwidth/2 + (2*k-1)*groupwidth/(2*nbars);
        errorbar(x, Y(:,k), E(:,k), 'k', 'LineStyle','none','LineWidth',1);
    end

    set(gca, 'XTick',1:ngroups, 'XTickLabel',phaseLabels, 'FontSize',12);
    xlabel('Fase','FontWeight','bold');
    ylabel('Mean Fixation Count','FontWeight','bold');
    legend(hb, responseLabels, 'Location','NorthWest');
    %title('Todas las categorías de respuesta','FontSize',14);
    ylim([0, max(Y(:)+E(:))*1.2]);
    hold off

    % Lo mismo solo para hits, LCR y LFA
    Y2 = [grandMeanRec(1:3); grandmeanCod1(1:3); grandmeanCod2(1:3); grandmeanCod3(1:3)];
    E2 = [semRec(1:3); semEnc1(1:3); semEnc2(1:3); semEnc3(1:3)];

    phaseLabels2   = {'Rec','Cod 1','Cod 2','Cod 3'};
    responseLabels2 = {'Hit','LCR','LFA'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% 8) ANOVA reproducible para Figura 2 (solo Hit, LCR, LFA)
    % ANOVA 4 x 3 (ensayo o fase x respuesta)
    % 8.1) Limpiar etiquetas y generar nombres wide
    % — quitar espacios y caracteres no válidos
    phaseLabels2_clean = regexprep(phaseLabels2, '\s+', '');   % {'Rec','Cod1','Cod2','Cod3'}
    responseLabels2_clean = responseLabels2;                     % {'Hit','LCR','LFA'}
    nF2 = numel(phaseLabels2_clean);    % 4 fases
    nR2 = numel(responseLabels2_clean); % 3 respuestas

    % Generar varNames2
    varNames2 = cell(1, nF2*nR2);
    idx = 1;
    for f = 1:nF2
        for r = 1:nR2
            varNames2{idx} = sprintf('%s_%s', phaseLabels2_clean{f}, responseLabels2_clean{r});
            idx = idx + 1;
        end
    end

    % Asegurarnos de que son nombres MATLAB válidos
    varNames2 = matlab.lang.makeValidName(varNames2);

    % 8.2) Montar tabla subject × (fase×respuesta)
    D2 = table( ...
        subjs, ...
        meanRec(:,1), meanRec(:,2), meanRec(:,3), ...
        meanCod1(:,1), meanCod1(:,2), meanCod1(:,3), ...
        meanCod2(:,1), meanCod2(:,2), meanCod2(:,3), ...
        meanCod3(:,1), meanCod3(:,2), meanCod3(:,3), ...
        'VariableNames', ['Subject', varNames2] ...
    );

    % 8.3) Diseño intra-sujetos
    Phase2    = repelem(phaseLabels2_clean(:), nR2, 1);
    Response2 = repmat (responseLabels2_clean(:), nF2, 1);
    Within2 = table( ...
        categorical(Phase2), categorical(Response2), ...
        'VariableNames', {'Phase','Response'} ...
    );

    % 8.4) Ajuste del modelo y ANOVA
    formulaStr = sprintf('%s-%s ~ 1', varNames2{1}, varNames2{end});
    rm2    = fitrm(D2, formulaStr, 'WithinDesign', Within2);
    ranov2 = ranova(rm2, 'WithinModel', 'Phase*Response');

    % η²p para cada efecto principal e interacción
    isError  = startsWith(ranov2.Properties.RowNames,'Error');
    eta2pCol = nan(height(ranov2),1);

    for i = 1:height(ranov2)
        if ~isError(i) && ~strcmp(ranov2.Properties.RowNames{i},'(Intercept)')
            % la fila de error emparejada es la primera 'Error' que viene detrás
            SSr = ranov2.SumSq(i);
            SSe = ranov2.SumSq(find(isError & (1:height(ranov2))' > i, 1, 'first'));
            eta2pCol(i) = SSr / (SSr + SSe);
        end
    end
    ranov2.eta2p = eta2pCol;
    disp(ranov2);
    % 8.5) Comparaciones post-hoc Bonferroni
    cmpPhase2 = multcompare(rm2, 'Phase','By', 'Response','ComparisonType','bonferroni');
    cmpResponse2 = multcompare(rm2, 'Response','By', 'Phase', 'ComparisonType','bonferroni');
    sigComparisonsPhase2 = cmpPhase2(cmpPhase2.pValue<.05,:);
    sigComparisonsResp2 = cmpResponse2(cmpResponse2.pValue<.05,:);
    disp(sigComparisonsPhase2);
    disp(sigComparisonsResp2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% 9) SALIDA EN LaTeX PARA TABLAS
    % 9.1) Salida para ANOVA
    latexLines = {
      '\begin{table}[htbp]'
      '\caption{ANOVA de medidas repetidas: Ensayo (4) × Respuesta (3)}'
      '\begin{tabular}{lrrrrrr}'
      '\toprule Fuente & SC & gl & MC & F & pValor & $\eta^2_{p}$\\'
      '\midrule'};
    
    for i = 1:height(ranov2)
        src  = strrep(ranov2.Properties.RowNames{i},'_','\_');
        SS   = ranov2.SumSq(i);
        df   = ranov2.DF(i);
        MS   = ranov2.MeanSq(i);
        Fval = ranov2.F(i);
    
        % p-value con formato APA
        if ranov2.pValue(i) < .001
            pStr = '< .001';
        else
            pStr = sprintf('%.3f', ranov2.pValue(i));
        end
    
        % η²p: usa la columna que añadimos; NaN → "––"
        if isnan(ranov2.eta2p(i))
            etaStr = '--';
        else
            etaStr = sprintf('%.3f', ranov2.eta2p(i));
        end
    
        latexLines{end+1} = sprintf('%s & %.3g & %d & %.3g & %.2f & %s & %s\\\\', ...
                                    src, SS, df, MS, Fval, pStr, etaStr);
    end
    
    latexLines(end+1:end+3) = {'\bottomrule','\end{tabular}','\end{table}'};
    fprintf('%s\n', latexLines{:});
    
    % 9.2) SALIDA EN LaTeX PARA POST-HOC BONFERRONI
    % 1) Salida para efectos simples de PHASE dentro de cada RESPONSE
    latexPhaseByResp = makePosthocLaTeX( ...
        cmpPhase2, ...           % la tabla multcompare
        'Phase', ...             % factor principal
        'Response', ...          % columna "By"
        'Comparaciones post-hoc Bonferroni: Phase \\textit{by} Response' ...
    );
    fprintf('%s\n', latexPhaseByResp{:});
    
    % 2) Salida para efectos simples de RESPONSE dentro de cada PHASE
    latexRespByPhase = makePosthocLaTeX( ...
        cmpResponse2, ...
        'Response', ...
        'Phase', ...
        'Comparaciones post-hoc Bonferroni: Response \\textit{by} Phase' ...
    );
    fprintf('%s\n', latexRespByPhase{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% 10) Representación figura solo para hits, LFA y LCR
    figure2 = figure('Position',[100 100 900 500]);
    set( figure2, ...
     'DefaultAxesFontName','Times New Roman', ...
     'DefaultTextFontName','Times New Roman' );
    hb2 = bar(Y2,'grouped');
    hold on

    [ngroups2, nbars2] = size(Y2);
    groupwidth2 = min(0.8, nbars2/(nbars2+1.5));

    for k = 1:numel(hb2)
        hb2(k).FaceColor = 'flat';
        hb2(k).CData = repmat(baseColors(k,:), size(Y,1), 1);
        hb2(k).FaceAlpha = 0.5;
    end

    for k = 1:nbars2
        x = (1:ngroups2) - groupwidth2/2 + (2*k-1)*groupwidth2/(2*nbars2);
        errorbar(x, Y2(:,k), E2(:,k), 'k', 'LineStyle','none','LineWidth',1);
    end

    set(gca, 'XTick',1:ngroups2, 'XTickLabel',phaseLabels2, 'FontSize',12);
    xlabel('Ensayo','FontWeight','bold');
    ylabel('Media de Fijaciones Totales','FontWeight','bold');
    legend(hb2, responseLabels2, 'Location','NorthWest');
    %title('Solo hits, LCR y LFA','FontSize',14);
    ylim([0, max(Y2(:)+E2(:))*1.2]);
    hold off
    
end