 % Retake manager for mSEM.
% List of operations:
%   * check integrities of file system (region_metadata.csv, protocol.txt,
%     focusmap.txt, coordinate files & number of full-res/thumbnail images)
%   * check sFoV overlap, mFoV overlap, jittering
%   * generate overvie w images for ROI tracking
%   * plot IMQA information for image quality manual validation

% Yuelong Wu (Lichtman Lab @ Harvard University), May 2018
clc; clear; close all;  delete(timerfindall);
%% Select folders and generate folders
addpath('.','CheckOverlap','ConfigFiles','FileInventory','GenerateReport',...
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

[~, batch_name] = fileparts(batch_dir);
sysreslt_subdir = utils_get_sys_result_dir(batch_dir);

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

% ask the user to define the reason to start the batch
batch_info_dir = [result_parent, filesep, 'batch_info.txt'];

if ~exist(batch_info_dir,'file')
reasonList = {'Initial take','Test batch','Focus issue retake','Beam arc','Stage off-target',...
    'Consecutive AFAS failure','ZEN multiSEM issue', 'mFoV rotation','Wafer issue','Human mistake'};
[ridx,tf] = listdlg('ListString',reasonList,'SelectionMode','single',...
    'Name','Batch info','CancelString','Manually define');
if tf
    batch_cmt = reasonList{ridx};
else
    batch_cmt = inputdlg('Input batch info:');
    if isempty(batch_cmt)
        batch_cmt = 'User decided not to comment...';
    else
        batch_cmt = batch_cmt{1};
    end
end
[hstt,user_opt] = startwindow;
delete(hstt);
use_email_alert = user_opt.Email;
if user_opt.PlasmaStatus
    batch_cmt = [batch_cmt,'|Plasma treated:',user_opt.PlasmaMinute,'min'];
end
if user_opt.BeamCrntStatus
    batch_cmt = [batch_cmt,'|Beam current measured:',user_opt.BeamCrnt,'pA'];
end
try
fcm = fopen(batch_info_dir,'w');
fwrite(fcm, batch_cmt, 'char');
fclose(fcm);
catch
    try fclose(fcm);catch; end
end
end
if ~exist('use_email_alert','var')
    use_email_alert_str = questdlg('Send email notifications?','email alert option','Yes','No','Yes');
    if strcmpi(use_email_alert_str,'No')
        use_email_alert = false;
    else
        use_email_alert = true;
    end
end
switch use_email_alert
case true
    disp('Email notification will be sent.')
    % winopen('alert_recipients.txt')
    % use_email_alert = true;
case false
    disp('Email notification turned off.')
    % use_email_alert = false;
end

explogdir = [batch_dir, filesep, 'experiment_log.txt'];
firsttimeout = 3*3600; % 3hr timeout for 1st section
if ~exist(explogdir, 'file')
    disp(['Experiment folder: ', batch_dir]);
    disp('Waiting for the first section...')
    tstart = tic;
    pause(10)
    while ~exist(explogdir, 'file')
        pause(30)
        if toc(tstart) > firsttimeout
            disp('First section timed out.')
            return
        end
    end
end

[~, status] = update_job_queue(batch_dir,  '.', {}, 1);
if status.errRaised
    return;
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
%%
try
    user_options = config_user_options;
    user_options.use_email_alert = use_email_alert;
    p = gcp;
    p.IdleTimeout = 180;
    
    vTimer = process_one_batch_timer_wrapper(batch_dir,sys_result_parent,result_parent,user_options);
catch guiME
    fprintf(2,'Unexpected error happened in the main function.');
    try delete(timerfindall); catch; end
end