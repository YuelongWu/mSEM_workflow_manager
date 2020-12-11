function [route_mfov_idx, mfov_num_in_RAM, adjacent_mfovs, d, hex_coords] = utils_plan_overlap_check_route(mfov_x,mfov_y, vec_alpha, vec_beta)
    % Plan the mFoV read-in order to simutanously optimize speed and RAM usage.
    % Basic idea similar to the scanline flood fill algorithm.
    
    % Yuelong Wu, May 2018
    
    % find the adjacency relationship
    d_0per = norm(5*vec_beta + 4*vec_alpha);
    Nmfov = length(mfov_x(:));
    pdis_x = repmat(mfov_x(:),1,Nmfov); 
    pdis_x = pdis_x - pdis_x';
    pdis_y = repmat(mfov_y(:),1,Nmfov);
    pdis_y = pdis_y - pdis_y';
    pdis_eucld = (pdis_x.^2 + pdis_y.^2).^0.5;
    d_est = quantile(pdis_eucld(~eye(size(pdis_eucld))),0.5/Nmfov);
    d_est = min(d_est,d_0per);
    adjacent_matrix = (pdis_eucld < (1.366 * d_est))&(pdis_eucld > (0.5 * d_est));
    adj_matrix_with_direct = zeros(size(adjacent_matrix),'single');
    dx_adj = pdis_x(adjacent_matrix); dy_adj = pdis_y(adjacent_matrix);
    theta_60deg = 3.5+(round(atan(dx_adj./dy_adj)/(pi/3))+1.5).*sign(dy_adj);
    adj_matrix_with_direct(adjacent_matrix) = theta_60deg;
    d = nan(6,2);
    adjacent_mfovs = nan(6, Nmfov, 'single');
    for k = 1:3
        directional_adj_matrix = (adj_matrix_with_direct == k);
        d(k,1) = median(pdis_x(directional_adj_matrix),'omitnan');
        d(k,2) = median(pdis_y(directional_adj_matrix),'omitnan');
        d(7-k,1) = - d(k,1);
        d(7-k,2) = - d(k,2);
        
        [rowidx, colidx] = find(directional_adj_matrix);
        adjacent_mfovs(k,colidx) = rowidx;
        adjacent_mfovs(7-k,rowidx) = colidx;
    end
    if any(isnan(d))
        d_default = [-1.179967  -0.767658;0.087516  -1.37391;1.267483  -0.606252];% Zen update %3 overlap
        d_default = [d_default; -d_default];
        d(isnan(d)) = d_default(isnan(d));
    end
    % plan the processing route
    dis_xy = (mfov_x - nanmean(mfov_x(:))).^2 + (mfov_y - nanmean(mfov_y(:))).^2;
    [~, midx] = min(dis_xy);
    mfov_x = mfov_x - mfov_x(midx);
    mfov_y = mfov_y - mfov_y(midx);
    vec_ortho = nan(3,2);
    vec_ortho(1,:) = 0.5*(d(2,:) + d(3,:));
    vec_ortho(2,:) = 0.5*(d(3,:) + d(6,:));
    vec_ortho(3,:) = 0.5*(d(5,:) + d(6,:));
    hex_coord = round(([mfov_x(:),mfov_y(:)]*(vec_ortho'))*diag(diag(1./(vec_ortho*vec_ortho'))));
    hex_coord(isnan(hex_coord)) = 0;
    [c1,~] = histcounts(hex_coord(:,1), (min(hex_coord(:,1))-0.5):1:(max(hex_coord(:,1))+0.5));
    [c2,~] = histcounts(hex_coord(:,2), (min(hex_coord(:,2))-0.5):1:(max(hex_coord(:,2))+0.5));
    [c3,~] = histcounts(hex_coord(:,3), (min(hex_coord(:,3))-0.5):1:(max(hex_coord(:,3))+0.5));
    [mfov_num_in_RAM, major_direct_idx] = min([max(c1),max(c2),max(c3)]+3);
    minor_direct_idx = mod(major_direct_idx,3) + 1;
    [~,idx1] = sort(hex_coord(:,minor_direct_idx));
    [~,idx2] = sort(hex_coord(idx1,major_direct_idx));
    route_mfov_idx = idx1(idx2);
    hex_coords = hex_coord(:,[major_direct_idx,minor_direct_idx]);
%     % find the longest path in the adjacency undirected graph
%     dp1 = pdist(hex_coord(:,[2,3]),'cityblock');
%     dp2 = pdist(hex_coord(:,[1,3]),'cityblock');
%     dp3 = pdist(hex_coord(:,[1,3]),'cityblock');
%     longest_path = min([max(dp1),max(dp2),max(dp3)]);
end