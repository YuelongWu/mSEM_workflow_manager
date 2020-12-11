function mm = utils_weighted_median(A, wt, dim, qt)
    % return weighted median of a matrix along one axis.
    % the weights are defined element-wise
    if nargin < 4
        qt = 0.5;
        if nargin < 3
            dim = 1;
        end
    end
    if size(A,dim) == 1
        mm = A;
        return
    end
    if nanstd(wt(:)) == 0 && max(wt(:) > 0)
        mm = median(A, dim, 'omitnan');
        return
    end
    if sum(size(wt)>1)==1 && size(A,dim) == length(wt(:))
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
    elseif length(A(:)) == length(wt(:))
        % use complex number to bind A with weights when sorting
        % stupid MATALAB...
        A = complex(A, reshape(wt, size(A)));
        A = sort(A, dim,'ComparisonMethod','real');
        WT = imag(A);
        A = real(A);
        WT(isnan(A)) = 0;
        % cumulatively add weight to see when the defined percentile is reached
        CWT = cumsum(WT,dim,'omitnan') - qt*sum(WT,dim,'omitnan');
        CWT(CWT<0) = nan;
        % find the place closest to the percentile
        SEL = CWT == min(CWT,[],dim);
        A(~SEL) = nan;
        % make sure 0 weight not selected
        A(WT == 0) = nan;
        mm = nanmean(A,dim);
    else
        error('utils_weighted_median_elem: dimension mismatch');
    end
end
