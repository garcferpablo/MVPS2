function [figure2, table2, sigComparisons2] = figAnova2(S)
% figAnova2 crea una figura representando la proporción de media de respuestas a cada estímulo
% PARA CADA CONDICIÓN y realiza el consiguiente análisis de datos.
%
% Entradas:
% - S: struct array con campos .trial, .categ, …
%
% Salidas:
% figures: representación/es gráfica/s.
% tables: análisis estadístico/s.

% 1) Extraer datos
% Obtenemos la lista de identificadores únicos de sujeto
subjs = unique({S.suj}); % {'01','02',…}
% fijar manualmente los tres tipos de estímulo que aparecen en tu struct
stimTypes = {'target','lure','foil'}; % Target, Lure y Foil
% y los tres códigos de respuesta posibles
respCodes = [1 2 3]; % 1=Old, 2=Similar, 3=New
respLabels = {'Old','Similar','New'};

% Número de sujetos, tipos de estímulo y tipos de respuesta
nS = numel(subjs);
nT = numel(stimTypes);
nR = numel(respCodes);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Proporción media de respuestas a cada tipo de estímulo POR CONDICIÓN %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Parámetros
stimTypes2 = {'target','lure'};
condLabels = {'MF','DF'};
respLabels = {'Old','Similar','New'};
nC = numel(condLabels);
nT2 = numel(stimTypes2);
nR = numel(respLabels);

% 1) Recalcular prop2 (igual que antes)
prop2 = nan(nS, nT2*nR*nC);
% Tiene una fila x suj y las columnas de prop2 son:
% Targ | Targ | Targ | Targ | Targ | Targ | Lure | Lure | Lure | Lure |
% MF | DF | MF | DF | MF | DF | MF | DF | MF | DF | ...
% Old | Old | Sim | Sim | new | new | Old | Old | Sim | Sim |

for iSub2 = 1:nS % recorrer cada sujeto
    isSub = strcmp({S.suj}, subjs{iSub2});
    for iT2 = 1:nT2 % recorrer cada tipo de estímulo (target, lure)
        isStim = isSub & strcmp({S.stimType}, lower(stimTypes2{iT2}));
        for iC = 1:nC % recorrer cada condición
            isCond = isStim & strcmp({S.condicion}, condLabels{iC});
            total = sum(isCond); %nº de ensayos TargMF/LureMF/TargDF/LureDF (debería ser 15 siempre)
            for iR2 = 1:nR
                isResp = isCond & [S.respRaw]==respCodes(iR2);
                idx = (iT2-1)*nR*nC + (iR2-1)*nC + iC;
                prop2(iSub2, idx) = sum(isResp)/total;

            end
        end
    end
end

% 1.2) Recrea el "map" de combinaciones (iT2,iR,iC)
nComb = nT2 * nR * nC;
combos = zeros(nComb,3);
cnt = 1;
for iT2 = 1:nT2
    for iR2 = 1:nR
        for iC = 1:nC
            combos(cnt,:) = [iT2, iR2, iC];
            cnt = cnt + 1;
        end
    end
end

% 1.3) Expande cada combinación por sujeto
% prop2(:) tiene tamaño [nS*nComb × 1], con
% sujeto = 1…nS para combos(1,:),
% luego sujeto = 1…nS para combos(2,:), etc.
subj_exp = repmat((1:nS)', nComb, 1); % [nS*nComb × 1]
combos_exp = repelem(combos, nS, 1); % [nS*nComb × 3]

% 1.4) Prepara cada columna como vector de longitud nS*nComb
Vsubj = categorical(subjs(subj_exp)', subjs);
Vstim = categorical(stimTypes2(combos_exp(:,1))', stimTypes2);
Vresp = categorical(respLabels(combos_exp(:,2))', respLabels);
Vcond = categorical(condLabels(combos_exp(:,3))', condLabels);
Vprop = prop2(:);

% 1.5) Construye la tabla de un golpe
tbl2 = table(Vsubj, Vstim, Vresp, Vcond, Vprop, ...
    'VariableNames', {'Subject','StimType','RespRaw','Condition','Prop'});

% 1.6) Comprueba un valor puntual (s01, lure–MF–New)
% row = tbl2.Subject=='s01' & tbl2.StimType=='lure' ...
% & tbl2.Condition=='MF' & tbl2.RespRaw=='New';
% fprintf('s01 lure–MF–New → tbl2.Prop = %.4f (debe ≈ 2/15)\n', tbl2.Prop(row));

%% 2) Boxplot con 12 cajas: Target y Lure, cada uno 3 respuestas × 2 cond
% — parámetros de posición (igual que antes) —
delta = 0.20;
boxWidth = 0.4;
gap = 0.25;
basePos = [1,2,3, 5,6,7];

pos = nan(1, numel(basePos)*2);
for i = 1:numel(basePos)
    %offset = (i > 3)*gap;
    centre = basePos(i); %+ offset;
    pos((i-1)*2 + (1:2)) = centre + [-delta, +delta];
end

% Colores por respuesta (Old, Similar, New)
respCols = lines(3);
% Crear respCols12 replicando cada color 2 veces
respCols12 = repelem(respCols, 2, 1);

% — dibujamos el boxplot —
figure('Color','w','Units','normalized','Position',[.1 .2 .8 .6]);
ax = axes('Position',[.1 .15 .8 .75]);
hold(ax,'on'); % <-- AQUI abrimos el hold

boxplot(tbl2.Prop, ...
    {tbl2.StimType, tbl2.RespRaw, tbl2.Condition}, ...
    'Parent', ax, ...
    'Positions', pos, ...
    'Widths', boxWidth, ...
    'FactorSeparator', 1, ... % línea vertical separando cada Stimtype
    'Whisker', 1.5, ...
    'Symbol', 'ko', ...
    'OutlierSize',3, ...
    'Colors', respCols12, ...
    'MedianStyle','line');

% — parches MF/DF y leyenda —
hBoxes = findobj(ax,'Tag','Box');
[~,ord] = sort(arrayfun(@(b) mean(get(b,'XData')), hBoxes));
hBoxes = hBoxes(ord);

legH = gobjects(6,1);
legLabels = cell(6,1);
idxLegend = 1;

map = zeros(numel(pos),3);
cnt = 1;
for iT2 = 1:nT2
    for iR2 = 1:nR
        for iC = 1:nC
            map(cnt,:) = [iT2, iR2, iC];
            cnt = cnt+1;
        end
    end
end

for iBox = 1:numel(hBoxes)
    b = hBoxes(iBox);
    m = map(iBox,:);
    respIdx = m(2);
    condIdx = m(3);
    col = respCols(respIdx,:);
    x = get(b,'XData'); y = get(b,'YData');
    if condIdx==1
        h = patch(x, y, col, 'FaceAlpha',.3,'EdgeColor',col,'LineWidth',1.2,'Parent',ax);
    else
        h = patch('XData',x,'YData',y,'FaceColor','none','EdgeColor',col,'LineWidth',1.5,'Parent',ax);
    end
    legH(idxLegend) = h;
    legLabels{idxLegend} = sprintf('%s %s',respLabels{respIdx},condLabels{condIdx});
    idxLegend = idxLegend + 1;
end

hold(ax,'off'); % <-- AQUÍ cerramos el hold justo antes de los ajustes de ejes

% — ajustes de ejes con solo dos ticks —
clusterPos = [ mean(pos(1:6)), mean(pos(7:12)) ];
set(ax, ...
    'XLim', [min(pos)-boxWidth, max(pos)+boxWidth], ...
    'XTick', clusterPos, ...
    'XTickLabel', {'Target','Lure'}, ...
    'FontSize', 14, ...
    'FontName', 'Times New Roman', ...
    'LineWidth', 1.2);
ylabel(ax,'Proporción de respuestas','FontSize',16,'FontName','Times New Roman');

% xlabel en el segundo eje
xlabel(ax,'Tipo de Estímulo', ...
    'FontSize',16, ...
    'FontName','Times New Roman')
% — añadir leyenda al gráfico —
legend(legH(1:idxLegend-7), legLabels(1:idxLegend-7), 'Location', 'eastoutside', 'FontSize', 12, 'FontName', 'Times New Roman', 'Box','off');


%% ANOVA Y POSTHOC ANALYSIS
% 0)Añadimos la variable Categoría en la tabla larga tbl2
tbl2.Category = categorical( ...
    strcat(string(tbl2.StimType),'_',string(tbl2.RespRaw)) );

% 1)Combinamos Categoría y Condición → 12 columnas (Cat_Cond)
tbl2.Fac = categorical( ...
    strcat(string(tbl2.Category),'_',string(tbl2.Condition)) );
tblWide= unstack(tbl2,'Prop','Fac','GroupingVariable','Subject');

%% --- PARCHE PARA ALINEAR COLUMNAS Y WithinDesign -----------------
% 0) decide primero cómo quieres que aparezca el contraste
%    (si quieres DF–MF como en R, pon DF primero):
condLabels = {'DF','MF'};        % <--  ¡ordénalos a tu gusto!

% 1) etiqueta de las 6 categorías (ya las tienes)
catLevels = categories(tbl2.Category)';   % {'lure_New' … 'target_Similar'}

% 2) construimos el orden deseado de nombres de columna: 6 cat × 2 cond
[wCat,wCond] = ndgrid(catLevels, condLabels);
wanted = strcat(string(wCat(:)), '_', string(wCond(:)));   % 12×1 string
wanted = cellstr(wanted);                                 % → cell array

% 3) reordenamos la tabla amplia (y actualizamos Yvars)
tblWide = tblWide(:, vertcat({'Subject'}, wanted));
Yvars = wanted;                                         % ahora ya coincide

% 4) creamos WithinDesign **en ese mismo orden**
WithinDesign = table( ...
    categorical(wCat(:), catLevels),  ...   % columna Category
    categorical(wCond(:), condLabels), ...  % columna Condition
    'VariableNames', {'Category','Condition'});
%% ----------------------------------------------------------------

% 3)Ajuste del modelo y ANOVA factorial
formula = sprintf('%s-%s ~ 1', Yvars{1}, Yvars{end});
rm= fitrm(tblWide, formula, 'WithinDesign', WithinDesign);
ranovatbl2 = ranova(rm,'WithinModel','Category*Condition');
table2= ranovatbl2;% ← para la salida como antes
disp(ranovatbl2)

% η²p para cada efecto principal e interacción
isError  = startsWith(ranovatbl2.Properties.RowNames,'Error');
eta2pCol = nan(height(ranovatbl2),1);

for i = 1:height(ranovatbl2)
    if ~isError(i) && ~strcmp(ranovatbl2.Properties.RowNames{i},'(Intercept)')
        % la fila de error emparejada es la primera 'Error' que viene detrás
        SSr = ranovatbl2.SumSq(i);
        SSe = ranovatbl2.SumSq(find(isError & (1:height(ranovatbl2))' > i, 1, 'first'));
        eta2pCol(i) = SSr / (SSr + SSe);
    end
end
ranovatbl2.eta2p = eta2pCol;

% 4)Post-hoc Bonferroni
%4.1) Efecto de Category dentro de cada Condition
cmpCond_by_Cat = multcompare(rm, ...
    'Condition', 'By', 'Category', 'ComparisonType', 'bonferroni');
% Opcional: extraer sólo los significativos
sigCond_by_Cat = cmpCond_by_Cat(cmpCond_by_Cat.pValue < .05, :);
disp(sigCond_by_Cat);

% 4.2) Efecto de Category dentro de cada Condition
cmpCat_by_Cond = multcompare(rm, ...
    'Category', 'By', 'Condition', 'ComparisonType', 'bonferroni');
sigCat_by_Cond = cmpCat_by_Cond(cmpCat_by_Cond.pValue < .05, :);
disp(sigCat_by_Cond);

%% SALIDA EN LaTeX PARA ANOVA
latexLines = {
  '\begin{table}[htbp]'
  '\caption{ANOVA de medidas repetidas: Categoría (6) × Condición (2)}'
  '\begin{tabular}{lrrrrrr}'
  '\toprule Fuente & SS & gl & MS & F & p & $\eta^2_{p}$\\'
  '\midrule'};

for i = 1:height(ranovatbl2)
    src  = strrep(ranovatbl2.Properties.RowNames{i},'_','\_');
    SS   = ranovatbl2.SumSq(i);
    df   = ranovatbl2.DF(i);
    MS   = ranovatbl2.MeanSq(i);
    Fval = ranovatbl2.F(i);

    % p-value con formato APA
    if ranovatbl2.pValue(i) < .001
        pStr = '< .001';
    else
        pStr = sprintf('%.3f', ranovatbl2.pValue(i));
    end

    % η²p: usa la columna que añadimos; NaN → "––"
    if isnan(ranovatbl2.eta2p(i))
        etaStr = '--';
    else
        etaStr = sprintf('%.3f', ranovatbl2.eta2p(i));
    end

    latexLines{end+1} = sprintf('%s & %.3g & %d & %.3g & %.2f & %s & %s\\\\', ...
                                src, SS, df, MS, Fval, pStr, etaStr);
end

latexLines(end+1:end+3) = {'\bottomrule','\end{tabular}','\end{table}'};
fprintf('%s\n', latexLines{:});

%% SALIDA EN LaTeX PARA POST-HOC BONFERRONI
latexCondByCat = makePosthocLaTeX( ...
    cmpCond_by_Cat, 'Condition', 'Category', ...
    'Comparaciones post-hoc Bonferroni: Condition \\textit{by} Category');
fprintf('%s\n', latexCondByCat{:});

latexCatByCond = makePosthocLaTeX( ...
    cmpCat_by_Cond, 'Category', 'Condition', ...
    'Comparaciones post-hoc Bonferroni: Category \\textit{by} Condition');
fprintf('%s\n', latexCatByCond{:});
end