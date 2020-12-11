% Retake manager for mSEM.
% List of operations:
%   * check integrities of file system (region_metadata.csv, protocol.txt,
%     focusmap.txt, coordinate files & number of full-res/thumbnail images)
%   * check sFoV overlap, mFoV overlap, jittering
%   * generate overview images for ROI tracking
%   * plot IMQA information for image quality manual validation

% Yuelong Wu, May 2018 
clc; clear; close all;

%% Select folders and generate folders
addpath('CheckOverlap','ConfigFiles','FileInventory','GenerateReport',...
    'PlotIMQA','RealTimeManager','TrackROI');
try
    load('mSEM_retake_manager_default_folder.mat','batch_dir','result_dir')
catch
    batch_dir = '';
    result_dir = '';
end

batch_dir = uigetdir(batch_dir,'Select the experiment folder');
if isnumeric(batch_dir)
    disp('No experiment folder selected.');
    return;
end
result_dir = uigetdir(result_dir,'Select the result folder');
if isnumeric(result_dir)
    disp('No result folder selected.');
    return;
end
save(['ConfigFiles',filesep,'mSEM_retake_manager_default_folder.mat'],'batch_dir','result_dir')

wafermode = isempty(regexp(batch_dir,'\d{8}_\d{2}-\d{2}-\d{2}', 'once'));

if wafermode
    wafer_dir = batch_dir;
    batch_dirs = dir(wafer_dir);
    batch_dirs = batch_dirs([batch_dirs.isdir]);
    batch_dirs = batch_dirs(3:end);
else
    batch_dirs = struct;
    [wafer_dir,batch_name] = fileparts(batch_dir);
    batch_dirs.name = batch_name;
end
    
for bnn = 1:length(batch_dirs)
batch_dir = [wafer_dir,filesep,batch_dirs(bnn).name];
sysreslt_subdir = utils_get_sys_result_dir(batch_dir);
[batch_parent, batch_name] = fileparts(batch_dir);
result_parent = [result_dir, filesep, batch_name];
sys_result_parent = ['SwRslt', filesep, sysreslt_subdir];
if ~exist(result_parent,'dir')
    mkdir(result_parent);
end
if ~exist([result_parent,filesep,'metadata.txt'],'file')
    fidmeta = fopen([result_parent,filesep,'metadata.txt'],'w');
    fclose(fidmeta);
end
if ~exist(sys_result_parent,'dir')
    mkdir(sys_result_parent);
end
exetime = now;
exetimestr1 = datestr(now,'yyyymmddTHHMMSS');
exetimestr2 = datestr(now,'yyyy-mm-dd HH:MM:SS');
rmrlog = [sys_result_parent, filesep,'log_', exetimestr1, '.txt'];
diary(rmrlog)
diary on
disp(['Experiment folder: ', batch_dir]);
disp(['Result folder: ', result_parent]);
disp(['Current time: ', exetimestr2])

experiment_log_dir = [batch_dir, filesep, 'experiment_log.txt'];
if exist(experiment_log_dir,'file')
    disp('Using experiment_log file...')
    useExperimentLog = true;
else
    disp('Experiment_log file not found. Trying to process all subfolders from the source folder...')
    useExperimentLog = false;
end
%%
user_options = config_user_options;
p = gcp;
useExperimentLog = false
if useExperimentLog
    [job_queue, ~] = update_job_queue(batch_dir, sys_result_parent, {}, 0);
else
    job_queue = update_job_queue_no_exp_log(batch_dir, sys_result_parent);
end

Nj = length(job_queue);
for k = 1:1:Nj     
    section_dir = job_queue{k}.SectionName;
    if ~contains(section_dir, '017_S18R1')
        continue
    end
    fprintf('\n')
    disp(['Start to processing: ', section_dir]);
    disp(datestr(now,'yyyy-mm-dd HH:MM:SS'));
    [~,sectionName] = fileparts(section_dir);
    sys_sec_dir = [sys_result_parent,filesep,sectionName];
    res_sec_dir = [result_parent,filesep,sectionName];
    if ~exist(sys_sec_dir,'dir')
        mkdir(sys_sec_dir);
    end
    if ~exist(res_sec_dir,'dir')
        mkdir(res_sec_dir);
    end

    [general_info, IMQA_info, coord_info, prot_info] = Check_All_Metadata_Files(section_dir, sys_sec_dir, job_queue{k}, 1);
    general_info.doImgCheck = general_info.doImgCheck && user_options.doImgCheck;
    general_info.doMfovOverlapCheck = general_info.doMfovOverlapCheck && user_options.doMfovOverlapCheck;
    general_info.doSfovOverlapCheck = general_info.doSfovOverlapCheck && user_options.doSfovOverlapCheck;
    general_info.doIMQAPlot = general_info.doIMQAPlot && user_options.doIMQAPlot;
    general_info.doJittering = general_info.doJittering && user_options.doJittering;
    general_info.doROITracking = general_info.doJittering && user_options.doJittering;
    [overlap_status, add_info] = Check_Overlap_For_One_Section(section_dir, coord_info, general_info, sys_sec_dir, res_sec_dir, 1);
    % prepare user mat file
    report_info = prepare_user_mat_data(general_info, IMQA_info, coord_info, overlap_status, add_info, prot_info);
    ovv_info = prepare_ovv_mat_data(general_info, IMQA_info, coord_info, add_info, report_info);
    if report_info.doIMQAPlot
        fidflag = fopen([res_sec_dir,filesep,'IMQA_ready'],'w');
        fclose(fidflag);
    end
    save([res_sec_dir,filesep,'summary.mat'],'report_info');
    save([res_sec_dir,filesep,'ovv_info.mat'],'ovv_info');
    % write flag file
    if (~general_info.metaErrRaised) && (~overlap_status.errRaised)
        fidflag = fopen([sys_sec_dir, filesep,'processed'],'w');
        fclose(fidflag);
    end
    
    % save new coordinates
    if overlap_status.sfovOverlapCheckFinished || overlap_status.mfovOverlapCheckFinished
        coord_saved = save_stitched_image_coordinates(section_dir,coord_info, add_info);
        if ~coord_saved
            fprintf(2,'\t\tFail to save the stitched coordinates files to the server.\n')
            fprintf(1,'\t\tSave to the result folder imstead.\n')
            save_stitched_image_coordinates(res_sec_dir,coord_info, add_info);
        end
    end
    disp(' ')
    disp(' ')
end
diary off
end