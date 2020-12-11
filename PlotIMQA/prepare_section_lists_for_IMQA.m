function [section_names, ifvalidated, ifready, result_section_dirs] = prepare_section_lists_for_IMQA(result_dir)
    % ifvalidated = 1: good_quality; -1: poor_quality; 0: not verified
    % ifready = 1: IMQA_ready; 0: not ready
    filelists = dir([result_dir,filesep,'**',filesep,'ovv_info.mat']);
    Ns = length(filelists);
    section_names = cell(Ns,1);
    ifvalidated = zeros(Ns,1,'single');
    ifready = false(Ns,1);
    % ifdiscard = false(Ns,1);
    result_section_dirs = {filelists.folder};
    for k = 1:Ns
        [~,secnm] = fileparts(filelists(k).folder);
        section_names{k} = secnm;
        if exist([filelists(k).folder, filesep,'IMQA_ready'],'file')
            ifready(k) = true;
            if exist([filelists(k).folder, filesep,'noretake'],'file')
                ifvalidated(k) = 1;
            elseif exist([filelists(k).folder, filesep,'yesretake'],'file')
                ifvalidated(k) = -1;
            else
                ifvalidated(k) = 0;
            end
        else
            ifready(k) = false;
            if exist([filelists(k).folder, filesep,'noretake'],'file')
                ifvalidated(k) = 1;
            elseif exist([filelists(k).folder, filesep,'yesretake'],'file')
                ifvalidated(k) = -1;
            else
                ifvalidated(k) = 0;
            end
        end
        % if the section is discarded, add 0.1 to ifvalidated
        if exist([filelists(k).folder, filesep,'discard'],'file')
            ifvalidated(k) = ifvalidated(k)+0.1;
        end
    end
     try
        outcell = split(section_names,'_');
        if length(section_names) == 1
            section_namest = outcell(end);
        else
            section_namest = outcell(:,end);
        end
        section_namest = strrep(strrep(section_namest,'S',''),'R','.');
        sec_id = str2double(section_namest(:));
    catch
        sec_id = section_names;
    end
    [~,idx] = sort(sec_id(:));
    section_names = section_names(idx);
    result_section_dirs = result_section_dirs(idx);
    ifready = ifready(idx);
    ifvalidated = ifvalidated(idx);
end