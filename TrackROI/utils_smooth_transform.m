function correct_matrix = utils_smooth_transform(As, success)
    wd = 300;
    threshlvl = 2e-4;
    
    N = size(As,3);
    correct_matrix = repmat(eye(3),1,1,N);
    for k = 1:N
        if success(k)
            A = As(:,:,k);
            [~,S,V] = svd(A(1:2,1:2));
            correct_matrix(1:2,1:2,k) = V*diag(1./diag(S))*V';
        end
    end
    correct_matrix = imfilter(correct_matrix,ones(1,1,wd)/wd,'symmetric');
    diffc = diff(correct_matrix,1,3);
    diffc = min(max(diffc,-threshlvl),threshlvl);
    correct_matrix = cumsum(cat(3,correct_matrix(:,:,1),diffc),3);
end