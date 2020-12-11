function [mfov_id, beam_id] = utils_parse_fullres_image_name(img_path)
    % given the string cell of image path, return section, mFoV and beam IDs
    outcell = utils_textscan(img_path, '%*s%f32%f32%*s', '_');
    mfov_id = outcell{1};
    beam_id = outcell{2};
end