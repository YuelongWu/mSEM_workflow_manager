addpath('PlotIMQA');
try
    addpath('ConfigFiles');
    load('mSEM_retake_manager_default_folder.mat')
    result_dir = 'Z:\lichtmanfs2\Yuelong\RetakeManagerVer2Beta\Results\U19_Zebrafish';
    result_dir = uigetdir(result_dir,'Select the result folder');
catch
    result_dir = '';
    result_dir = 'Z:\lichtmanfs2\Yuelong\RetakeManagerVer2Beta\Results\U19_Zebrafish';
    result_dir = uigetdir(result_dir,'Select the result folder');
end
if isnumeric(result_dir)
    disp('No folder selected');
    return;
end
plot_imqa_ui({result_dir})