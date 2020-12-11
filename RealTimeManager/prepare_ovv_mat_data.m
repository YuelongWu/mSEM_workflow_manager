function ovv_info = prepare_ovv_mat_data(general_info, IMQA_info, coord_info, add_info, report_info)
    ovv_info = struct;
    try
        ovv_info.overview_scl = add_info.ds_scl;
    catch
        ovv_info.overview_scl = 1/16;
    end
    ovv_info.sectionDir = general_info.section_dir;
    ovv_info.sectionDirN = general_info.section_dirn;
    ovv_info.mfovNum = general_info.mfov_num;
    ovv_info.regionMetadataStatus = general_info.regionMetadata_status;
    ovv_info.focusMapStatus = general_info.focusMap_status;
    ovv_info.coordStatus = general_info.coord_status;
    ovv_info.mfovId = IMQA_info.regionMetadata.mfovId;
    ovv_info.IMQA = IMQA_info.regionMetadata.IMQA;
    ovv_info.stageCoord = IMQA_info.regionMetadata.xyCoordinates;
    ovv_info.focusMapData = IMQA_info.focusMapData;
    ovv_info.imgPath = coord_info.img_coord.imgpath';
    ovv_info.mfov_x = add_info.mfov_stitched_x;
    ovv_info.mfov_y = add_info.mfov_stitched_y;
    ovv_info.sfov_coord = add_info.sfov_coord;
    ovv_info.thumbsize = add_info.thumbsize;
    %  overlap status
    ovv_info.sfov_status = add_info.sfov_stitch_status;
    if abs(add_info.sfov_rotation) > 1
        ovv_info.sfov_status = 1;
    end
    if ~report_info.mfovOverlapCheckFinished
        ovv_info.mfov_status = -1;
    else
        ovv_info.mfov_status = 0;
    end
    if ~isempty(add_info.gapsMfovPairs)
        ovv_info.mfov_status = 1;
    end
    % image count status
    if ~report_info.imgNumberCheckFinished
        ovv_info.imgcount_status = -1;
    else
        ovv_info.imgcount_status = 0;
    end
    if ~isempty(report_info.missingThumb) || ~isempty(report_info.missingFullRes)
        ovv_info.imgcount_status = 1;
    end
    %
    if any(isnan(add_info.stage_jitter_amp))
        ovv_info.jitter_status = -1;
    else
        ovv_info.jitter_status = 0;
    end
    if any(add_info.stage_jitter_amp>0)
        ovv_info.jitter_status = 1;
    end
    %
    if any(isnan(add_info.top_distortion_amp))
        ovv_info.distort_status = -1;
    else
        ovv_info.distort_status = 0;
    end
    if any(add_info.top_distortion_amp>0)
        ovv_info.distort_status = 1;
    end
    %
    if any(isnan(add_info.mfov_scanfault))
        ovv_info.scanfault_status = -1;
    else
        ovv_info.scanfault_status = 0;
    end
    if any(add_info.mfov_scanfault>0)
        ovv_info.scanfault_status = 1;
    end
    %
  
    
    ovv_info.ovv_coord_ready = false;
    if general_info.doIMQAPlot && general_info.mfov_num>0
        ovv_info.IMQA_coord_ready = true;
    else
        ovv_info.IMQA_coord_ready = false;
    end
    try
        ovv_info = local_link_stage_and_ICS(ovv_info);
    catch
        % disp('Ouch')
    end
end

function ovv_info = local_link_stage_and_ICS(ovv_info)
    mfovNum = ovv_info.mfovNum;
    if mfovNum > 0
        IMQA = ovv_info.IMQA;
        xyCoordinates = ovv_info.stageCoord;
        mfovId = ovv_info.mfovId;
        ovv_info.mfovId = (1:mfovNum)';
        ovv_info.IMQA = nan(mfovNum,61);
        ovv_info.stageCoord = nan(mfovNum,2);
        idx = (mfovId>0) & (mfovId<=mfovNum);
        mFovId = mfovId(idx);
        xyCoordinates = xyCoordinates(idx,:);
        IMQA = IMQA(idx,:);
        ovv_info.stageCoord(mFovId,:) = xyCoordinates;
        ovv_info.IMQA(mFovId,:) = IMQA;
        ovv_info.ovv_coord_x = repmat(ovv_info.mfov_x(:),1,61) + ...
            repmat(ovv_info.sfov_coord(:,1)',mfovNum,1);
        ovv_info.ovv_coord_y = repmat(ovv_info.mfov_y(:),1,61) + ...
            repmat(ovv_info.sfov_coord(:,2)',mfovNum,1);
        ovv_info.ovv_coord_x = (ovv_info.ovv_coord_x - min(ovv_info.ovv_coord_x(:)))*ovv_info.overview_scl;
        ovv_info.ovv_coord_y = (ovv_info.ovv_coord_y - min(ovv_info.ovv_coord_y(:)))*ovv_info.overview_scl;
        ovv_info.ovv_coord_x = round(ovv_info.ovv_coord_x)+(ovv_info.thumbsize(2)*ovv_info.overview_scl+1)/2;
        ovv_info.ovv_coord_y = round(ovv_info.ovv_coord_y)+(ovv_info.thumbsize(1)*ovv_info.overview_scl+1)/2;
        
        ovv_info.ovv_coord_ready = true;
    end
end