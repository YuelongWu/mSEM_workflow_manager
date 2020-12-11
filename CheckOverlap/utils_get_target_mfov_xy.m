function [mfov_x, mfov_y] = utils_get_target_mfov_xy(sfov_x,sfov_y,vec_alpha,vec_beta,beam_coord)
    if nargin < 5
        beam_coord = config_beam_coord_vectors;
    end
    sfov_offset_x = beam_coord(:,1) * vec_alpha(1) +  beam_coord(:,2) * vec_beta(1);
    sfov_offset_y = beam_coord(:,1) * vec_alpha(2) +  beam_coord(:,2) * vec_beta(2);
    Nmfov = size(sfov_x, 2);
    mfov_x = median(sfov_x - repmat(sfov_offset_x,1,Nmfov),'omitnan');
    mfov_y = median(sfov_y - repmat(sfov_offset_y,1,Nmfov),'omitnan');
end