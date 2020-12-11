function [vec_alpha,vec_beta,conf] = utils_stitch_sfov_for_one_mfov_old(sfov_stack, vec_alpha, vec_beta)
    % stitch the sFoVs within one mfov. the sfov_stack has the background
    % removed already. return the alpha and beta vectors, also the
    % confidence level.
    sfov_stack = imfilter(single(sfov_stack),fspecial('log'),'symmetric');
    d1_idx = [2,8,9,3,1,7,19,20,21,22,10,11,4,5,6,17,18,36,37,38,...
        39,40,41,23,24,25,12,13,14,15,16,33,34,35,59,60,61,nan,nan,nan,...
        nan,nan,42,43,44,45,26,27,28,29,30,31,32,55,56,57,58,nan,nan,nan,nan];
    d2_idx = [3,9,10,11,4,1,2,21,22,23,24,25,12,13,5,6,7,19,8,39,...
        40,41,42,43,44,45,26,27,28,14,15,16,17,18,36,37,20,nan,nan,nan,...
        nan,nan,nan,nan,nan,nan,46,47,48,49,29,30,31,32,33,34,35,59,60,61,38];
    d3_idx = [4,3,11,12,13,5,1,9,10,24,25,26,27,28,14,15,6,7,2,21,...
        22,23,43,44,45,46,47,48,49,29,30,31,16,17,18,19,8,39,40,41,...
        42,nan,nan,nan,nan,nan,nan,nan,nan,nan,50,51,52,53,32,33,34,35,36,37,20];
    
    imght = size(sfov_stack,1);
    imgwd = size(sfov_stack,2);
    
    sfov_ovlap_horz = max(round(imgwd - abs(vec_alpha(1))),1);
    sfov_ovlap_vert = max(round(imght - abs(vec_beta(2))),1);
    sfov_ovlap_vert2 = max(round(imght - abs(vec_beta(2)-vec_alpha(2))),1);
    
    sample_wd = min(4*sfov_ovlap_horz,imgwd);
    sample_ht = min(4*max(sfov_ovlap_vert,sfov_ovlap_vert2),imght);
    mask1 = false(imght,sample_wd);
    mask6 = mask1;
    mask1(:,(end-2*sfov_ovlap_horz+1):end) = 1;
    mask6(:,1:(2*sfov_ovlap_horz)) = 1;
    mask2 = false(sample_ht,imgwd);
    mask3 = mask2; mask4 = mask2; mask5 = mask2;
    mask2(1:(2*sfov_ovlap_vert),floor(imgwd/2):end) = 1;
    mask5((end-2*sfov_ovlap_vert+1):end,1:ceil(imgwd/2)) = 1;
    mask3(1:(2*sfov_ovlap_vert2),1:ceil(imgwd/2)) = 1;
    mask4((end-2*sfov_ovlap_vert2+1):end,floor(imgwd/2):end) = 1;
    
    tgt_dx1 = sign(vec_alpha(1))*(sample_wd - sfov_ovlap_horz);
    tgt_dy1 = round(vec_alpha(2));
    tgt_dx2 = round(vec_beta(1));
    tgt_dy2 = sign(vec_beta(2))*(sample_ht - sfov_ovlap_vert);
    tgt_dx3 = round(vec_beta(1) - vec_alpha(1));
    tgt_dy3 = sign(vec_beta(2)-vec_alpha(2))*(sample_ht - sfov_ovlap_vert2);
    
    supp_sz = 3;
    sfov_stack1 = sfov_stack(:,(end-sample_wd+1):end,~isnan(d1_idx));
    sfov_stack2 = sfov_stack(:,1:sample_wd,d1_idx(~isnan(d1_idx)));
    [displacement1, conf1] = utils_estimate_displacement_fft2(sfov_stack1.*repmat(mask1,1,1,size(sfov_stack1,3)),...
        sfov_stack2.*repmat(mask6,1,1,size(sfov_stack2,3)), tgt_dx1, tgt_dy1, supp_sz);
    
    sfov_stack1 = sfov_stack(1:sample_ht,:,~isnan(d2_idx));
    sfov_stack2 = sfov_stack((end-sample_ht+1):end,:,d2_idx(~isnan(d2_idx)));
    [displacement2, conf2] = utils_estimate_displacement_fft2(sfov_stack1.*repmat(mask2,1,1,size(sfov_stack1,3)),...
        sfov_stack2.*repmat(mask5,1,1,size(sfov_stack2,3)), tgt_dx2, tgt_dy2, supp_sz);
    
    sfov_stack1 = sfov_stack(1:sample_ht,:,~isnan(d3_idx));
    sfov_stack2 = sfov_stack((end-sample_ht+1):end,:,d3_idx(~isnan(d3_idx)));
    [displacement3, conf3] = utils_estimate_displacement_fft2(sfov_stack1.*repmat(mask3,1,1,size(sfov_stack1,3)),...
        sfov_stack2.*repmat(mask4,1,1,size(sfov_stack2,3)), tgt_dx3, tgt_dy3, supp_sz);
    
    vec1 = displacement1;
    vec1(:,1) = vec1(:,1) + sign(vec_alpha(1))*(imgwd - sample_wd);
    vec2 = displacement2;
    vec2(:,2) = vec2(:,2) + sign(vec_beta(2))*(imght - sample_ht);
    vec3 = displacement3;
    vec3(:,2) = vec3(:,2) + sign(vec_beta(2)-vec_alpha(2))*(imght - sample_ht);
    vec_alphas = zeros(2,2);
    vec_betas = zeros(2,2);
    vec_alphas(1,:) = sum(vec1.*(conf1-1).^2)/sum((conf1-1).^2);
    conf_alpha1 = sum(conf1.*(conf1-1).^2)/sum((conf1-1).^2);
    vec_alphas(2,:) = sum((vec2-vec3).*(min(conf2,conf3)-1).^2)/sum((min(conf2,conf3)-1).^2);
    conf_alpha2 = sum(min(conf2,conf3).*(min(conf2,conf3)-1).^2)/sum((min(conf2,conf3)-1).^2);
    vec_betas(1,:) = sum(vec2.*(conf2-1).^2)/sum((conf2-1).^2);
    conf_beta1 = sum(conf2.*(conf2-1).^2)/sum((conf2-1).^2);
    vec_betas(2,:) = sum((vec1+vec3).*(min(conf1,conf3)-1).^2)/sum((min(conf1,conf3)-1).^2);
    conf_beta2 = sum(min(conf1,conf3).*(min(conf1,conf3)-1).^2)/sum((min(conf1,conf3)-1).^2);
    [conf_alpha, tidx] = max([conf_alpha1,conf_alpha2]);
    vec_alpha = vec_alphas(tidx,:)';
    [conf_beta, tidx] = max([conf_beta1,conf_beta2]);
    vec_beta = vec_betas(tidx,:)';
    conf = [conf_alpha,conf_beta];
end