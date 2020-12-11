function TF = save_stitched_image_coordinates(section_dir,coord_info, add_info)
try
    fid_img = fopen([section_dir, filesep, 'full_image_coordinates_corrected.txt'],'w');
    fid_thumb = fopen([section_dir, filesep, 'full_thumbnail_coordinates_corrected.txt'],'w');
    beam_num = size(add_info.sfov_coord,1);
    mfov_num = length(add_info.mfov_stitched_x(:));
    valid_coord = (~isnan(coord_info.img_coord.x)) & (~isnan(coord_info.thumbnail_coord.x));
    sclfactor = median((coord_info.img_coord.x(valid_coord)-mean(coord_info.img_coord.x(valid_coord)))./...
        (coord_info.thumbnail_coord.x(valid_coord)-mean(coord_info.thumbnail_coord.x(valid_coord))),'omitnan');
    stitched_x = repmat(add_info.mfov_stitched_x(:)',beam_num,1) + repmat(add_info.sfov_coord(:,1),1,mfov_num);
    stitched_y = repmat(add_info.mfov_stitched_y(:)',beam_num,1) + repmat(add_info.sfov_coord(:,2),1,mfov_num);
    idx = (~isnan(stitched_x)) & (~isnan(stitched_y)) & (~cellfun(@isempty,coord_info.thumbnail_coord.imgpath));
    str_x = cellstr(num2str(reshape(stitched_x(idx),sum(idx(:)),1),'%.3f'));
    str_y = cellstr(num2str(reshape(stitched_y(idx),sum(idx(:)),1),'%.3f'));
    fwrite(fid_thumb,strjoin(strcat(coord_info.thumbnail_coord.imgpath(idx),{char(9)},str_x,{char(9)},str_y,{char(9)},'0'),'\r\n'),'char*1');
    
    idx = (~isnan(stitched_x)) & (~isnan(stitched_y)) & (~cellfun(@isempty,coord_info.img_coord.imgpath));
    str_x = cellstr(num2str(reshape(stitched_x(idx)*sclfactor,sum(idx(:)),1),'%.3f'));
    str_y = cellstr(num2str(reshape(stitched_y(idx)*sclfactor,sum(idx(:)),1),'%.3f'));
    fwrite(fid_img,strjoin(strcat(coord_info.img_coord.imgpath(idx),{char(9)},str_x,{char(9)},str_y,{char(9)},'0'),'\r\n'),'char*1');
    
    fclose(fid_img);
    fclose(fid_thumb);
    TF = true;
catch
    try fclose(fid_img);catch;end
    try fclose(fid_thumb); catch; end
    if nargout < 1
        fprintf(2,'\t\tFail to save the stitched coordinates files.\n')
    end
    TF = false;
end