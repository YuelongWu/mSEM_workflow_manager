function [mfov_img, cornerpts_info] = utils_analyze_sfov_overlap_sfovcoord(sfov_coord, imgsz, vec_alpha, vec_beta)
    % status = 0 good overlap; 1 thin overlap(<150nm); 2 gaps; 3:failed
    % overlap
    cornerpts_info = struct;

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
    concave_corners = (mfov_img<=0.25) & (imfilter(mfov_img==1, ones(3,3),0)>0) & (imfilter(mfov_img==0.5, ones(3,3),0)>0);
    convex_corners = (mfov_img==0.5) & ((imfilter(single(mfov_img==1), ones(3,3),1)==5)|(imfilter(single(mfov_img==1), ones(3,3),1)==4));
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
end
