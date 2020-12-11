function sfov_idx = utils_select_sfov_for_jitter_detection(mfovstack, sfov_idxs, pertail)
    if nargin < 3
        pertail = 0.6;
    end
    if nargin < 2
        sfov_idxs = 1:size(mfovstack,3);
    end
    imgstds = (single(reshape(mfovstack(1:round(size(mfovstack,1)/4),:,:,:),round(size(mfovstack,1)/4)*size(mfovstack,2),size(mfovstack,3))));
    imgstds = nanmean(maxk(imgstds,20))-nanmean(mink(imgstds,20));
    [~,idx] = min(abs(imgstds(:)-quantile(imgstds(:),pertail)));
    sfov_idx = sfov_idxs(idx);
end