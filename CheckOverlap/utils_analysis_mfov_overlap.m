function  [gap_MfovPairs, lowConfMfovPairs] = utils_analysis_mfov_overlap(add_info)
    mfov_stitched_x = add_info.mfov_stitched_x;
    mfov_stitched_y = add_info.mfov_stitched_y;
    mfov_stitched_groups = add_info.mfov_stitched_groups;
    cornerpts_info = add_info.cornerpts_info;
    mfovAdjacencies = add_info.mfovAdjacencies;
    sfov_coord = add_info.sfov_coord;
    imgsz = add_info.thumbsize;
    m1_group = repmat(mfov_stitched_groups(:)',size(mfovAdjacencies,1),1);
    m2_group = m1_group;
    m2_group(mfovAdjacencies>0) = mfov_stitched_groups(mfovAdjacencies(mfovAdjacencies>0));
    overlap_err = (m1_group~=m2_group);
    overlap_err(1:3,:) = 0;
    [~,m1] = find(overlap_err);
    m2 = mfovAdjacencies(overlap_err);
    lowConfMfovPairs = sort([m1,m2],2);
    
    % To detect gaps, check if all the concave corner points of each mfov 
    % is covered by another neigboring mfovs.
    overlap_err = 0 & overlap_err;
    for m1 = 1:size(overlap_err,2)
        concave_pts = cornerpts_info.corner_pts(cornerpts_info.concave_bool,:);
        concave_x = concave_pts(:,1);
        concave_y = concave_pts(:,2);
        concave_direct = cornerpts_info.corner_direct(cornerpts_info.concave_bool);
        covered_bool = false(size(concave_x));
        nb_ids = mfovAdjacencies(:,m1);
        nb_conf = add_info.mfovRelativeConf(:,m1);
        nb_rel_dx = add_info.mfovRelativePositionX(:,m1);
        nb_rel_dy = add_info.mfovRelativePositionY(:,m1);
        
        valid_ids = (nb_ids>0);
        nb_ids = nb_ids(valid_ids);
        nb_conf = nb_conf(valid_ids);
        nb_rel_dx = nb_rel_dx(valid_ids);
        nb_rel_dy = nb_rel_dy(valid_ids);
        
        nb_mfov_dx = mfov_stitched_x(nb_ids) - mfov_stitched_x(m1);
        err_x = nb_rel_dx - nb_mfov_dx;
        nb_mfov_dy = mfov_stitched_y(nb_ids) - mfov_stitched_y(m1);
        err_y = nb_rel_dy - nb_mfov_dy;
        uselocal = (nb_conf>1.5) & (abs(err_x)<15) & (abs(err_y)<15);
        nb_mfov_dx(uselocal) = nb_rel_dx(uselocal);
        nb_mfov_dy(uselocal) = nb_rel_dy(uselocal);
        
        nb_sfov_dx = repmat(nb_mfov_dx(:)', size(sfov_coord,1),1)+ repmat(sfov_coord(:,1),1,length(nb_ids));
        nb_sfov_dx = nb_sfov_dx(:);
        
        nb_sfov_dy = repmat(nb_mfov_dy(:)', size(sfov_coord,1),1)+ repmat(sfov_coord(:,2),1,length(nb_ids));
        nb_sfov_dy = nb_sfov_dy(:);
        for cn = 1:length(concave_x)
            x_covered = abs(nb_sfov_dx-concave_x(cn)) <= (imgsz(2)+2)/2;
            y_covered = abs(nb_sfov_dy-concave_y(cn)) <= (imgsz(1)+2)/2;
            if any(x_covered&y_covered)
                covered_bool(cn) = true;
            else
                covered_bool(cn) = false;
            end
        end
        err_direct = unique(concave_direct(~covered_bool));
        overlap_err(err_direct,m1) = (mfovAdjacencies(err_direct,m1)>0);
    end
    [~,m1] = find(overlap_err);
    m2 = mfovAdjacencies(overlap_err);
    gap_MfovPairs = sort([m1,m2],2);
    gap_MfovPairs = unique(gap_MfovPairs,'rows');
end