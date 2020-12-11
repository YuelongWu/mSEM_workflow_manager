function section_dir = utils_add_disk_label_to_sectiondir(section_dir)
    try
        if ispc
            [status, cmdout] = system(['vol ', section_dir(1:2)]);
            if status == 0
                outcell = textscan(cmdout,'%*s%s','Delimiter',{' is '});
                disklabel = outcell{1}{1};
                if ~isempty(disklabel)
                    section_dir = [disklabel,filesep,section_dir(3:end)];
                end
            end
        end
    catch
        % just return the unchanged directory
    end
end
