function wts = utils_get_sfov_wts_based_on_bytes(thumb_bytes)
    [~, neighbor_pairs] = config_beam_coord_vectors;
    Ndir = length(neighbor_pairs);
    wts = cell(Ndir,1);
    for d = 1:Ndir
        d_idx = neighbor_pairs{d};
        tbyte1 = thumb_bytes(d_idx(:, 1), :);
        tbyte2 = thumb_bytes(d_idx(:, 2), :);
        tbyte = min(tbyte1,tbyte2,'includenan');
        tbyte = tbyte - min(tbyte(:)) + 1;
        tbyte(isnan(tbyte)) = 0;
        wts{d} = tbyte;
    end
end