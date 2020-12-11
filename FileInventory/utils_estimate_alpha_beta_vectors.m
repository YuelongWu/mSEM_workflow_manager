function [vec_alpha, vec_beta] = utils_estimate_alpha_beta_vectors(xx, yy, beam_coord)
    if nargin < 3
        beam_coord = config_beam_coord_vectors;
    end
    v1_dif = repmat(beam_coord(:,1), 1, size(xx,1));
    v1_dif = v1_dif - v1_dif';
    v2_dif = repmat(beam_coord(:,2), 1, size(xx,1));
    v2_dif = v2_dif - v2_dif';
    
    v1_dift = -1*((v1_dif == 1) & (v2_dif == 0)) + eye(size(v1_dif));
    v1_dif_mat = v1_dift(sum(v1_dift,2)== 0, :);
    vec_alpha_mat_x = v1_dif_mat * xx;
    vec_alpha_mat_y = v1_dif_mat * yy;
    vec_alpha = [median(vec_alpha_mat_x(:),'omitnan'); median(vec_alpha_mat_y(:),'omitnan')];
    
    
    
    v2_dift = -1*((v2_dif == 1) & (v1_dif == 0)) + eye(size(v2_dif));
    v2_dif_mat = v2_dift(sum(v2_dift,2)== 0,:);
    vec_beta_mat_x = v2_dif_mat * xx;
    vec_beta_mat_y = v2_dif_mat * yy;
    vec_beta = [median(vec_beta_mat_x(:),'omitnan'); median(vec_beta_mat_y(:),'omitnan')];
end