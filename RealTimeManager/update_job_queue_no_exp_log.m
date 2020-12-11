function job_queue = update_job_queue_no_exp_log(batch_dir, sys_result_dir)
    job_queue = {};
    
    section_folder_list = dir(batch_dir);
    section_folder_list = section_folder_list([section_folder_list.isdir]);
    dotidx = ~contains({section_folder_list.name},'.'); % remove . and ..
    section_folder_list = section_folder_list(dotidx);
    
    N = length(section_folder_list);
    for k = 1:N
        section_name = section_folder_list(k).name;        
        section_dir = [batch_dir, filesep, section_name];

        if exist([sys_result_dir, filesep, section_name, filesep, 'processed'], 'file')
            continue;
        end
        section_info = struct;
        section_info.SectionName = section_dir;
        section_info.duration = nan;
        section_info.mfov_num = 0;
        section_info.fsp_num = 0;
        section_info.success_fsp_num = 0;
        section_info.legit_entry = true;
        job_queue = [job_queue;{section_info}];
    end
    
end