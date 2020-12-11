function utils_output_overlap_err_img(result_dir, general_info, coord_info, add_info, gap_MfovPairs, lowConfMfovPairs, directional_bsfov_idx, parallel_read)
    if isempty(gap_MfovPairs) && isempty(lowConfMfovPairs)
        return
    end
    section_dir = general_info.section_dir;
    if ~exist(result_dir, 'dir')
        mkdir(result_dir);
    end
    thumb_path = coord_info.thumbnail_coord.imgpath;
    thumbsz = add_info.thumbsize;
    for k = 1:size(gap_MfovPairs,1)
        m1 = gap_MfovPairs(k,1);
        m2 = gap_MfovPairs(k,2);
        direct = find(add_info.mfovAdjacencies(:,m1) == m2);
        sfov_id1 = directional_bsfov_idx(direct,:);
        sfov_id2 = directional_bsfov_idx(7-direct,:);
        err_x = (add_info.mfovRelativePositionX(direct,m1)+add_info.mfov_stitched_x(m1)-add_info.mfov_stitched_x(m2));
        err_y = (add_info.mfovRelativePositionY(direct,m1)+add_info.mfov_stitched_y(m1)-add_info.mfov_stitched_y(m2));
        if (add_info.mfovRelativeConf(direct,m1)> 1.5) && (abs(err_x) < 15) &&(abs(err_y) < 15)
            xx1 = add_info.sfov_coord(sfov_id1,1);
            yy1 = add_info.sfov_coord(sfov_id1,2);
            xx2 = add_info.sfov_coord(sfov_id2,1) + add_info.mfovRelativePositionX(direct,m1);
            yy2 = add_info.sfov_coord(sfov_id2,2) + add_info.mfovRelativePositionY(direct,m1);
        else
            xx1 = add_info.sfov_coord(sfov_id1,1) + add_info.mfov_stitched_x(m1);
            yy1 = add_info.sfov_coord(sfov_id1,2) + add_info.mfov_stitched_y(m1);
            xx2 = add_info.sfov_coord(sfov_id2,1) + add_info.mfov_stitched_x(m2);
            yy2 = add_info.sfov_coord(sfov_id2,2) + add_info.mfov_stitched_y(m2);
        end
        minx = min(min(xx1),min(xx2)); miny = min(min(yy1),min(yy2));
        xx1 = round(xx1 - minx); xx2 = round(xx2-minx);
        yy1 = round(yy1 - miny); yy2 = round(yy2-miny);
        imgstack1 = utils_read_thumbnail_stack(section_dir,thumb_path(sfov_id1,m1),thumbsz,parallel_read);
        imgstack2 = utils_read_thumbnail_stack(section_dir,thumb_path(sfov_id2,m2),thumbsz,parallel_read);
        outimg = zeros(max(max(yy1),max(yy2))+thumbsz(1),max(max(xx1),max(xx2))+thumbsz(2),3,'uint8');
        for s = 1:length(xx1)
            outimg(yy1(s)+(1:thumbsz(1)),xx1(s)+(1:thumbsz(2)),1) = imgstack1(:,:,s);
        end
        outimg(:,:,3) = outimg(:,:,1);
        for s = 1:length(xx2)
            outimg(yy2(s)+(1:thumbsz(1)),xx2(s)+(1:thumbsz(2)),2) = imgstack2(:,:,s);
        end
        try
            imwrite(outimg,[result_dir,filesep,'gap_',num2str(m1),'_',num2str(m2),'.png']);
        catch
            disp('    Failed to save overlap gap image')
        end
    end
    
    for k = 1:size(lowConfMfovPairs,1)
        m1 = lowConfMfovPairs(k,1);
        m2 = lowConfMfovPairs(k,2);
        direct = find(add_info.mfovAdjacencies(:,m1) == m2);
        sfov_id1 = directional_bsfov_idx(direct,:);
        sfov_id2 = directional_bsfov_idx(7-direct,:);
        xx1 = add_info.sfov_coord(sfov_id1,1) + add_info.mfov_stitched_x(m1);
        yy1 = add_info.sfov_coord(sfov_id1,2) + add_info.mfov_stitched_y(m1);
        xx2 = add_info.sfov_coord(sfov_id2,1) + add_info.mfov_stitched_x(m2);
        yy2 = add_info.sfov_coord(sfov_id2,2) + add_info.mfov_stitched_y(m2);
        minx = min(min(xx1),min(xx2)); miny = min(min(yy1),min(yy2));
        xx1 = round(xx1 - minx); xx2 = round(xx2-minx);
        yy1 = round(yy1 - miny); yy2 = round(yy2-miny);
        imgstack1 = utils_read_thumbnail_stack(section_dir,thumb_path(sfov_id1,m1),thumbsz,parallel_read);
        imgstack2 = utils_read_thumbnail_stack(section_dir,thumb_path(sfov_id2,m2),thumbsz,parallel_read);
        outimg = zeros(max(max(yy1),max(yy2))+thumbsz(1),max(max(xx1),max(xx2))+thumbsz(2),3,'uint8');
        for s = 1:length(xx1)
            outimg(yy1(s)+(1:thumbsz(1)),xx1(s)+(1:thumbsz(2)),1) = imgstack1(:,:,s);
        end
        outimg(:,:,3) = outimg(:,:,1);
        for s = 1:length(xx2)
            outimg(yy2(s)+(1:thumbsz(1)),xx2(s)+(1:thumbsz(2)),2) = imgstack2(:,:,s);
        end
        try
            imwrite(outimg,[result_dir,filesep,'lowconf_',num2str(m1),'_',num2str(m2),'.png']);
       catch
            disp('    Failed to save overlap low-conf image')
        end
    end
end