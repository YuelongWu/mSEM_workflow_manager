function [A,conflvl] = utils_ransac_get_transformation_matrix(xy1,xy2,indexpairs,metrics, deformconstraint, Niter)
    if nargin < 6
        Niter = 100;
        if nargin <5
            deformconstraint = false;
        end
    end
    maxiter = size(indexpairs,1)*Niter; % maximum number of iteration
    disthresh = 4; % threshold for error in pixel
    % sample the indexpairs based on the metrics numbers
    sample_prob = cumsum(metrics);
    sample_prob = sample_prob/max(sample_prob(:));
   
    conflvl = 0;
    xy1 = [xy1, ones(size(xy1,1),1)];
    xy2 = [xy2, ones(size(xy2,1),1)];
    Npairs = size(indexpairs,1);
    warning('off','MATLAB:singularMatrix');
    warning('off','MATLAB:nearlySingularMatrix');
    A = nan(3);
    fit_idx1 = [];
    for k = 1:maxiter
        idxs = local_randomly_sample_indx(sample_prob,3);
        A0 = xy2(indexpairs(idxs,2),:)\xy1(indexpairs(idxs,1),:);
        diserr = xy2(indexpairs(:,2),:)*A0 - xy1(indexpairs(:,1),:);
        fit_idx = (sum(diserr.^2,2).^0.5) < disthresh;
        conf1 = sum(fit_idx)/Npairs;
        if conf1>conflvl
            if deformconstraint
                 [~,S,~] = svd(A0(1:2,1:2));
                if (S(1)*S(4)>0) && (abs(log(S(1)*S(4)))< 0.2) && (abs(log(S(1)/S(4)))<0.2)
                    conflvl = conf1;
                    fit_idx1 = fit_idx;
                end
            else
                conflvl = conf1;
                fit_idx1 = fit_idx;
            end
            % A = A0;
        end
        if conf1 > 0.75
            break;
        end
    end
    if isempty(fit_idx1)
        return;
    end
    A = xy2(indexpairs(fit_idx1,2),:)\xy1(indexpairs(fit_idx1,1),:);
    A(:,end) = [0;0;1];
end

function idxs = local_randomly_sample_indx(sample_prob,N)
    randnum = rand(N,1);
    idxs = zeros(N,1);
    for k = 1:N
        t = find(sample_prob>=randnum(k),1,'first');
        if any(idxs == t)
            if t>1
                t = t-1;
            elseif t<length(sample_prob)
                t = t+1;
            end
        end
        idxs(k) = t;
    end
end