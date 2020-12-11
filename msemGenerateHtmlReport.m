% generate the report in html form. Result folder can either be a batch
% folder or a wafer folder. Keep the relative file path in those folders
% unchanged.
addpath('GenerateReport');
try
    addpath('ConfigFiles');
    load('mSEM_retake_manager_default_folder.mat','result_dir');
    result_dir = uigetdir(result_dir,'Select the folder with the processed results');
catch
    result_dir = '.';
    result_dir = 'F:\U19_Fish1_5\RetakeManager';
    result_dir = uigetdir(result_dir,'Select the folder with the processed results');
end

if isnumeric(result_dir)
    disp('No folder selected.');
    return;
end

[~, result_name] = fileparts(result_dir);
report_path = [result_dir, filesep, result_name,'_report.htm'];

utils_generate_html_reports(result_dir, report_path);

web(report_path,'-browser')