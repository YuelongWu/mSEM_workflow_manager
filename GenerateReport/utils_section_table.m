function tablestr = utils_section_table(sec_info, batch_id)
    nl = [char(13),newline];
    idt1 = char(9);
    trhead = utils_tr_thead;
    Nsec = length(sec_info);
    trbody = cell(Nsec,1);
    crnt_batch = batch_id == max(batch_id(:));
    crnt_sec = false(Nsec,1);
    [~, idx] = max([sec_info.end_time]);
    crnt_sec(idx) = true;
    sec_id = strrep(cellstr(num2str((1:Nsec)')),' ','0');
    for k = 1:1:Nsec
        trbody{k} = utils_tr_one_section(sec_info(k), crnt_batch(k), crnt_sec(k), sec_id{k});
    end
    tablestr = ['<table id="sectionTable">',nl,...
        idt1,'<thead>',nl, trhead,idt1,'</thead>',nl,...
        idt1,'<tbody>',nl, horzcat(trbody{:}),idt1,'</tbody>',nl,...
        '</table>', nl];
end