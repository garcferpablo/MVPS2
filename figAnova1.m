function [figure1, table1, sigComparisons] = figAnova1(S)
% figAnova1 crea una figura representando la proporción media de respuestas a cada estímulo
% y realiza el consiguiente análisis de datos (ANOVA de medidas repetidas + post-hoc).

%% 1) Extraer y calcular proporciones
subjs      = unique({S.suj});
stimTypes  = {'target','lure','foil'};
respCodes  = [1 2 3];
respLabels = {'Old','Similar','New'};
nS = numel(subjs);
nT = numel(stimTypes);
nR = numel(respCodes);

prop = nan(nS, nT*nR);
for iSub = 1:nS
    isSub = strcmp({S.suj}, subjs{iSub});
    for iT = 1:nT
        isStim = isSub & strcmp({S.stimType}, lower(stimTypes{iT}));
        total  = sum(isStim);
        for iR = 1:nR
            isResp = isStim & [S.respRaw]==respCodes(iR);
            prop(iSub,(iT-1)*nR + iR) = sum(isResp)/total;
        end
    end
end

%% 2) Montar tabla long
nComb      = nT * nR;
combos     = zeros(nComb,2);
cnt        = 1;
for iT = 1:nT
    for iR = 1:nR
        combos(cnt,:) = [iT, iR];
        cnt = cnt + 1;
    end
end
subj_exp   = repmat((1:nS)', nComb, 1);
combos_exp = repelem(combos, nS, 1);

Vsubj = categorical(subjs(subj_exp)', subjs);
Vstim = categorical(stimTypes(combos_exp(:,1))', stimTypes);
Vresp = categorical(respLabels(combos_exp(:,2))', respLabels);
Vprop = prop(:);

tbl = table(Vsubj, Vstim, Vresp, Vprop, ...
    'VariableNames', {'Subject','StimType','RespRaw','Prop'});

%% 3) Boxplot
colors3 = lines(3);
colors9 = repmat(colors3, nT, 1);
pos     = [1 2 3, 5 6 7, 9 10 11];

figure1 = figure('Color','w','Units','normalized','Position',[.1 .2 .8 .6]);
ax = axes('Position',[.1 .15 .8 .75]);
hold(ax,'on');
boxplot(tbl.Prop, {tbl.StimType, tbl.RespRaw}, ...
    'Parent', ax, 'Positions', pos, 'Colors', colors9, ...
    'FactorSeparator',1, 'Widths',0.6, 'Whisker',1.5, ...
    'Symbol','ko', 'OutlierSize',2, 'MedianStyle','line');

hBoxes = findobj(ax,'Tag','Box');
[~,ord] = sort(arrayfun(@(b) mean(get(b,'XData')),hBoxes));
hBoxes = hBoxes(ord);

legH = gobjects(3,1);
for i = 1:numel(hBoxes)
    stimIdx = ceil(i/3);
    respIdx = mod(i-1,3) + 1;
    if stimIdx == respIdx
        edgeCol = [0 0.5 0];
        lw = 1.5;
    else
        edgeCol = colors9(i,:);
        lw = 1;
    end
    bx = hBoxes(i);
    x  = get(bx,'XData'); y = get(bx,'YData');
    hPatch = patch(x, y, colors9(i,:), 'FaceAlpha',0.3, ...
                   'EdgeColor',edgeCol, 'LineWidth',lw, 'Parent',ax);
    idx = respIdx;
    if isempty(legH(idx))
        legH(idx) = hPatch;
    end
end

hOld = hBoxes(1); hSim = hBoxes(2); hNew = hBoxes(3);
lg = legend(ax, [hOld,hSim,hNew], respLabels, ...
    'Location','eastoutside','FontSize',12, ...
    'FontName','Times New Roman','Box','off');

clusterPos = mean(reshape(pos,3,3),1);
set(ax, 'XLim',[0.5 11.5], 'XTick',pos, 'XTickLabel',{}, ...
    'FontSize',14, 'FontName','Times New Roman','LineWidth',1.2);
ylabel(ax,'Proporción de respuestas','FontSize',16,'FontName','Times New Roman');

ax2 = axes('Position',ax.Position,'Color','none', ...
    'XLim',ax.XLim,'XTick',clusterPos,'XTickLabel',stimTypes, ...
    'FontSize',14,'FontName','Times New Roman', ...
    'YTick',[],'Box','off');
ax2.XAxisLocation = 'bottom'; ax2.YAxisLocation = 'right';
xlabel(ax2,'Tipo de Estímulo','FontSize',16,'FontName','Times New Roman', ...
    'Units','normalized','Position',[0.5 -0.08 0], 'VerticalAlignment','top');
hold(ax,'off');

%% 4) ANOVA de medidas repetidas (formato wide)
rawCats      = strcat(cellstr(tbl.StimType), '_', cellstr(tbl.RespRaw));
tbl.Category = categorical(rawCats);

tblShort = tbl(:, {'Subject','Prop','Category'});
tblWide  = unstack(tblShort, 'Prop', 'Category', 'GroupingVariable', 'Subject');

Yvars = tblWide.Properties.VariableNames(2:end);
WithinDesign = table(categorical(Yvars, Yvars)', 'VariableNames', {'Category'}); 

firstVar = Yvars{1};
lastVar  = Yvars{end};
formula  = [firstVar '-' lastVar ' ~ 1'];
rm       = fitrm(tblWide, formula, 'WithinDesign', WithinDesign);

ranovatbl = ranova(rm,'WithinModel','Category');
table1    = ranovatbl;                       % Para devolverla como antes

% 4.1) Cálculo de η² parcial

% Filas: 3 = (Intercept):Category ; 4 = Error(Category)
SS_effect = ranovatbl.SumSq(3);
SS_error  = ranovatbl.SumSq(4);
eta2_partial = SS_effect / (SS_effect + SS_error);   % η² parcial

%% 5) Post-hoc Bonferroni
t = multcompare(rm, 'Category', 'ComparisonType', 'bonferroni');
t.Significant = t.pValue < 0.05;
sigComparisons = t(t.Significant,:);
disp('Comparaciones post-hoc (significativas):');
disp(sigComparisons);

%% 6) Imprimir tabla en formato LaTeX con η²
% 6.1) Formatear p-valores estilo APA 7
pInt = ranovatbl.pValue(1);           % p del (Intercept)
if pInt < .001
    pIntStr = '< .001';
else
    pIntStr = sprintf('%.3f', pInt);
end

pEff = ranovatbl.pValue(3);           % p del efecto (Intercept):Category
if pEff < .001
    pEffStr = '< .001';
else
    pEffStr = sprintf('%.3f', pEff);
end

% 6.2) Construir la tabla LaTeX
latexLines = { ...
    '\begin{table}[htbp]', ...
    '    \caption{ANOVA de medidas repetidas para el tipo de respuesta}', ...
    '    \label{tab:Tabla1}', ...
    '    \begin{tabular}{lrrrrrr}', ...
    '\toprule   & SC & GL & MC & F & pValor & $\eta^2_{p}$\\', ...
    '\midrule', ...
    sprintf('(Intercept) & %.3g & %d & %.3g & %.1f & %s & --\\\\', ...
            ranovatbl.SumSq(1), ranovatbl.DF(1), ranovatbl.MeanSq(1), ...
            ranovatbl.F(1), pIntStr), ...
    sprintf('Error & %.3g & %d & %.3g & -- & -- & --\\\\', ...
            ranovatbl.SumSq(2), ranovatbl.DF(2), ranovatbl.MeanSq(2)), ...
    sprintf('(Intercept):Categoría & %.3g & %d & %.3g & %.1f & %s & %.3f\\\\', ...
            SS_effect, ranovatbl.DF(3), ranovatbl.MeanSq(3), ...
            ranovatbl.F(3), pEffStr, eta2_partial), ...
    sprintf('Error(Categoría) & %.3g & %d & %.3g & -- & -- & --\\\\', ...
            SS_error, ranovatbl.DF(4), ranovatbl.MeanSq(4)), ...
    '\bottomrule', ...
    '\end{tabular}', ...
    '\end{table}' ...
    };

fprintf('%s\n', latexLines{:});    % imprime cada línea con salto de línea

%% 7) Tabla LaTeX de comparaciones múltiples (robusta a nombres de columnas)
latexPosthoc = makePosthocLaTeX_1f(t, 'Comparaciones post-hoc para Category');
fprintf('%s\n', latexPosthoc{:});
% esc = @(s) strrep(s,'_','\_');      % escapador de guiones bajos
% 
% % 7.1) Detectar nombres de columnas numéricas (igual que antes)
% vNames   = t.Properties.VariableNames;
% estVar   = vNames{find(contains(vNames, {'Estimate','Diff','Difference','Mean'}, 'IgnoreCase',true),1)};
% lowerVar = vNames{find(contains(vNames, {'Lower','LowerCI','LCL'}, 'IgnoreCase',true),1)};
% upperVar = vNames{find(contains(vNames, {'Upper','UpperCI','UCL'}, 'IgnoreCase',true),1)};
% 
% % 7.2) Etiquetas "A vs B", escapado y negrita+asterisco si p < .05
% cmpLabels = arrayfun(@(i) ...
%     sprintf('%s vs %s', esc(string(t.Category_1(i))), esc(string(t.Category_2(i)))), ...
%     (1:height(t))', 'UniformOutput', false);
% 
% isSig = t.pValue < .05;
% cmpLabels(isSig) = strcat('\textbf{', cmpLabels(isSig), '*}');
% 
% % 7.3) Generar líneas LaTeX
% latexPH = { ...
%     '\begin{table}[htbp]', ...
%     '    \caption{Comparaciones post-hoc con corrección de Bonferroni}', ...
%     '    \label{tab:TablaCompPostHoc}', ...
%     '    \begin{tabular}{lrrrr}', ...
%     '\toprule   Comparación & Dif.\ media & IC$_{95\%}$ inf & IC$_{95\%}$ sup & $p$\\', ...
%     '\midrule'};
% 
% for i = 1:height(t)
%     % p-valor APA
%     if t.pValue(i) < .001
%         pStr = '$< .001$';          % modo matemático seguro
%     else
%         pStr = sprintf('$%.3f$', t.pValue(i));  % también en modo matemático
%     end
% 
%     latexPH{end+1} = sprintf('%s & %.3f & %.3f & %.3f & %s\\\\', ...
%         cmpLabels{i}, t.(estVar)(i), t.(lowerVar)(i), t.(upperVar)(i), pStr);
% end
% 
% latexPH = [latexPH, '\bottomrule', '\end{tabular}', '\end{table}'];
% 
% fprintf('%s\n', latexPH{:});       % imprime cada línea con salto de línea

end

function latex = makePosthocLaTeX_1f(cmpT, caption)
% makePosthocLaTeX_1f: genera un bloque LaTeX para comparaciones post-hoc
% de un solo factor, ordenado por significación.
%
%   cmpT    = tabla resultante de multcompare(rm,…)
%   caption = texto para \caption{}

  % 1) Detectar columnas de niveles, estimate, IC y p-value
  vn   = cmpT.Properties.VariableNames;
  lvl1 = vn{endsWith(vn,'_1')};   % e.g. Category_1
  lvl2 = vn{endsWith(vn,'_2')};   % e.g. Category_2
  est  = vn{contains(vn,'Difference','IgnoreCase',1) ...
            | contains(vn,'Estimate','IgnoreCase',1)};
  low  = vn{contains(vn,'Lower','IgnoreCase',1)};
  upp  = vn{contains(vn,'Upper','IgnoreCase',1)};
  pv   = vn{contains(vn,'pValue','IgnoreCase',1)};

  % 2) Ordenar todas las comparaciones por p-valor (ascendente)
  cmpT = sortrows(cmpT, pv);

  % 3) Eliminar duplicados A vs B / B vs A (conservar el primero, que tiene el p más bajo)
  N = height(cmpT);
  keys = strings(N,1);
  for i = 1:N
    a = string(cmpT.(lvl1)(i));
    b = string(cmpT.(lvl2)(i));
    if a < b
      keys(i) = a + "__" + b;
    else
      keys(i) = b + "__" + a;
    end
  end
  [~, ia] = unique(keys, 'stable');
  cmpT = cmpT(ia,:);

  % 4) Cabecera LaTeX
  latex = {
    '\begin{table}[htbp]'
    ['\caption{', caption, '}']
    '\begin{tabular}{lrrrr}'
    '\toprule Comparación & Dif & IC$_{95\\%}$ inf & sup & p\\'
    '\midrule'
  };

  % 5) Añadir filas: etiqueta en negrita y con asterisco si p<.05
  for i = 1:height(cmpT)
    a = strrep(string(cmpT.(lvl1)(i)), '_', '\_');
    b = strrep(string(cmpT.(lvl2)(i)), '_', '\_');
    p = cmpT.(pv)(i);
    % Construir etiqueta
    label = sprintf('%s vs %s', a, b);
    if p < .05
      label = ['\textbf{', label, '*}'];
    end
    % Formatear p-value
    if p < .001
      pstr = '< .001';
    else
      pstr = sprintf('%.3f', p);
    end
    % Agregar la línea de la tabla
    latex{end+1} = sprintf('%s & %.3f & %.3f & %.3f & %s\\\\', ...
                           label, ...
                           cmpT.(est)(i), ...
                           cmpT.(low)(i), ...
                           cmpT.(upp)(i), ...
                           pstr);
  end

  % 6) Pie de tabla
  latex(end+1:end+3) = {
    '\bottomrule'
    '\end{tabular}'
    '\end{table}'
  };
end