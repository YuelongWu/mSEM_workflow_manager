function [status, sfov_coord, mfov_img, cornerpts_info] = utils_analyze_sfov_overlap_old(vec_alpha, vec_beta, imght, imgwd)
    % status = 0 good overlap; 1 thin overlap(<150nm); 2 gaps
    try
    beam_coord = config_beam_coord_vectors;
    sfov_coord = beam_coord*[vec_alpha(:)';vec_beta(:)'];
    overlap_wd = [imgwd - abs(vec_alpha(1)); imght - abs(vec_beta(2)); imght - abs(vec_beta(2)-vec_alpha(2))];
    if min(overlap_wd) < 0 || isnan(min(overlap_wd))
        status = 2;
    elseif min(overlap_wd) < 2.5
        status = 1;
    else
        status = 0;
    end
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
    concave_corners = (mfov_img<=0.25) & (imfilter(mfov_img==1, ones(3,3))>0) & (imfilter(mfov_img==0.5, ones(3,3))>0);
    convex_corners = (mfov_img==0.5) & (imfilter(single(mfov_img==1), ones(3,3))==5);
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
    unit_vecs = [vec_alpha(:), vec_beta(:),vec_gamma(:),...
        -vec_alpha(:), -vec_beta(:),-vec_gamma(:)];
    unit_vecs = unit_vecs./repmat(vecnorm(unit_vecs),2,1);
    vec_dots = corner_pts * unit_vecs;
    [~, sort_direct] = sort(vec_dots, 2, 'descend');
    max_direct = sum(sort_direct(:,1:2).^2,2);
    corner_direct = nan(size(concave_bool));
    corner_direct(max_direct == 5) = 3;
    corner_direct(max_direct == 13) = 2;
    corner_direct(max_direct == 25) = 1;
    corner_direct(max_direct == 41) = 4;
    corner_direct(max_direct == 61) = 5;
    corner_direct(max_direct == 37) = 6;
    cornerpts_info.corner_pts = corner_pts;
    cornerpts_info.concave_bool = concave_bool;
    cornerpts_info.corner_direct = corner_direct;
    catch
        status = 3;
        cornerpts_info = struct;
        mfov_img = 0;
    end
end
