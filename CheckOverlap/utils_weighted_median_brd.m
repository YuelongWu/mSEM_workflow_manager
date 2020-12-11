function mm = utils_weighted_median_brd(A, wt, dim)
    % return weighte median of a matrix along one axis.
    if nargin < 3
        dim = 1;
    end
    if nanstd(wt) == 0 && max(wt(:) > 0)
        mm = median(A, dim, 'omitnan');
        return
    end
    if size(A,dim) ~= length(wt(:))
        error('utils_weighted_median: dimension mismatch');
    end
    [Asrt, Isrt] = sort(A, dim);
    WT = wt(Isrt);
    WT(isnan(Asrt)) = 0;
    Asrt(WT == 0) = nan;
    WTsum = sum(WT, dim);
    WT = cumsum(WT, dim) - WTsum/2;
    WT(WT<0) = nan;
    mn = min(WT, [], dim);
    Asrt(WT ~= mn) = nan;
    mm = nanmean(Asrt,dim);
end