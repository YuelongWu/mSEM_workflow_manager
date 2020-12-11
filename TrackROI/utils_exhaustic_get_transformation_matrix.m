function [A,conflvl,indexpairs] = utils_exhaustic_get_transformation_matrix(XY1,XY2,indexpairs,metrics,deformconstraint,Niter)
    warning('off','MATLAB:singularMatrix');
    warning('off','MATLAB:nearlySingularMatrix');
    Npairs = size(indexpairs,1);
    if nargin < 6
        Niter = min(100,Npairs);
        if nargin <5
            deformconstraint = false;
        end
    end
    Niter = min(Niter, Npairs);
    disthresh = 5; % threshold for error in pixel
    exitthresh = 0.8; 
    [~, sidx] = sort(metrics,'descend','MissingPlacement','last');
    XY1 = [XY1(indexpairs(sidx,1),:), ones(Npairs,1)];
    XY2 = [XY2(indexpairs(sidx,2),:), ones(Npairs,1)];
    indexpairs = indexpairs(sidx,:);
    idx_addition = [1, 1, 1;0, 0, 1;0, 0, 2;0, 1, 1;0, 0, 3;0, 1, 2];
    idx0 = [1,2,3];
    idx1 = idx0;
    
    conflvl = 0;
    inlieridx = [];
    A = nan(3);
    for k = 1:(Niter*(Niter-1)*(Niter-2)/6 + 4)
        if max(idx1) > Npairs
            continue
        end
        A0 = XY2(idx1,:)\XY1(idx1,:);
        diserr = XY2*A0 - XY1;
        inlieridx0 = (sum(diserr.^2,2).^0.5) < disthresh;
        conf0 = sum(inlieridx0(:))/Npairs;
        if conf0 > conflvl
            if deformconstraint
                [~,S,~] = svd(A0(1:2,1:2));
                if (S(1)*S(4)>0) && (abs(log(S(1)*S(4)))< 0.4) && (abs(log(S(1)/S(4)))<0.4)
                    conflvl = conf0;
                    inlieridx = inlieridx0;
                end
            else
                conflvl = conf0;
                inlieridx = inlieridx0;
            end
        end
        if conflvl > exitthresh
            break;
        end
        idx1 = idx0 + idx_addition(mod(k,6)+1,:);
        if mod(k,6) == 0
            idx0 = idx1;
        end
    end
    if isempty(inlieridx)
        return;
    end
    A = XY2(inlieridx,:)\XY1(inlieridx,:);
    A(:,end) = [0;0;1];
    indexpairs = indexpairs(inlieridx,:);
end