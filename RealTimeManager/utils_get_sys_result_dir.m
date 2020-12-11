function sysreslt_subdir = utils_get_sys_result_dir(batch_dir)
    [batch_parent,batch_name] = fileparts(batch_dir);
    [batch_parent, batch_parents1] = fileparts(batch_parent);
    [batch_parent, batch_parents2] = fileparts(batch_parent);
    [~, batch_parents3] = fileparts(batch_parent);
    if ~isempty(batch_parents3)
        sysreslt_subdir = [batch_parents3,filesep,batch_parents2, filesep, batch_parents1,filesep,batch_name];
    else
        if ~isempty(batch_parents2)
            sysreslt_subdir = [batch_parents2, filesep, batch_parents1,filesep,batch_name];
        else
            if ~isempty(batch_parents1)
                sysreslt_subdir = [batch_parents1,filesep,batch_name];
            else
                sysreslt_subdir = batch_name;
            end
        end
    end
end