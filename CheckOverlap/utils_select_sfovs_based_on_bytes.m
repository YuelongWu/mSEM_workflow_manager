function sfov_pairs = utils_select_sfovs_based_on_bytes(thumb_bytes, prefered_dir)
    % select two sfovs to do jitter test etc based on thumbnail file size
    % lager files less likely to contain blank regions
    % prefered_dir: sign(mfov rotation angle)
    %   prefered_dir > 0: use pairs like beam 1-> beam 3
    %   prefered_dir < 0: use pairs like beam 1-> beam 4
    %   otherwise: use whichever has the largest thumbnails
    if nargin < 2
        prefered_dir = 0;
    end
    [~, neighbor_pairs] = config_beam_coord_vectors;
    Ndir = length(neighbor_pairs);
    sfov_pairs = nan(Ndir-1,2,'single');
    mxbytes = nan(Ndir-1,1,'single');
    for d = 1:(Ndir-1)
        d_idx = neighbor_pairs{d + 1};
        tbyte1 = thumb_bytes(d_idx(:, 1));
        tbyte2 = thumb_bytes(d_idx(:, 2));
        tbyte = min(tbyte1,tbyte2,'includenan');
        tbyte = tbyte - min(tbyte(:)) + 1;
        tbyte(isnan(tbyte)) = 0;
        [mxbyte, idx] = max(tbyte, [], 1);
        mxbytes(d) = mxbyte;
        sfov_pairs(d,:) = d_idx(idx,:);
    end
    switch prefered_dir
    case 0
        [mxbyte, midx] = max(mxbytes);
        sfov_pairs = sfov_pairs(midx,:);
    case 1
        mxbyte = mxbytes(1);
        sfov_pairs = sfov_pairs(1,:);
    case -1
        mxbyte = mxbytes(2);
        sfov_pairs = sfov_pairs(2,:);
    end
    if isnan(mxbyte)
        sfov_pairs = nan(size(sfov_pairs),'single');
    end
end
