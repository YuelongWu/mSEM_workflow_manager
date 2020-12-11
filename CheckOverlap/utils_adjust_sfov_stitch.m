function add_info = utils_adjust_sfov_stitch(add_info, displc)
    % adjust the sfov stitching based on the full resolution check results
    wt = 5; % weight put on the full-res stitched results
    valid_idx = all(~isnan(displc),1);
    sampled_sfov = add_info.fullres_sampled_sfov;
    sampled_sfov = sampled_sfov(:,valid_idx)';
    if isempty(sampled_sfov)
        return
    end
    displc = displc(:,valid_idx)';
    [sampled_sfov, ~, ic] = unique(sampled_sfov,'rows');
    dispu = zeros(size(sampled_sfov));
    for k = 1:1:size(sampled_sfov,1)
        dispu(k,:) = median(displc(ic==k,:),1,'omitnan');
    end
    beam_num = size(add_info.sfov_coord,1);
    [~, neighbor_pairs,directional_bsfov_idx] = config_beam_coord_vectors;
    neighbor_pairs = vertcat(neighbor_pairs{:});
    sampled_sfov_1d = sampled_sfov(:,1)*beam_num + sampled_sfov(:,2);
    A = zeros(size(neighbor_pairs,1)+1,beam_num);
    wts = ones(size(neighbor_pairs,1)+1,1);
    b = zeros(size(neighbor_pairs,1)+1,2);
    for k = 1:size(neighbor_pairs,1)
        s1 = neighbor_pairs(k,1);
        s2 = neighbor_pairs(k,2);
        A(k,s1) = -1;
        A(k,s2) = 1;
        sampledTF = sampled_sfov_1d == (s1*beam_num + s2);
        if any(sampledTF)
            b(k,:) = -dispu(sampledTF,:);
            wts(k) = wt;
        end
    end
    A(end,1) = 1;
    dsfov_coord = (diag(wts)*A)\(diag(wts)*b);
    sfov_coord0 = add_info.sfov_coord;
    sfov_coord1 = sfov_coord0 + dsfov_coord;
    % displacement_vector0 = zeros(6,2);
    % displacement_vector1 = zeros(6,2);
    for k = 1:size(directional_bsfov_idx,1)
        dx0 = min(sfov_coord0(directional_bsfov_idx(7-k,:),1))-min(sfov_coord0(directional_bsfov_idx(k,:),1));
        dy0 = min(sfov_coord0(directional_bsfov_idx(7-k,:),2))-min(sfov_coord0(directional_bsfov_idx(k,:),2));
        dx1 = min(sfov_coord1(directional_bsfov_idx(7-k,:),1))-min(sfov_coord1(directional_bsfov_idx(k,:),1));
        dy1 = min(sfov_coord1(directional_bsfov_idx(7-k,:),2))-min(sfov_coord1(directional_bsfov_idx(k,:),2));
        add_info.mfovRelativePositionX(k,:) = add_info.mfovRelativePositionX(k,:) + dx0 - dx1;
        add_info.mfovRelativePositionY(k,:) = add_info.mfovRelativePositionY(k,:) + dy0 - dy1;
    end
    add_info.sfov_coord = sfov_coord1;
end
