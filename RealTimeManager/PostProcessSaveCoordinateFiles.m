sysrst_dir = uigetdir;
filelist = dir([sysrst_dir,filesep,'**', filesep, 'processed']);
tok = '';

for k = 1:length(filelist)
    try
        if isempty(tok) || contains(filelist(k).folder,tok)
            load([filelist(k).folder, filesep,'metadata_file_info.mat'],'general_info','coord_info');
            load([filelist(k).folder, filesep,'overlap_info.mat'],'add_info');
            save_stitiched_image_coordinates(general_info.section_dir,coord_info, add_info);
        end
    catch
        disp(k);
    end
end