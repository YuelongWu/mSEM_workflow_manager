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
        report_info = prepare_user_mat_data(general_info, IMQA_info, coord_info, overlap_status, add_info, prot_info);
        if exist([targetPath,rel_direct],'dir')
            save([targetPath,rel_direct,filesep,'summary.mat'],'report_info');
        else
            error('No taget place exist');
        end
    catch ME
        disp(folderlist{k});
        try
            disp(ME.message)
        end
    end
end