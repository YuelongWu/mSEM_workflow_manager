sourcePath = uigetdir('SwRslt','Select the software tmp folder');
targetPath = uigetdir('tmp_result','Select the result folder');

filelist = dir([sourcePath,filesep,'**',filesep,'processed']);
folderlist = {filelist.folder};
for k = 1:length(folderlist)
    try
        foldername = folderlist{k};
        rel_direct = strrep(foldername,sourcePath,'');
        load([foldername,filesep,'metadata_file_info.mat']);
        load([foldername,filesep,'overlap_info.mat']);
        
        if exist([targetPath,rel_direct],'dir')
            load([targetPath,rel_direct,filesep,'summary.mat'],'report_info');
            ovv_info = prepare_ovv_mat_data(general_info, IMQA_info, coord_info, add_info, report_info);
            save([targetPath,rel_direct,filesep,'ovv_info.mat'],'ovv_info');
        else
            error('No taget place exist');
        end
    catch ME
        disp(folderlist{k});
        disp(ME.message)
    end
end