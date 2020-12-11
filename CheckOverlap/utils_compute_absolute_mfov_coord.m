function [mfov_stitched_x, mfov_stitched_y, mfov_stitched_groups]=utils_compute_absolute_mfov_coord(mfovRelativePositionX,mfovRelativePositionY,mfovRelativeConf,mfov_stitch_conf_thresh,mfovAdjacencies,d_mfov, mfov_x, mfov_y)
    % compute the mfov absolute coordinate
    all_overlap = (mfovAdjacencies > 0);
    valid_overlap = (mfovRelativeConf > mfov_stitch_conf_thresh);
    lowconf_overlap = (mfovRelativeConf < mfov_stitch_conf_thresh) | (isnan(mfovRelativeConf) & all_overlap);
    adjacent_matrix = utils_recover_adjacent_matrix(valid_overlap.*mfovAdjacencies);
    mfov_stitched_groups = utils_group_connected_mfovs(adjacent_matrix);
    mmx = double(nanmean(mfov_x(:)));
    mmy = double(nanmean(mfov_y(:)));
    mfov_x = mfov_x - mmx;
    mfov_y = mfov_y - mmy;
    % in case missing too much coord info
    adjacent_matrix0 = utils_recover_adjacent_matrix(mfovAdjacencies>0);
    mfov_stitched_groups0 = utils_group_connected_mfovs(adjacent_matrix0);
    [~,ia,~] = unique(mfov_stitched_groups0);
    mfov_anchor_x = mfov_x(ia);
    mfov_anchor_y = mfov_y(ia);
    mfov_anchor_x(isnan(mfov_anchor_x)) = 0;
    mfov_anchor_y(isnan(mfov_anchor_y)) = 0;
    Nmfov = size(mfovAdjacencies,2);
    
    % rectify confidence matrix to prevent singularity
    mfovRelativeConf(lowconf_overlap) = mfov_stitch_conf_thresh;
    mfovRelativeConf(mfovRelativeConf>5*mfov_stitch_conf_thresh) = 5*mfov_stitch_conf_thresh;
    for d = 1:size(mfovAdjacencies,1)
        dx = median(mfovRelativePositionX(d,valid_overlap(d,:)),'omitnan');
        dy = median(mfovRelativePositionY(d,valid_overlap(d,:)),'omitnan');
        if isnan(dx) || isnan(dy)
            mfovRelativePositionX(d,lowconf_overlap(d,:)) = d_mfov(d,1);
            mfovRelativePositionY(d,lowconf_overlap(d,:)) = d_mfov(d,2);
        else
            mfovRelativePositionX(d,lowconf_overlap(d,:)) = dx;
            mfovRelativePositionY(d,lowconf_overlap(d,:)) = dy;
        end
    end
    all_overlap(4:end,:) = 0;
    Nov = sum(all_overlap(:));
    A = zeros(Nov+length(ia(:)),Nmfov);
    [~, m1] = find(all_overlap);
    m2 = mfovAdjacencies(all_overlap);
    Conf = mfovRelativeConf(all_overlap)-mfov_stitch_conf_thresh+0.25;
    DX = mfovRelativePositionX(all_overlap);
    DY = mfovRelativePositionY(all_overlap);
    A(sub2ind(size(A),(1:Nov)',m2)) = Conf;
    A(sub2ind(size(A),(1:Nov)',m1)) = -Conf;
    mconf = max(Conf(:));
    if isempty(mconf)
        mconf = 1;
    end
    for g = 1:length(ia)
        A(Nov+g,ia(g)) = mconf;
    end
    mfov_stitched_coord = A\double([Conf(:).*DX(:),Conf(:).*DY(:);mconf*mfov_anchor_x(:),mconf*mfov_anchor_y(:)]);
    mfov_stitched_x = mfov_stitched_coord(:,1) + mmx;
    mfov_stitched_y = mfov_stitched_coord(:,2) + mmy;
    mfov_stitched_x(isnan(mfov_x)) = nan;
    mfov_stitched_y(isnan(mfov_y)) = nan;
end