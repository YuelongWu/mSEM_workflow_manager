function [jitter_amp, jitter_time] = utils_detect_stage_jitter(img_dir)
    jitter_amp = nan;
    jitter_time = nan;
    try
        wd = 5;
        Ndiv = 1;
        img0 = single(utils_read_partial_bmp(img_dir, [1,800]));
        img0 = img0 - repmat(mean(img0,2),1,size(img0,2));
        jitter_amps = nan(Ndiv,1);
        jitter_times = nan(Ndiv,1);
        szimg = size(img0,2);
        szpts = [1,round(szimg*(1:(Ndiv-1))/Ndiv),szimg];
        for k = 1:Ndiv
            img = img0(:,szpts(k):szpts(k+1));
            curv = sum(abs(img-imfilter(img,ones(wd,1)/wd,'symmetric')),2)-sum(abs(img-imfilter(img,ones(1,wd)/wd,'symmetric')),2);
            curv = medfilt1(curv(:),20);
            med = mean(curv(end-round(length(curv)/2):(end-2*wd)));
            mx = max(curv(wd:(10*wd)));
            jitter_times(k) = sum(curv - med)/(mx-med);
            if (jitter_times(k) <= 0) || (mx <= med)
                jitter_amps(k) = 0;
                jitter_times(k) = 0;
            else
                jitter_residue = curv(2*wd:(800-2*wd)) - med-(mx-med)*exp(-((2*wd):(800-2*wd))'/jitter_times(k));
                jitter_amps(k) = nanstd(curv(2*wd:(800-2*wd)))/nanstd(jitter_residue);
            end
        end
        jitter_amp = median(jitter_amps,'omitnan');
        jitter_time = median(jitter_times,'omitnan');
    catch
    end
end