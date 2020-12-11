function [section_id, region_id]= utils_get_section_and_region_id(section_names)
    Ns = length(section_names);
    section_id = nan(Ns,1,'single');
    region_id = nan(Ns,1,'single');
    section_names = strrep(section_names,'.png','');
    section_str = [strjoin(section_names, [char(13),newline]), char(13), newline];
    try
        scanned_cell = textscan(section_str, '%*s%f%f', 'Delimiter', {'S','R'}, ...
            'ReturnOnError', 0);
        section_id = scanned_cell{1};
        region_id = scanned_cell{2};
    catch
        for k = 1:Ns
            str1 = section_names{k};
            % if contains(str1,'_')
            %     fmtstr = '%*s%f%f';
            % else
            %     fmtstr = '%f%f';
            % end
            fmtstr = '%*s%f%f';
            [scanned_cell, failidx] = textscan(str1,fmtstr,'Delimiter',{'S','R'});
            if isempty(scanned_cell{1})
                continue;
            end
            if isempty(scanned_cell{2})
                if failidx == length(str1)
                    scanned_cell{2} = 0;
                else
                    c1 = str1(failidx+1);
                    scanned_cell{2} = min(double(c1),255);
                end
            end
            section_id(k) = scanned_cell{1};
            region_id(k) = scanned_cell{2};
        end
    end
end