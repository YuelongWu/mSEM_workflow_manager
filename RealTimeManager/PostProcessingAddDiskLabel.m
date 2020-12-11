sourcePath = uigetdir('SwRslt','Select the software tmp folder');

filelist = dir([sourcePath,filesep,'**',filesep,'metadata_file_info.mat']);

for k = 1:length(filelist)
    try
        load([filelist(k).folder, filesep, filelist(k).name]);
        general_info.section_dirn = utils_add_disk_label_to_sectiondir(general_info.section_dir);
        save([filelist(k).folder, filesep, filelist(k).name],'coord_info','general_info','IMQA_info','prot_info');
    catch ME
        disp(filelist(k).name);
        disp(ME.message)
    end
end