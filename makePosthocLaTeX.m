function latex = makePosthocLaTeX(cmpT, mainFactor, byFactor, caption)
% makePosthocLaTeX: construye un bloque LaTeX para un multcompare "By".
%   cmpT       = output de multcompare(...)
%   mainFactor = nombre del factor que estás comparando ('Phase' o 'Response')
%   byFactor   = nombre de la columna de contexto ('Response' o 'Phase')
%   caption    = texto para \caption{}

  vn = cmpT.Properties.VariableNames;

  % Detectar columnas de niveles: e.g. 'Phase_1'/'Phase_2' o 'Response_1'/'Response_2'
  is1 = endsWith(vn, '_1');
  is2 = endsWith(vn, '_2');
  lvl1 = vn{is1};
  lvl2 = vn{is2};

  % Detectar estimate / lower / upper / pValue
  est   = vn{contains(vn,'Difference','IgnoreCase',1) | contains(vn,'Estimate','IgnoreCase',1)};
  low   = vn{contains(vn,'Lower','IgnoreCase',1)};
  upp   = vn{contains(vn,'Upper','IgnoreCase',1)};
  pv    = vn{contains(vn,'pValue','IgnoreCase',1)};

% 0) QUITAR DUPLICADOS "A vs B" / "B vs A" quedándonos con el menor p
 % 0.1) ordena ascendente por pValue
  cmpT = sortrows(cmpT, pv);

  % 0.2) extrae las dos columnas de nivel como string arrays
  lvl1col = string(cmpT.(lvl1));
  lvl2col = string(cmpT.(lvl2));
  bycol   = string(cmpT.(byFactor));

  N = height(cmpT);
  keys = strings(N,1);

  for i = 1:N
    % sort() sobre string array sí funciona: devuelve [menor; mayor]
    tmp = sort([ lvl1col(i), lvl2col(i) ]);
    % construye clave "Contexto:menor_mayor"
    keys(i) = bycol(i) + ":" + tmp(1) + "_" + tmp(2);
  end

  % 0.3) unique sobre string array conserva la PRIMERA aparición de cada clave
  [~, ia] = unique(keys, "stable");
  cmpT    = cmpT(ia, :);

  % 0.4) recalcula n para los labels
  n = height(cmpT);

  % Construir etiquetas: "Contexto: Nivel1 vs Nivel2"
  esc = @(s) strrep(s,'_','\_');
  labels = cell(n,1);
  ctxs   = cmpT.(byFactor);
  for i = 1:n
    labels{i} = sprintf('%s: %s vs %s', ...
                        esc(string(ctxs(i))), ...
                        esc(string(cmpT.(lvl1)(i))), ...
                        esc(string(cmpT.(lvl2)(i))));
  end

  % Negrita y asterisco para p<.05
  sig = cmpT.(pv) < .05;
  labels(sig) = strcat('\textbf{', labels(sig), '*}');

  % Montar cabecera LaTeX
  latex = {
    '\begin{table}[htbp]'
    ['\caption{', caption, '}']
    '\begin{tabular}{lrrrr}'
    '\toprule Comparación & Dif & IC$_{95\%}$ inf & sup & p\\'
    '\midrule'
  };

  % Añadir filas
  for i = 1:n
    pval = cmpT.(pv)(i);
    if pval < .001
      pstr = '< .001';
    else
      pstr = sprintf('%.3f', pval);
    end
    latex{end+1} = sprintf('%s & %.3f & %.3f & %.3f & %s\\\\', ...
                           labels{i}, ...
                           cmpT.(est)(i), ...
                           cmpT.(low)(i), ...
                           cmpT.(upp)(i), ...
                           pstr);
  end

  % Pie de tabla
  latex(end+1:end+3) = {'\bottomrule','\end{tabular}','\end{table}'};
end