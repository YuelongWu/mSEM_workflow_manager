function outputstr = utils_convert_id_vector_into_str_report(v)
    % convert e.g. [2, 1, 4, 5, 6, 9] to string '1,2,4~6,9'
    if isempty(v)
        outputstr = '';
        return
    end
    v = v(~isnan(v));
    v = unique(v); % default sorted
    v = v(:);
    if isempty(v)
       outputstr = '';
       return
    end
    dv = diff(v);
    dv_head_one = [false; dv == 1];
    dv_tail_one = [dv == 1; false];
    dv_keep = (~dv_head_one) | (~dv_tail_one);
    
    vc = v(dv_keep);
    tail1c = dv_tail_one(dv_keep);
    
    Nvc = length(vc);
    
    if isempty(vc)
        outputstr = '';
    else
        tmpcell = repmat({''},Nvc,1);
        for k = 1:(Nvc-1)
            if tail1c(k) && (~dv_keep(k+1))
                tmpcell{k} = [num2str(vc(k)),'~'];
            else
                tmpcell{k} = [num2str(vc(k)),','];
            end
        end
        tmpcell{Nvc} = num2str(vc(end));
        outputstr = horzcat(tmpcell{:});
    end