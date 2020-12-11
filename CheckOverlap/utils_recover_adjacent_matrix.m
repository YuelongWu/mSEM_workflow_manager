function adjacent_matrix = utils_recover_adjacent_matrix(adjacent_mfovs)
    Nmfov = size(adjacent_mfovs,2);
    adjacent_matrix = zeros(Nmfov,Nmfov,'single');
    for k = 1:size(adjacent_mfovs,1)
        m2 = find((adjacent_mfovs(k,:))>0);
        m1 = adjacent_mfovs(k,m2);
        indx1 = sub2ind(size(adjacent_matrix), m1, m2);
        indx2 = sub2ind(size(adjacent_matrix), m2, m1);
        adjacent_matrix(indx1) = k;
        adjacent_matrix(indx2) = 7-k;
    end
end