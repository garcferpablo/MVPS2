function [trialsByCat, trialIDs] = splitFixByCategory(fixData, category)
% splitFixByCategory   Separa fijaciones de una categoría en sus ensayos.
%
%   [trialsByCat, trialIDs] = splitFixByCategory(fixData, category)
%
%   - fixData:  struct array con campos .trial, .categ, …
%   - category: char, string o categorical con la categoría deseada.
%
%   Salidas:
%     trialsByCat:  1×M cell; cada cell es el array de structs de un ensayo.
%     trialIDs:     1×M vector con los valores únicos de .trial.

    % convierto la categoría buscada a string
    category = string(category);

    % extraigo todas las categorías como string array:
    sample = fixData(1).categ;
    if iscategorical(sample)
        cats = string([fixData.categ]);        % concatena categorical
    else
        cats = string({fixData.categ});        % pone char o string en cell → luego a string
    end

    % máscara lógica de las fijaciones que coinciden
    mask    = (cats == category);
    dataCat = fixData(mask);

    % si no hay nada, devuelvo vacío
    if isempty(dataCat)
        trialsByCat = {};
        trialIDs    = [];
        return;
    end

    % ensayos únicos y división en celda
    trialIDs    = unique([dataCat.trial]);
    trialsByCat = arrayfun(@(t) dataCat([dataCat.trial]==t), trialIDs, ...
                          'UniformOutput', false);
end