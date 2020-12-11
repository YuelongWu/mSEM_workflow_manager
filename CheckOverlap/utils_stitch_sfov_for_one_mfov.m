function [vecs, confs] = utils_stitch_sfov_for_one_mfov(sfov_stack, vec_alpha, vec_beta)
    % stitch the sFoVs within one mfov. the sfov_stack has the background
    % removed already. return the alpha and beta vectors, also the
    % confidence level.
    sfov_stack = single(sfov_stack);
    sfov_stack = sfov_stack - mean(mean(sfov_stack));

    [~, neighbor_pairs] = config_beam_coord_vectors;
    d1_idx = neighbor_pairs{1};
    d2_idx = neighbor_pairs{2};
    d3_idx = neighbor_pairs{3};

    imght = size(sfov_stack,1);
    imgwd = size(sfov_stack,2);
    scf = ((imght*imgwd)/(196*170)).^0.5;
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

    supp_sz = ceil(3*scf);
    sfov_stack1 = sfov_stack(:,(end-sample_wd+1):end, d1_idx(:,1));
    sfov_stack2 = sfov_stack(:,1:sample_wd,d1_idx(:,2));
    [displacement1, conf1] = utils_estimate_displacement_fft2(sfov_stack1.*repmat(mask1,1,1,size(sfov_stack1,3)),...
        sfov_stack2.*repmat(mask6,1,1,size(sfov_stack2,3)), tgt_dx1, tgt_dy1, supp_sz, scf);

    sfov_stack1 = sfov_stack(1:sample_ht,:,d2_idx(:,1));
    sfov_stack2 = sfov_stack((end-sample_ht+1):end,:,d2_idx(:,2));
    [displacement2, conf2] = utils_estimate_displacement_fft2(sfov_stack1.*repmat(mask2,1,1,size(sfov_stack1,3)),...
        sfov_stack2.*repmat(mask5,1,1,size(sfov_stack2,3)), tgt_dx2, tgt_dy2, supp_sz, scf);

    sfov_stack1 = sfov_stack(1:sample_ht,:,d3_idx(:,1));
    sfov_stack2 = sfov_stack((end-sample_ht+1):end,:,d3_idx(:,2));
    [displacement3, conf3] = utils_estimate_displacement_fft2(sfov_stack1.*repmat(mask3,1,1,size(sfov_stack1,3)),...
        sfov_stack2.*repmat(mask4,1,1,size(sfov_stack2,3)), tgt_dx3, tgt_dy3, supp_sz, scf);

    vec1 = displacement1;
    vec1(:,1) = vec1(:,1) + sign(vec_alpha(1))*(imgwd - sample_wd);
    vec2 = displacement2;
    vec2(:,2) = vec2(:,2) + sign(vec_beta(2))*(imght - sample_ht);
    vec3 = displacement3;
    vec3(:,2) = vec3(:,2) + sign(vec_beta(2)-vec_alpha(2))*(imght - sample_ht);
    vecs = cell(3,1);
    confs = cell(3,1);
    vecs{1} = vec1; vecs{2} = vec2; vecs{3} = vec3;
    confs{1} = conf1; confs{2} = conf2; confs{3} = conf3;
end
