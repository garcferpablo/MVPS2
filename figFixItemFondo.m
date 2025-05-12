function [figure1, table1] = figFixItemFondo(S)
% figFixItemFondo crea una figura representando el % de fijaciones en Ítem vs Fondo
% y realiza ANOVAs de medidas repetidas (StimType×Condition) para cada medida.
%
% Entradas:
% - S: struct array con campos .suj, .stimType, .condicion, .totalFix, .itemFix, .fondoFix
%
% Salidas:
% - figure1: handle de la figura creada
% - table1: struct con campos
%       .Item  = tabla ANOVA para % Ítem
%       .Fondo = tabla ANOVA para % Fondo

%% 1) Preparar datos
subjs      = unique({S.suj});
stimTypes2 = {'target','lure'};
condLabels = {'MF','DF'};
nS         = numel(subjs);
nT2        = numel(stimTypes2);
nC         = numel(condLabels);
nComb2     = nT2 * nC;

% Matriz sujeto × (Target-MF, Target-DF, Lure-MF, Lure-DF) × {1=Item,2=Fondo}
propMat = nan(nS, nComb2, 2);

for iSub = 1:nS
    isSub = strcmp({S.suj}, subjs{iSub});
    for iT2 = 1:nT2
        for iC = 1:nC
            isCond = isSub ...
                   & strcmp({S.stimType},   stimTypes2{iT2}) ...
                   & strcmp({S.condicion},   condLabels{iC});
            idx    = (iT2-1)*nC + iC;
            totalFix        = sum([S(isCond).totalFix]);
            propMat(iSub,idx,1) = sum([S(isCond).itemFix])  / totalFix;
            propMat(iSub,idx,2) = sum([S(isCond).fondoFix]) / totalFix;
        end
    end
end

%% 2) Crear tabla "larga" para boxplots
% Prealoca
nRows = nS * nComb2 * 2;
Subject   = cell(nRows,1);
StimType  = cell(nRows,1);
Condition = cell(nRows,1);
Measure   = cell(nRows,1);
Prop      = nan(nRows,1);

row = 0;
measLabels = {'Item','Fondo'};
for iSub = 1:nS
    for iT2 = 1:nT2
        for iC = 1:nC
            idxComb = (iT2-1)*nC + iC;
            for iM = 1:2
                row = row + 1;
                Subject{row}   = subjs{iSub};
                StimType{row}  = stimTypes2{iT2};
                Condition{row} = condLabels{iC};
                Measure{row}   = measLabels{iM};
                Prop(row)      = propMat(iSub, idxComb, iM);
            end
        end
    end
end

Subject   = categorical(Subject,   subjs);
StimType  = categorical(StimType,  stimTypes2);
Condition = categorical(Condition, condLabels);
Measure   = categorical(Measure,   measLabels);

tblFix = table(Subject, StimType, Condition, Measure, Prop);
assert(height(tblFix)==nRows, 'Error en construcción de tblFix.');

%% 3) Dibujar boxplots
figure1 = figure('Color','w','Units','normalized','Position',[.1 .2 .6 .6]);
t = tiledlayout(3,1,'TileSpacing','compact','Padding','compact');

% Parámetros de posición
delta   = 0.25;
basePos = [1,2];
posCond = [ basePos(1)-delta, basePos(1)+delta, ...
            basePos(2)-delta, basePos(2)+delta ];

grayFill = [0.7 0.7 0.7];
edgeCol  = [0 0 0];

% — Tile 1: % Ítem —
ax1     = nexttile(t,1);
maskIt  = tblFix.Measure=='Item';
boxplot( tblFix.Prop(maskIt), ...
         {tblFix.StimType(maskIt), tblFix.Condition(maskIt)}, ...
         'Positions',      posCond, ...
         'FactorSeparator',1, ...
         'Colors',         repmat(edgeCol,4,1), ...
         'Widths',         0.4, ...
         'Whisker',        1.5, ...
         'Symbol',         'ko', ...
         'OutlierSize',3, ...
         'MedianStyle',    'line');
ylabel(ax1, '% Ítem', 'FontName','Times New Roman');
set(ax1, 'XTick',[],'FontSize',12,'LineWidth',1.2,'FontName','Times New Roman');

% parchar MF/DF
hB = findobj(ax1,'Tag','Box');
[~,ord] = sort(arrayfun(@(b) mean(b.XData), hB));
hB = hB(ord);
for iB=1:4
    x = get(hB(iB),'XData');
    y = get(hB(iB),'YData');
    if mod(iB-1,2)==0  % MF
        patch(x,y,grayFill, 'EdgeColor',edgeCol,'Parent',ax1);
    else               % DF
        patch(x,y,'w',       'EdgeColor',edgeCol,'Parent',ax1);
    end
end

% — Tile 2: % Fondo —
ax2     = nexttile(t,2);
maskFd  = tblFix.Measure=='Fondo';
boxplot( tblFix.Prop(maskFd), ...
         {tblFix.StimType(maskFd), tblFix.Condition(maskFd)}, ...
         'Positions',      posCond, ...
         'FactorSeparator',1, ...
         'Colors',         repmat(edgeCol,4,1), ...
         'Widths',         0.4, ...
         'Whisker',        1.5, ...
         'Symbol',         'ko', ...
         'OutlierSize',3, ...
         'MedianStyle',    'line');
ylabel(ax2, '% Fondo','FontName','Times New Roman');
set(ax2, ...
    'XTick',      basePos, ...
    'XTickLabel', {'Target','Lure'}, ...
    'FontSize',   12, ...
    'LineWidth',  1.2, ...
    'FontName',   'Times New Roman');
xlabel(ax2, 'Tipo de Estímulo', 'FontName','Times New Roman');

hB = findobj(ax2,'Tag','Box');
[~,ord] = sort(arrayfun(@(b) mean(b.XData), hB));
hB = hB(ord);
for iB=1:4
    x = get(hB(iB),'XData');
    y = get(hB(iB),'YData');
    if mod(iB-1,2)==0
        patch(x,y,grayFill, 'EdgeColor',edgeCol,'Parent',ax2);
    else
        patch(x,y,'w',       'EdgeColor',edgeCol,'Parent',ax2);
    end
end

% — Tile 3: Leyenda —
axL = nexttile(t,3);
axis(axL,'off');
hMF = patch(NaN,NaN,grayFill,'EdgeColor',edgeCol);
hDF = patch(NaN,NaN,'w',      'EdgeColor',edgeCol);
legend(axL,[hMF,hDF], {'MF','DF'}, ...
       'Orientation','horizontal', 'Location', 'north','Box','off', ...
       'FontName','Times New Roman');

%% 4) ANOVA de medidas repetidas (2×2) para Item y para Fondo
function [ranovatbl, rm] = doANOVA(measTable)
        % PUEDE USAR nS, nComb2, nC, stimTypes2, condLabels
        X = nan(nS, nComb2);
        for i = 1:nComb2
            iT2  = ceil(i/nC);
            iC   = mod(i-1,nC)+1;
            mask = measTable.StimType==stimTypes2{iT2} & ...
                   measTable.Condition==condLabels{iC};
            X(:,i) = measTable.Prop(mask);
        end
        TblWide        = array2table(X, 'VariableNames',{'T_MF','T_DF','L_MF','L_DF'});
        TblWide.Subject = (1:nS)';
        Within = table( ...
            categorical(repelem(stimTypes2(:), nC, 1)), ...  % target,target,lure,lure
            categorical(repmat(condLabels(:),  nT2,1)), ...  % MF,DF,MF,DF
            'VariableNames', {'StimType','Condition'} ...
            );
        rm         = fitrm(TblWide, 'T_MF-L_DF~1', 'WithinDesign', Within);
        ranovatbl  = ranova(rm, 'WithinModel','StimType*Condition');
end


% 4.1) Ejecutar las ANOVAs
tblItem         = tblFix(tblFix.Measure=='Item',:);
[ranovatbl_Item, rm]  = doANOVA(tblItem);
tblFondo        = tblFix(tblFix.Measure=='Fondo',:);
[ranovatbl_Fondo, rm] = doANOVA(tblFondo);

% Guardar tablas crudas en la salida
table1.Item  = ranovatbl_Item;
table1.Fondo = ranovatbl_Fondo;

% 4.2) Calcular η²ₚ por búsqueda de la fila de error que sigue a cada efecto
for fn = {'Item','Fondo'}
    T      = table1.(fn{1});
    names  = T.Properties.RowNames;
    n      = height(T);
    isErr  = startsWith(names,'Error');
    SS     = T.SumSq;
    eta2p  = nan(n,1);

    for i = 1:n
        if ~isErr(i) && ~strcmp(names{i},'(Intercept)')
            % Busca el primer error que aparece tras la fila i
            idxErr = find(isErr & (1:n)' > i, 1, 'first');
            if ~isempty(idxErr)
                SSr       = SS(i);
                SSe       = SS(idxErr);
                eta2p(i)  = SSr / (SSr + SSe);
            end
        end
    end

    % Añadir la columna y re-asignar
    T.eta2p = eta2p;
    table1.(fn{1}) = T;
end

% 4.3) Imprimir LaTeX para ambas ANOVAs
print1 = applLTX(table1.Item);
print2 = applLTX(table1.Fondo);
fprintf('%s\n', print1{:});
fprintf('\n');
fprintf('%s\n', print2{:});

% 5)Post-hoc Bonferroni
% 5.1) Efecto de Category dentro de cada Condition
cmpStimType_by_Cond = multcompare(rm, ...
    'StimType', 'By', 'Condition', 'ComparisonType', 'bonferroni');

% 5.2) Efecto de Category dentro de cada Condition
cmpCond_by_StimType = multcompare(rm, ...
    'Condition', 'By', 'StimType', 'ComparisonType', 'bonferroni');


latexStimTypeByCond = makePosthocLaTeX( ...
    cmpStimType_by_Cond, 'StimType', 'Condition', ...
    'Comparaciones post-hoc Bonferroni: Tipo de estímulo by Condición');
fprintf('%s\n', latexStimTypeByCond{:});

latexCondByStimType = makePosthocLaTeX( ...
    cmpCond_by_StimType, 'Condition', 'StimType', ...
    'Comparaciones post-hoc Bonferroni: Condición by Tipo de estímulo');
fprintf('%s\n', latexCondByStimType{:});

end

% ---------------------------------------------------------
% Función local auxiliar: genera líneas LaTeX en APA7
% ---------------------------------------------------------
function latexLines = applLTX(tabl)
    latexLines = {
      '\begin{table}[htbp]'
      '\caption{ANOVA de medidas repetidas: Tipo de estímulo $\times$ Condición}'
      '\label{tab:anova_fix}'
      '\centering'
      '\begin{tabular}{lrrrrrr}'
      '\toprule'
      'Fuente & SS & gl & MS & F & $p$ & $\eta^2_{p}$ \\'
      '\midrule'
    };
    for i = 1:height(tabl)
        src   = strrep(tabl.Properties.RowNames{i}, '_', '\_');
        SS    = tabl.SumSq(i);
        df    = tabl.DF(i);
        MS    = tabl.MeanSq(i);
        Fval  = tabl.F(i);

        % p‐valor en formato APA
        p = tabl.pValue(i);
        if p < .001
            pStr = '< .001';
        else
            pStr = sprintf('%.3f', p);
        end

        % η²ₚ con if…else
        eta = tabl.eta2p(i);
        if isnan(eta)
            etaStr = '--';
        else
            etaStr = sprintf('%.3f', eta);
        end

        latexLines{end+1} = sprintf( ...
            '%s & %.3g & %d & %.3g & %.2f & %s & %s\\\\', ...
            src, SS, df, MS, Fval, pStr, etaStr);
    end
    latexLines(end+1:end+3) = {
      '\bottomrule'
      '\end{tabular}'
      '\end{table}'
    };
end