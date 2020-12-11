function report_info = prepare_user_mat_data(general_info, IMQA_info, coord_info, overlap_status, add_info, prot_info)
    report_info = struct;
    % general infomation
    report_info.AFAS = general_info.AFAS;
    report_info.sectionDir = general_info.section_dir;
    report_info.sectionDirN = general_info.section_dirn;
    report_info.duration = general_info.duration;
    report_info.fspNum = general_info.fsp_num;
    report_info.mfovNum = general_info.mfov_num;
    report_info.metaErrRaised = general_info.metaErrRaised;
    report_info.processErrRaised = overlap_status.errRaised;
    report_info.sfovOverlapCheckFinished = overlap_status.sfovOverlapCheckFinished;
    report_info.mfovOverlapCheckFinished = overlap_status.mfovOverlapCheckFinished;
    report_info.imgNumberCheckFinished = overlap_status.imgNumberCheckFinished;
    report_info.overviewImgGenerated = overlap_status.overviewImgGenerated;
    report_info.stageJitteringCheckFinished = overlap_status.stageJitteringCheckFinished;
    report_info.imageChargingCheckFinished = overlap_status.imageChargingCheckFinished;
    report_info.scanfaultCheckFinished = overlap_status.scanfaultCheckFinished;
    report_info.mfovBytes = sum(add_info.mfovBytes);
    report_info.metaBytes = general_info.metaBytes;
    % metadata file status
    report_info.regionMetadataStatus = general_info.regionMetadata_status;
    report_info.focusMapStatus = general_info.focusMap_status;
    report_info.protocolStatus = general_info.protocol_status;
    report_info.coordStatus = general_info.coord_status;
    report_info.workflowStatus = general_info.workflow_status;
    % fullres_check_status = add_info.fullres_check_status;
    % if all(fullres_check_status==0)
    %     report_info.fullresCheckStatus = 0;
    % else
    %     report_info.fullresCheckStatus = 1;
    % end
    % IMQA info
    report_info.doIMQAPlot = general_info.doIMQAPlot;
%     report_info.mfovId = IMQA_info.regionMetadata.mfovId;
%     report_info.xyCoordinates = IMQA_info.regionMetadata.xyCoordinates;
    report_info.IMQA = [nanmean(IMQA_info.regionMetadata.IMQA(:)),nanstd(IMQA_info.regionMetadata.IMQA(:))];
    beam_IMQA = median(IMQA_info.regionMetadata.IMQA,'omitnan');
    [~,bb_idx] = mink(beam_IMQA,5);
    report_info.worst_beams = bb_idx;
    report_info.focusMapData = IMQA_info.focusMapData;
    report_info.prot_info = prot_info;
    % image count
    report_info.missingThumb = find(~(add_info.thumbCount >= coord_info.thumbnail_coord.expected_img_count));
    report_info.missingFullRes = find(~(add_info.imgCount >= coord_info.img_coord.expected_img_count));
    report_info.dupThumb = find(add_info.thumbCount > coord_info.thumbnail_coord.expected_img_count);
    report_info.dupFullRes = find(add_info.imgCount > coord_info.img_coord.expected_img_count);
    % overlap
    report_info.lowConfMfovPairs = add_info.lowConfMfovPairs;
    report_info.gapsMfovPairs = add_info.gapsMfovPairs;
    report_info.sfovStitchStatus = add_info.sfov_stitch_status;
    report_info.sfovRotation = add_info.sfov_rotation;
    report_info.stageJitter = sum(add_info.stage_jitter_amp(:)>0);
    report_info.imageDistort = sum(add_info.top_distortion_amp(:)>0);
    report_info.scanFault = sum(add_info.mfov_scanfault(:)>0);
    
%     try
%         report_info.overview_scl = add_info.ds_scl;
%     catch
%         report_info.overview_scl = 1/16;
%     end
end