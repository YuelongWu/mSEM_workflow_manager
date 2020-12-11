function [exist_AFAS_folder, mFoV_ids, meta_bytes] = dir_section_folders(section_dir)
%     metaExt = {'.txt', '.csv', '.xaml'};
    fList = dir(section_dir);
    meta_bytes = sum([fList(~[fList.isdir]).bytes])/(1024^3);
    folderBool = [fList.isdir];
    folderName = {fList(folderBool).name};
    mFoV_ids = str2double(folderName);      % mFoV folders name can be converted to numbers
%     mfov_folders = strcat(section_dir, filesep, folderName(~isnan(mFoV_ids)));
    
    if any(strcmpi(folderName(isnan(mFoV_ids)), 'AFASFailure')) % check if AFASFailure folder exists
        exist_AFAS_folder = true;
    else
        exist_AFAS_folder = false;
    end
    
%     fileBool = ~[fList.isdir];
%     fileName = {fList(fileBool).name};
%     metaBool = contains(fileName,metaExt);
%     metadata_files = strcat(section_dir,filesep,fileName(metaBool));
    
    mFoV_ids = mFoV_ids(~isnan(mFoV_ids));
end