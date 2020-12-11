function [indexpairs, metrics, dtheta] = utils_align_radon_features(Mdist, Mtheta, Ntheta)
    Mtheta = single(Mtheta);
    
    [~,dimlg] = max([size(Mdist,1),size(Mdist,2)]);
    if dimlg == 1
        Mdist = Mdist';
        Mtheta = Mtheta';
    end
    [~, idx1] = min(Mdist);
    indx = sub2ind(size(Mdist),idx1,1:length(idx1));
    [thetaidx, thetaF] = mode(Mtheta(indx));
    dtheta = wrapToPi((thetaidx-1)*pi/Ntheta);
    Mdist = Mdist.*(1+abs(Mtheta-thetaidx-2*Ntheta*round((Mtheta-thetaidx)/(2*Ntheta)))).^(2*thetaF/length(indx));
    [mindis, idx1] = min(Mdist);
    idx1 = idx1(:)';
    
    [mindis, sidx] = sort(mindis(:));
    sidx = sidx(:);
    idx1 = idx1(sidx);
%     idx2 = sidx;
    [idx1,ia] = unique(idx1);
    mindis = mindis(ia);
    idx2 = sidx(ia);
    if dimlg == 1
        indexpairs = [idx2(:),idx1(:)];
    else
        indexpairs = [idx1(:),idx2(:)];
    end
    Mdist(sub2ind(size(Mdist),idx1(:),idx2(:))) = nan;
    mink1 = min(Mdist)';
    mink2 = min(Mdist,[],2);
    metric1 = mink1(idx2(:))./mindis;
    metric2 = mink2(idx1(:))./mindis;
    metrics = min(metric1,metric2);
end