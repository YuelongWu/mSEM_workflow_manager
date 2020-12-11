function [img_path_cell, xx, yy, dup_info, mfov_img_count] = utils_arrange_img_coord(img_path, mfov_num, img_x, img_y, is_thumbnail, verbose)
    % Arrange coordinates into mfov_num-by-beam_num cells/matrices. Also
    % detect misplaced images and return those cannot be corrected.
    if nargin < 6
        verbose = true;
    end
    beam_num = 61;
    if is_thumbnail
        [mfov_id, beam_id] = utils_parse_thumbnail_image_name(img_path);
    else
        [mfov_id, beam_id] = utils_parse_fullres_image_name(img_path);
    end
    if max(mfov_id) > mfov_num
        if verbose
            fprintf(1, ['\t\tWarning: Excess mFoVs found in coordinate files:', ...
                num2str(max(mfov_id)),'/', num2str(mfov_num), '(found/expected)\n']);
            fprintf(1, '\t\t\tAbandon these mFoVs...\n');
        end
        mvalid_idx = (mfov_id <= mfov_num);
        img_path = img_path(mvalid_idx);
        img_x = img_x(mvalid_idx);
        img_y = img_y(mvalid_idx);
        mfov_id = mfov_id(mvalid_idx);
        beam_id = beam_id(mvalid_idx);
    end
    
    img_path_cell = repmat({''}, beam_num, mfov_num);
    xx = nan(beam_num, mfov_num);
    yy = nan(beam_num, mfov_num);
    
    dup_info = struct;
    dup_info.img_path = {};
    dup_info.x = [];
    dup_info.y = [];
    dup_info.mfov_id = [];
    dup_info.beam_id = [];
    dup_info.act_mfov_id = [];
    
    valid_idx = find((beam_id > 0) & (mfov_id > 0) &(beam_id <= beam_num));
    
    mfov_img_count = histcounts(mfov_id(valid_idx), 0.5:1:(mfov_num+0.5));
    indx = beam_id + (mfov_id - 1) * beam_num;
    img_path_cell(indx(valid_idx)) = img_path(valid_idx);
    xx(indx(valid_idx)) = img_x(valid_idx);
    yy(indx(valid_idx)) = img_y(valid_idx);
    
    % detect misplaced mFoVs
    img_count = histcounts(indx(valid_idx), 0.5:1:(mfov_num*beam_num+0.5));
    img_count = img_count(indx(valid_idx));
    dup_indx = indx(valid_idx(img_count > 1));
    dup_idx = valid_idx(img_count > 1);
    if ~isempty(dup_indx)
        xx(dup_indx) = nan;
        yy(dup_indx) = nan;
        img_path_cell(dup_indx) = {''};
        if verbose
            fprintf(1, '\t\tWarning: misplaced mFoV detected. Trying to identify the correct mFoV number...\n');
        end
        % save the duplicated image information for now..
        dup_info.img_path = img_path(dup_idx);
        dup_info.x = img_x(dup_idx);
        dup_info.y = img_y(dup_idx);
        dup_info.mfov_id = mfov_id(dup_idx);
        dup_info.beam_id = beam_id(dup_idx);
        dup_info.act_mfov_id = nan(size(dup_info.mfov_id));
    end
end

