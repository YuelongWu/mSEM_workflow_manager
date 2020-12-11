function [job_queue, status] = update_job_queue(batch_dir, sys_result_dir, processed_queue,waitfile)
    if nargin <4
        waitfile = false;
    end
    job_queue = {};
    experiment_log_dir = [batch_dir, filesep, 'experiment_log.txt'];
    [status, explog_info] = parse_experiment_log_file(experiment_log_dir,waitfile,1);
    if status.errRaised
        return
    end
    section_folder_list = dir(batch_dir);
    section_folder_list = section_folder_list([section_folder_list.isdir]);
    dotidx = ~contains({section_folder_list.name},'.'); % remove . and ..
    section_folder_list = section_folder_list(dotidx);
    N = length(explog_info);
    for k = 1:N
        if ~explog_info{k}.legit_entry
            continue;
        end
        nameappear = strfind({section_folder_list.name},explog_info{k}.SectionName);
        idx = find(~cellfun(@isempty,nameappear),1);
        if isempty(idx)
            continue;
        end
        section_name = section_folder_list(idx).name;        
        section_dir = [batch_dir, filesep, section_name];
        if any(strcmpi(processed_queue, section_dir))
            continue;
        end
        if exist([sys_result_dir, filesep, section_name, filesep, 'processed'], 'file')
            continue;
        end
        job_info = explog_info{k};
        job_info.SectionName = section_dir;
        job_queue = [job_queue;{job_info}];
    end
    
end