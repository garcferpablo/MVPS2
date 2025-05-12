function [LDI, REC] = ldi(S)
% fig1 crea una figura representando el numero de fijaciones total,
% en el ítem y en el fondo.
%
% Entradas:
% - S: struct array con campos .trial, .categ, …
%
% Salidas:
% LDI: lure discrimination index
% REC: corrected recognition scores.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Lure Discrimination index %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 1) IDs únicos y número de sujetos
subjects = unique({S.suj});% p.ej. {'01','02',...}
nSuj= numel(subjects);

% 2) Prealocar estructuras de resultados
LDI = struct('total', cell(1,nSuj), 'MF', cell(1,nSuj), 'DF', cell(1,nSuj));
REC = struct('total', cell(1,nSuj), 'MF', cell(1,nSuj), 'DF', cell(1,nSuj));

% 3) Bucle por sujeto
for iS = 1:nSuj
    subjID = subjects{iS}; % p.ej. '01'
    idx = strcmp({S.suj}, subjID); % máscara lógica

    % Extraer sólo los ensayos de este sujeto
    resp = [S(idx).respTag];% vector numérico
    stim = {S(idx).stimType}; % celda de strings
    cond = {S(idx).condicion};% celda de strings

    % Máscaras de tipo de ensayo
    isLure = strcmp(stim, 'lure');
    isFoil = strcmp(stim, 'foil');
    isTarget = strcmp(stim, 'target');

    % Totales de ensayos
    totalLure = sum(isLure);
    totalFoil = sum(isFoil);
    totalTarget = sum(isTarget);

    % Conteos globales
    LCR_total = sum(resp==2); % similar response to lure
    LFA_total = sum(resp == 3); % old response to lure
    Sr2F_total = sum(resp==9); % similar response to foil
    FFA_total = sum(resp==8); % old response to foil
    Hit_total  = sum(resp==1); % old response to target

    LDI(iS).total = LCR_total/totalLure - Sr2F_total/totalFoil;
    REC(iS).total = Hit_total/totalTarget - FFA_total/totalFoil;

    % Por condición
    isMF = strcmp(cond, 'MF');
    isDF = strcmp(cond, 'DF');

    nLure_MF = sum(isLure & isMF);
    nFoil_MF = sum(isFoil & isMF);
    nTarget_MF = sum(isTarget & isMF);
    nLure_DF = sum(isLure & isDF);
    nFoil_DF = sum(isFoil & isDF);
    nTarget_DF = sum(isTarget & isDF);

    % LDI
    LCR_MF = sum(resp==2 & isMF);
    LCR_DF = sum(resp==2 & isDF);

    LDI(iS).MF= LCR_MF/nLure_MF - Sr2F_total/totalFoil;
    LDI(iS).DF= LCR_DF/nLure_DF - FFA_total/totalFoil;

    % REC
    hit_MF = sum(resp==1 & isMF);
    FFA_MF = sum(resp==8 & isMF);
    hit_DF = sum(resp==1 & isDF);
    FFA_DF = sum(resp==8 & isDF);

    REC(iS).MF= hit_MF/nTarget_MF - Sr2F_total/totalFoil;
    REC(iS).DF= hit_DF/nTarget_DF - FFA_total/totalFoil;
end
% 4) Paired t-test LDI MF vs DF
% Extraer vectores columna
LDI_MF = [LDI.MF]';
LDI_DF = [LDI.DF]';

% Test t de Student para muestras relacionadas
[H,P,CI,STATS] = ttest(LDI_MF, LDI_DF);

% Mostrar resultados
fprintf('Paired t-test LDI MF vs DF:\n');
fprintf('  t(%d) = %.3f, p = %.4f\n', STATS.df, STATS.tstat, P);

% 5) Representación
% Extraer los vectores de LDI
LDI_total = [LDI.total];
LDI_MF    = [LDI.MF];
LDI_DF    = [LDI.DF];

% Combinar en una matriz (filas = sujetos, columnas = condiciones)
data = [LDI_total; LDI_MF; LDI_DF]';

% 2) Dibuja el boxplot base
figure('Color','w');
ax = axes; hold(ax,'on');
boxplot( ...
    data, ...
    'Positions',   1:3, ...
    'Widths',      0.5, ...
    'Colors',      'k', ...
    'Whisker',     1.5, ...
    'Symbol',      'ko', ...
    'OutlierSize', 4, ...
    'MedianStyle', 'line');

% 3) Localiza cajas y medianas
hBox = findobj(ax,'Tag','Box');      % Patch objects
hMed = findobj(ax,'Tag','Median');   % Line objects

% Ordena según X
[~,ord] = sort( arrayfun(@(b) mean(b.XData), hBox) );
hBox = hBox(ord);
hMed = hMed(ord);

% 4) Define estilos
fillCols = { [0 0 0],  [.7 .7 .7],  [1 1 1]};
edgeCols = { [0 0 0],  [0 0 0] , [0 0 0]};
medCols  = { [0 0 0],  [0 0 0], [0 0 0]};
medWidth = [2.5, 2, 2];

% 5) Parcha cada caja
for i = 1:3
    x = hBox(i).XData; y = hBox(i).YData;
    patch( x, y, fillCols{i}, ...
        'Parent',    ax, ...
        'FaceAlpha', 0.3, ...
        'EdgeColor', edgeCols{i}, ...
        'LineWidth', 1);
    set(hBox(i),'Visible','off');
end

% 7) Ajustes finales
hold(ax,'off');
xlim([0.5 3.5]);
xticks(1:3); xticklabels({'Total','MF','DF'});
ylabel('LDI', 'FontSize',16);

% Times New Roman
set(ax, ...
    'FontName',    'Times New Roman', ...
    'FontSize',    12, ...
    'Box',         'off', ...
    'LineWidth',   1.2);
set(get(ax,'XLabel'),'FontName','Times New Roman','FontSize',12);
set(get(ax,'YLabel'),'FontName','Times New Roman','FontSize',12);
set(get(ax,'Title'), 'FontName','Times New Roman','FontSize',14,'FontWeight','bold');


% Tabla en LaTeX
% Diferencias
d = LDI_MF - LDI_DF;

% Test t pareado
[~, p, ci, stats] = ttest(LDI_MF, LDI_DF);

% Estadísticos descriptivos
mDiff  = mean(d);
sdDiff = std(d);
seDiff = sdDiff/sqrt(nSuj);
tVal   = stats.tstat;
df     = stats.df;

% Formatear p-value estilo APA
if p < .001
    pStr = '< .001';
else
    pStr = sprintf('= %.3f', p);
end

latexLines = { ...
    '\begin{table}[htbp]', ...
    '  \caption{Prueba t de muestras pareadas para LDI: MF vs DF}', ...
    '  \label{tab:tLDI_MFvsDF}', ...
    '  \centering', ...
    '  \begin{tabular}{lrrrrrr}', ...
    '  \toprule', ...
    '  & M diferencia & Desv. std & Error s.e. & $t$ & gl & $p$ (bilateral) \\', ...
    '  \midrule', ...
    sprintf('  LDI MF--DF & %.3f & %.3f & %.3f & %.2f & %d & %s\\\\',...
    mDiff, sdDiff, seDiff, tVal, df, pStr), ...
    '  \bottomrule', ...
    '  \end{tabular}', ...
    '\end{table}'...
    };

% Imprime línea a línea (puedes redirigirlo a un .tex)
fprintf('%s\n', latexLines{:});
end
