% Generate the csv file to pass downstream
addpath('GenerateReport');
try
    addpath('ConfigFiles');
    load('mSEM_retake_manager_default_folder.mat','result_dir');
    result_dir = uigetdir(result_dir,'Select the folder with the processed results');
catch
    result_dir = uigetdir('.','Select the folder with the processed results');
end

if isnumeric(result_dir)
    disp('No folder selected.');
    return;
end

if exist([result_dir,filesep,'report.mat'],'file')
    load([result_dir,filesep,'report.mat'],'section_list');
else
    section_list = utils_report_prepare_section_list(result_dir);
end

if isempty(section_list)
    disp('No section found in the result folder');
    return;
end
Nsec = length(section_list);
section_name = {section_list(:).section_name};
section_name = section_name(:);
section_path = {section_list(:).section_dirn};
section_path = section_path(:);
keep = repmat({'N'},Nsec,1);
idx = (~[section_list(:).discarded]) & (~[section_list(:).AFAS]) &...
    (~[section_list(:).retaken]) & ([section_list(:).user_decision] ~= -1);
keep(idx) = {'Y'};
user_comments = {section_list(:).user_comment};
user_comments = strrep(user_comments(:),',','*');
T = table(section_name,section_path,keep,user_comments);
[~,result_name] = fileparts(result_dir);
writetable(T,[result_dir,filesep,result_name,'.csv'],'Delimiter',',');
if ispc
    winopen([result_dir,filesep,result_name,'.csv']);
end