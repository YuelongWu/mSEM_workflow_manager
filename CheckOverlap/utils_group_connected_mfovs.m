function group_idx = utils_group_connected_mfovs(adjacent_matrix)
    Nmfov = size(adjacent_matrix,2);
    adjacent_matrix = double(adjacent_matrix | eye(size(adjacent_matrix)));
    % max_eig = max(abs(eig(adjacent_matrix)));
    max_eig = 6; % greatest eigen value bounded by maximum degree
    p_init = min([Nmfov, floor(log(2^51/Nmfov)/log(max_eig))]); % make sure numerically stable
    A0 = (adjacent_matrix^p_init)>0.5;
    A1 = (A0^2)>0.5;
    while any(A0(:)~=A1(:))
        A0 = A1;
        A1 = (A1^2)>0.5;
    end
    group_idx = zeros(Nmfov,1);
    gid = 1;
    while any(group_idx == 0)
        m_idx = find(group_idx==0,1);
        group_idx(A1(m_idx,:)) = gid;
        gid = gid+1;
    end
    % sort on group size
    N = histcounts(group_idx, 0.5:1:max(group_idx+0.5));
    [~, idx] = sort(N,'descend');
    group_idx = idx(group_idx);
end