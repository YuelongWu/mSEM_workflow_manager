function bb_bool = utils_detect_bad_beam(IMQA)
    QAqt = quantile(IMQA,[0.25,0.5,0.75],1);
    LowerBound = QAqt(1,:) - (QAqt(2,:)-QAqt(1,:));
    UpperBound = QAqt(3,:) + (QAqt(3,:)-QAqt(2,:));
    QAoutlier = (IMQA>repmat(UpperBound,size(IMQA,1),1)) | (IMQA<repmat(LowerBound,size(IMQA,1),1));
    IMQA(QAoutlier) = nan;
    b_std = min(nanstd(IMQA)/0.6745,7.5);
    b_mean = nanmean(IMQA);
    bsline = median(b_mean,'omitnan');
    eff_sz = (b_mean - bsline)./b_std;
    bb_bool = eff_sz < -0.7;
end