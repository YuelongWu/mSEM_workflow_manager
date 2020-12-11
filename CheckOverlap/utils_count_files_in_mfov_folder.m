function [thumb_count, img_count, mfov_bytes] = utils_count_files_in_mfov_folder(mfov_folder)
    % count if there are right numbers of full-res/thumbnail images.
    filelist = dir(mfov_folder);
    mfov_bytes = sum([filelist.bytes])/(1024^3);
    filelist = filelist((~[filelist.isdir]) & ([filelist.bytes] > 10)); % only consider file size > 10 Byte
    filename = {filelist.name};
    img_count = sum(contains(filename,'.bmp') & (~contains(filename,'thumbnail')));
    if img_count == 0
        img_count = sum(contains(filename,'.jp2'));
    end
    thumb_count = sum(contains(filename,{'.jpg', '.bmp'}) & contains(filename,'thumbnail')); 
end