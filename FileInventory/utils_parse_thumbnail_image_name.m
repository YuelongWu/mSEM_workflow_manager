function [mfov_id, beam_id] = utils_parse_thumbnail_image_name(thumb_path)
    % given the string cell of thumbnail image path, return section, mFoV and beam IDs
    outcell = utils_textscan(thumb_path, '%*s%*s%f32%f32%*s', '_');
    mfov_id = outcell{1};
    beam_id = outcell{2};
end