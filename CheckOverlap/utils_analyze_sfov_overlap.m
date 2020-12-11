function [status, sfov_coord, mfov_img, vec_alpha, vec_beta, cornerpts_info] = utils_analyze_sfov_overlap(sfov_vecs,sfov_confs,conf_thresh, imgsz)
    % status = 0 good overlap; 1 thin overlap(<150nm); 2 gaps; 3:failed
    % overlap
    status = 0;
    sfov_coord = nan(61,2);
    mfov_img = [];
    vec_alpha = nan(2,1);   % beam 1 -> beam 2
    vec_beta = nan(2,1);    % beam 1 -> beam 3
    cornerpts_info = struct;

    vec1s = sfov_vecs{1};
    vec2s = sfov_vecs{2};
    vec3s = sfov_vecs{3};
    conf1 = sfov_confs{1};
    conf2 = sfov_confs{2};
    conf3 = sfov_confs{3};

    [beam_coord, neighbor_pairs] = config_beam_coord_vectors;
    d1_idx = neighbor_pairs{1}; d1_idx0 = d1_idx;
    d2_idx = neighbor_pairs{2}; d2_idx0 = d2_idx;
    d3_idx = neighbor_pairs{3}; % d3_idx0 = d3_idx;
    beam_num = size(beam_coord,1);
    % conf_thresh1 = maxk([conf1(:);conf2(:);conf3(:)], round(1.5*size(d1_idx,1)));
    % conf_thresh = (conf_thresh1(end) + conf_thresh)/2;
    % remove all the entries that are not confident enough
    d1_idx(conf1 < conf_thresh,:) = [];
    d2_idx(conf2 < conf_thresh,:) = [];
    d3_idx(conf3 < conf_thresh,:) = [];
    vec1s(conf1 < conf_thresh,:) = [];
    vec2s(conf2 < conf_thresh,:) = [];
    vec3s(conf3 < conf_thresh,:) = [];
    conf1(conf1 < conf_thresh) = [];
    conf2(conf2 < conf_thresh) = [];
    conf3(conf3 < conf_thresh) = [];

    adj_sfovs = zeros(3, beam_num);
    adj_sfovs(1,d1_idx(:,1)) = d1_idx(:,2);
    adj_sfovs(2,d2_idx(:,1)) = d2_idx(:,2);
    adj_sfovs(3,d3_idx(:,1)) = d3_idx(:,2);

    adjacent_matrix = utils_recover_adjacent_matrix(adj_sfovs);
    % make sure all the sfovs are connected
    group_idx = utils_group_connected_mfovs(adjacent_matrix>0);
    % otherwise raise an error flag and return
    if max(group_idx) > 1
        status = 3;
        return;
    end

    % use weighted LLS to convert relative sfov positions into sfov_coord
    [direct,s1] = find(adj_sfovs>0);
    A = zeros(length(s1)+1,beam_num);
    b = zeros(length(s1)+1,2);
    conf = zeros(length(s1)+1,1);
    t1 = 1; t2 = 1; t3 = 1;
    for k = 1:length(s1)
        A(k,s1(k)) = -1;
        A(k,adj_sfovs(direct(k),s1(k))) = 1;
        switch direct(k)
        case 1
            b(k,:) = vec1s(t1,:);
            conf(k) = conf1(t1);
            t1 = t1+1;
        case 2
            b(k,:) = vec2s(t2,:);
            conf(k) = conf2(t2);
            t2 = t2 + 1;
        case 3
            b(k,:) = vec3s(t3,:);
            conf(k) = conf3(t3);
            t3 = t3 + 1;
        end
    end
    A(end,1) = 1;
    b(end) = 0;
    conf(end) = max(conf(:));
    sfov_coord = (diag(conf - conf_thresh+0.1)*A)\(diag(conf-conf_thresh+0.1)*b);

    vec_alphas = sfov_coord(d1_idx0(:,2),:) - sfov_coord(d1_idx0(:,1),:);
    vec_betas = sfov_coord(d2_idx0(:,2),:) - sfov_coord(d2_idx0(:,1),:);
    vec_alpha = median(vec_alphas, 1, 'omitnan')';
    vec_beta = median(vec_betas, 1, 'omitnan')';

    % generate the sfov overlap map
    imght = imgsz(1);
    imgwd = imgsz(2);
    sfov_coord_positive = round(sfov_coord - repmat(min(sfov_coord),size(sfov_coord,1),1));
    mfov_wd = max(sfov_coord_positive(:,1)) + imgwd + 2;
    horz_center = (mfov_wd+1)/2;
    mfov_ht = max(sfov_coord_positive(:,2)) + imght + 2;
    vert_center = (mfov_ht+1)/2;
    mfov_img = ones(mfov_ht,mfov_wd,'single');
    mfov_img1 = 0*mfov_img;

    bound_img = zeros(imght,imgwd,'single');
    bound_img([1,end],:) = 1;
    bound_img(:,[1,end]) = 1;
    [bound_y,bound_x] = find(bound_img);
    bound_theta = atan2(bound_y-(imght+1)/2,bound_x-(imgwd+1)/2);
    bound_img(~~bound_img) = bound_theta;

    for k = 1:size(sfov_coord_positive,1)
        mfov_img(sfov_coord_positive(k,2)+(1:imght)+1, sfov_coord_positive(k,1)+(1:imgwd)+1) = ...
        mfov_img(sfov_coord_positive(k,2)+(1:imght)+1, sfov_coord_positive(k,1)+(1:imgwd)+1)*0.5;
        mfov_img1(sfov_coord_positive(k,2)+(1:imght)+1, sfov_coord_positive(k,1)+(1:imgwd)+1) = ...
            +wrapTo2Pi(bound_img - atan2(-sfov_coord(k,2),-sfov_coord(k,1)))/(2*pi+0.1)-k;
    end

    % find the corner points of the mfovs for hexgon visualization
    mfov_imgt = min(mfov_img, 1-min(0.5,imfill(1 - mfov_img, 'holes')));
    concave_corners = (mfov_imgt<=0.25) & (imfilter(mfov_imgt==1, ones(3,3),0)>0) & (imfilter(mfov_imgt==0.5, ones(3,3),0)>0);
    convex_corners = (mfov_imgt==0.5) & ((imfilter(single(mfov_imgt==1), ones(3,3),1)==5)|(imfilter(single(mfov_imgt==1), ones(3,3),1)==4));
    [cc_y, cc_x] = find(concave_corners);
    [cv_y, cv_x] = find(convex_corners);
    corner_pts = [cc_x(:) - horz_center,cc_y(:) - vert_center;...
        cv_x(:) - horz_center,cv_y(:) - vert_center];
    concave_bool = [true(size(cc_x(:))); false(size(cv_x(:)))];
    corner_number = mfov_img1(sub2ind(size(mfov_img),corner_pts(:,2)+vert_center,corner_pts(:,1)+horz_center));
    [~, corner_order] = sort(corner_number);
    corner_pts = corner_pts(corner_order,:);
    concave_bool = concave_bool(corner_order);
    vec_gamma = vec_beta(:) - vec_alpha(:);
    % compute the inner product between the alpha, beta, gamma vectors and
    % the vertex vectors
    unit_vecs = [vec_alpha(:), vec_beta(:),vec_gamma(:),...
        -vec_alpha(:), -vec_beta(:),-vec_gamma(:)];
    unit_vecs = unit_vecs./repmat(vecnorm(unit_vecs),2,1);
    vec_dots = corner_pts * unit_vecs;
    % decide the direction of each vertex vector by looking at which are 
    % the two closest unit vectors among alpha, beta and gamma
    [~, sort_direct] = sort(vec_dots, 2, 'descend');
    % take square just to convert 2d into 1d conveniently
    max_direct = sum(sort_direct(:,1:2).^2,2);
    corner_direct = nan(size(concave_bool));
    % 5 = 2^2 + 1^2; between e1 and e2
    corner_direct(max_direct == 5) = 3;
    % 13 = 2^2 + 3^2; between e2 and e3
    corner_direct(max_direct == 13) = 2;
    % 25 = 3^2 + 4^2; between e3 and e4
    corner_direct(max_direct == 25) = 1;
    % 41 = 4^2 + 5^2; between e4 and e5
    corner_direct(max_direct == 41) = 4;
    % 61 = 5^2 + 6^2; between e5 and e6
    corner_direct(max_direct == 61) = 5;
    % 37 = 6^2 + 1^2; between e6 and e1
    corner_direct(max_direct == 37) = 6;
    cornerpts_info.corner_pts = corner_pts;
    cornerpts_info.concave_bool = concave_bool;
    cornerpts_info.corner_direct = corner_direct;

    min_x_overlap = -max(abs(vec_alphas(:,1))) + imgsz(2);
    min_y_overlap = -max(max(abs(vec_betas(:,2))),max(abs(vec_betas(:,2)-vec_alphas(:,2)))) + imgsz(1);
    if (min_x_overlap < 0) || (min_y_overlap<0)
        status = 2;
    elseif (min_x_overlap < 2.5) || (min_y_overlap<2.5)
        status = 1;
    end
end
