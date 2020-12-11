function section_dir = utils_get_original_section_result_folder(ovv_dir)
    [section_parent,section_name,~] = fileparts(ovv_dir);
    if strcmp(section_parent(end),filesep)
        section_parent(end) = [];
    end
    section_parent = fileparts(section_parent);
    section_dir = [section_parent, filesep, section_name];
end