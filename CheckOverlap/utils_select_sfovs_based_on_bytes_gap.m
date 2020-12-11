function sfov_pairs = utils_select_sfovs_based_on_bytes_gap(thumb_bytes, sfov_coord)
    % select two sfovs to do jitter test etc based on thumbnail file size
    % lager files less likely to contain blank regions
    % prefered_dir: sign(mfov rotation angle)
    %   prefered_dir > 0: use pairs like beam 1-> beam 3
    %   prefered_dir < 0: use pairs like beam 1-> beam 4
    %   otherwise: use whichever has the largest thumbnails
    [~, neighbor_pairs] = config_beam_coord_vectors;
    neighbor_pairs = [neighbor_pairs{2};neighbor_pairs{3}];
    dY = sfov_coord(neighbor_pairs(:,2),2) - sfov_coord(neighbor_pairs(:,1),2);
    discard_idx = dY > median(dY,'omitnan');
    neighbor_pairs(discard_idx,:) = [];
    Np = size(neighbor_pairs,1);
    mxbytes = nan(Np,1,'single');
    for d = 1:Np
        tbyte1 = thumb_bytes(neighbor_pairs(d, 1));
        tbyte2 = thumb_bytes(neighbor_pairs(d, 2));
        tbyte = min(tbyte1,tbyte2,'includenan');
        mxbytes(d) = tbyte;
    end
    [mxbyte, idx] = max(mxbytes);
    sfov_pairs = neighbor_pairs(idx,:);
    if isnan(mxbyte) || mxbyte == 0
        sfov_pairs = nan(size(sfov_pairs),'single');
    end
end