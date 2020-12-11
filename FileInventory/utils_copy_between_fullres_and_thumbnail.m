function [coord_info, coord_info_t] = utils_copy_between_fullres_and_thumbnail(coord_info)
    coord_info_t = coord_info;
    thumbnail_coord = coord_info.thumbnail_coord;
    img_coord = coord_info.img_coord;
    thumb_miss = isnan(thumbnail_coord.x) | isnan(thumbnail_coord.y);
    img_miss = isnan(img_coord.x) | isnan(img_coord.y);
    
    scl = median((img_coord.x(:))./(thumbnail_coord.x(:)),'omitnan');
    
    thumb_miss_only = thumb_miss & (~img_miss);
    img_miss_only = img_miss & (~thumb_miss);
    
    thumbnail_coord.imgpath(thumb_miss_only) = local_switch_imgpath(img_coord.imgpath(thumb_miss_only),true);
    img_coord.imgpath(img_miss_only) = local_switch_imgpath(thumbnail_coord.imgpath(img_miss_only),false);
    coord_info_t.thumbnail_coord = thumbnail_coord;
    coord_info_t.img_coord = img_coord;

    thumbnail_coord.x(thumb_miss_only) = img_coord.x(thumb_miss_only)/scl;
    thumbnail_coord.y(thumb_miss_only) = img_coord.y(thumb_miss_only)/scl;
    img_coord.x(img_miss_only) = thumbnail_coord.x(img_miss_only)*scl;
    img_coord.y(img_miss_only) = thumbnail_coord.y(img_miss_only)*scl;
    
    coord_info.thumbnail_coord = thumbnail_coord;
    coord_info.img_coord = img_coord;
end

function outpath = local_switch_imgpath(inpath, isthumb)
    if isthumb
        outpath = strrep(inpath, 'thumbnail_','');
        outpath = strrep(outpath, '.jpg', '.bmp');
    else
        outpath = strrep(inpath, '\','\thumbnail_');
        outpath = strrep(outpath, '.bmp', '.jpg');
    end
end