function sec_sum_str = utils_section_summarize(section_list)
    nl = [char(13),newline];
    idt1 = char(9); idt2 = [char(9),char(9)];
    sec_sum_str = ['<p>',nl];
    section_ids = floor([section_list(:).section_id]);
    discarded = [section_list(:).discarded];
    lastestver = ~[section_list(:).retaken];
    notverified = [section_list(:).user_decision] == 0;
    toretake = ([section_list(:).user_decision] == -1) | ([section_list(:).AFAS]) | ([section_list(:).errorRaised]);
    sec_names = {section_list(:).section_name};
    section_num = max(section_ids);
    if isnan(section_num)
        sec_sum_str = [sec_sum_str,idt1,'<div style="color:red;">Section names do NOT fit ''S_R_'' pattern.</div>',nl];
    else
        if any(isnan(section_ids))
            sec_sum_str = [sec_sum_str,idt1,'<div style="color:orange;">Some section names do NOT fit ''S_R_'' pattern.</div>',nl];
        end
        idx = find(~ismember(1:section_num,section_ids(~discarded)));
        if isempty(idx)
            sec_sum_str = [sec_sum_str,idt1,'<div>No section missing &#9786;.</div>',nl];
        else
            sec_sum_str = [sec_sum_str,idt1,'<div>Missing sections: <span style="color:red;">',strrep(utils_convert_id_vector_into_str_report(idx),',',', '),'</span></div>',nl];
        end
        idx = toretake & lastestver & (~discarded);
        if any(idx)
            sec_sum_str = [sec_sum_str,idt1,'<div>Sections to retake: <span style="color:red;">',strjoin(sec_names(idx)),'</span></div>',nl];
        end
        idx = notverified(lastestver&(~discarded)&(~toretake));
        if any(idx)
            sec_sum_str = [sec_sum_str,idt1,'<div style="color:orange;">',num2str(sum(idx(:))),' sections have not been verified by the user</div>',nl];
        end
        idx = find(discarded);
        if ~isempty(idx)
            sec_sum_str = [sec_sum_str,idt1,'<div> Discarded sections: ',nl];
            for k = 1:length(idx)
                t = idx(k);
                sec_sum_str = [sec_sum_str,idt2,'<span style="color:blue;" title="',section_list(t).batch_timestamp,'">',section_list(t).section_name,', </span>',nl];
            end
            sec_sum_str = [sec_sum_str,idt1,'</div>',nl];
        end
    end
    sec_sum_str = [sec_sum_str,'</p>',nl,'<hr>',nl];
end