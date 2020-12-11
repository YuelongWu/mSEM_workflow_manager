function coord_struct = utils_resolve_coordinate_duplicates(coord_struct, beam_coord, verbose)
    % trying to find the right mFoV for images when multiple images have
    % identical mfov and beam number
    if nargin < 3
        verbose = true;
        if nargin < 2
            beam_coord = config_beam_coord_vectors;
        end 
    end
    dup_info = coord_struct.dup_info;
    if isempty(dup_info)
        return;
    end
    if isempty(dup_info.img_path)
        return;
    end
    
   
    xx = coord_struct.x;
    yy = coord_struct.y;
    [vec_alpha, vec_beta] = utils_estimate_alpha_beta_vectors(xx, yy, beam_coord);
    if any(isnan(vec_alpha)) || any(isnan(vec_beta))
        if verbose
            fprintf(2, '\t\t\tFail to compute the alpha or beta vectors. Image duplication not resolved\n');
        end
        return;
    end
    xx_c = median(xx - repmat(beam_coord(:,1) * vec_alpha(1) + beam_coord(:,2) * vec_beta(1),1, size(xx,2)), 1, 'omitnan');
    yy_c = median(yy - repmat(beam_coord(:,1) * vec_alpha(2) + beam_coord(:,2) * vec_beta(2),1, size(yy,2)), 1, 'omitnan');
    dN = length(coord_struct.dup_info.img_path);
    for k = 1:dN
        if ~isnan(dup_info.act_mfov_id(k)) % already validated
            continue;
        end
        x_c = dup_info.x(k) - beam_coord(dup_info.beam_id(k),1) * vec_alpha(1) - beam_coord(dup_info.beam_id(k),2) * vec_beta(1);
        y_c = dup_info.y(k) - beam_coord(dup_info.beam_id(k),1) * vec_alpha(2) - beam_coord(dup_info.beam_id(k),2) * vec_beta(2);
        [mindis, act_m_id] = min((xx_c-x_c).^2 + (yy_c - y_c).^2);
        if mindis < (0.25 * (vec_alpha'*vec_alpha)) % estimated mFoV center close to existing mFoV centers (<0.5 alpha)
            coord_struct.imgpath{dup_info.beam_id(k), act_m_id} = dup_info.img_path{k};
            coord_struct.x(dup_info.beam_id(k), act_m_id) = dup_info.x(k);
            coord_struct.y(dup_info.beam_id(k), act_m_id) = dup_info.y(k);
            coord_struct.dup_info.act_mfov_id(k) = act_m_id; 
            if verbose && (dup_info.mfov_id(k) ~= act_m_id)
                fprintf(1, ['\t\t\t',strrep(dup_info.img_path{k},'\','\\'), ...
                    ' should belong to mFoV #', num2str(act_m_id),'\n']);
            end
        else
            if verbose
                fprintf(2, ['\t\t\tCannot find the right mFoV for ',strrep(dup_info.img_path{k},'\','\\'),'.\n']);
            end
        end
    end
    correct_idx = (dup_info.mfov_id == coord_struct.dup_info.act_mfov_id);
    coord_struct.dup_info.img_path = coord_struct.dup_info.img_path(~correct_idx);
    coord_struct.dup_info.x = coord_struct.dup_info.x(~correct_idx);
    coord_struct.dup_info.y = coord_struct.dup_info.y(~correct_idx);
    coord_struct.dup_info.mfov_id = coord_struct.dup_info.mfov_id(~correct_idx);
    coord_struct.dup_info.beam_id = coord_struct.dup_info.beam_id(~correct_idx);
    coord_struct.dup_info.act_mfov_id = coord_struct.dup_info.act_mfov_id(~correct_idx);
end
        
    