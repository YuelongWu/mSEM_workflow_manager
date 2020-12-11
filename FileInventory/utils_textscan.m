function scanned_cell  = utils_textscan(input_str, fmt_str, Delimit)
    % Wrapper of the built-in textscan function with customized error
    % handling.
    if iscell(input_str)
        input_str_1 = [strjoin(input_str, [char(13),newline]), char(13), newline];
    else
        input_str_1 = [input_str(:); char(13); newline];        
    end
    try
        scanned_cell = textscan(input_str_1, fmt_str, 'Delimiter', Delimit, ...
            'ReturnOnError', 0);
    catch
        if ~iscell(input_str)
            input_str = strsplit(input_str(:)',[char(13), newline]);
            input_str = input_str(~cellfun(@isempty, input_str));
        end
        scanned_cell = textscan(['0', char(13), newline], fmt_str, 'Delimiter', Delimit);
        strfield_idx = (cellfun(@iscell, scanned_cell));
        scanned_cell(strfield_idx) = {{''}};
        fltfield_idx = (cellfun(@isfloat, scanned_cell));
        scanned_cell(fltfield_idx) = {nan};
        tN = length(input_str);
        for k = 1:length(scanned_cell)
            scanned_cell{k} = repmat(scanned_cell{k}, tN, 1);
        end
        for t = 1:tN
            try
                outcellt = textscan(input_str{t}, fmt_str, 1, 'Delimiter', Delimit, ...
                        'ReturnOnError', 0);
                for k = 1:length(scanned_cell)
                    scanned_cell{k}(t) = outcellt{k};
                end
            catch
                continue
            end
        end
    end