function [check_result, status, err_imgs] = utils_full_res_check(section_dir,imgpath,sfov_coord,fullres_sz,doScanFaultCheck, thres)
    scanfault_thresh = thres.scanfault_thresh; % threshold for detecting scanfault
    jitter_thresh = thres.jitter_thresh; % threshold for detecting jitter
    skew_thresh = thres.skew_thresh; % threshold for detecting skew
    
    margin_tol = 48;
    % status: 3-coordinate error; 2-reading error; 1-computational error; 0-normal.
    check_result = struct;
    check_result.jitter_amp = nan;
    check_result.jitter_freq = nan;
    check_result.top_distort_amp = nan;
    check_result.top_distort_length = nan;

    check_result.scanfault = nan;
    check_result.scanfault_pos = nan;
    check_result.displacement = [nan,nan];
    err_imgs = struct;
    err_imgs.scanfault = [];
    err_imgs.top_err =[];
    
    try
        d_sfov = diff(sfov_coord,1,1); % relative positions of the two sfovs
        ovlp_wd0 = round(fullres_sz(1)-abs(d_sfov(2)));  % overlap width
        ovlp_wd = ovlp_wd0 + margin_tol;
        ovlp_len = round(fullres_sz(2) - abs(d_sfov(1)));   % overlap length
        % read in either partial or entire image, depending on whether to do scan fault check
        if doScanFaultCheck
            try
                A1 = utils_read_bmp_in_normal_way([section_dir, filesep, imgpath{1}]);
                A1p = A1(1:ovlp_wd,:);
            catch
                status = 2;
                return
            end
            [TF1, curv1] = local_detect_scanfault_1(A1, scanfault_thresh);
            if TF1
                try
                    A2 = utils_read_bmp_in_normal_way([section_dir, filesep, imgpath{2}]);
                    A2p = A2(end-ovlp_wd+1:end,:);
                catch
                    status = 2;
                    return
                end
                [~, curv2] = local_detect_scanfault_1(A2, scanfault_thresh);
                % the scanfault peaks of the two images need to be at the
                % same position
                [mx, pos] = max(min(curv1,curv2));
                if mx >= scanfault_thresh
                    check_result.scanfault = 1;
                    check_result.scanfault_pos = pos;
                    % output scanfault images
                    x_rg = round(size(A1,2)/2) + [-128,128];
                    x_rg = max(1,min(x_rg,size(A1,2)));
                    y_rg = round(pos) + [-64,64];
                    y_rg = max(1, min(y_rg,size(A1,1)));
                    err_imgs.scanfault = uint8(A1(y_rg(1):y_rg(2),x_rg(1):x_rg(2)));
                else
                    check_result.scanfault = 0;
                end
            else
            % no scanfault in the first image, continue to the next
                check_result.scanfault = 0;
                [A2p, imgsz] = utils_read_partial_bmp([section_dir, filesep, imgpath{2}], [fullres_sz(1)-ovlp_wd+1, fullres_sz(1)]);
                if isempty(imgsz)
                    status = 2;
                    return
                end
            end
        else
            [A1p, imgsz] = utils_read_partial_bmp([section_dir, filesep, imgpath{1}], [1,ovlp_wd]);
            if isempty(imgsz)
                status = 2;
                return
            end
            % partial image
            [A2p, imgsz] = utils_read_partial_bmp([section_dir, filesep, imgpath{2}], [fullres_sz(1)-ovlp_wd+1, fullres_sz(1)]);
            if isempty(imgsz)
                status = 2;
                return
            end
        end
        if d_sfov(1) > 0
            A1p = single(A1p(:,end-ovlp_len+1:end));
            A2p = single(A2p(:,1:ovlp_len));
        else
            A1p = single(A1p(:,1:ovlp_len));
            A2p = single(A2p(:,end-ovlp_len+1:end));
        end
        [A1p,A2p,displacement] = local_register_sfovs_fft(A1p,A2p,margin_tol);
        check_result.displacement = displacement;
        [jitter_amp,jitter_freq,skew_amp, skew_length] = local_detect_imagetop_problem(A1p,A2p,thres);
        jitter_amp = jitter_amp - jitter_thresh;
        skew_amp = skew_amp - skew_thresh;
        check_result.jitter_amp =  jitter_amp;
        check_result.jitter_freq = jitter_freq;
        check_result.top_distort_amp = skew_amp;
        check_result.top_distort_length = skew_length;
        if skew_amp > 0 || jitter_amp > 0
            err_imgs.top_err = uint8(cat(3,A2p,A1p,A2p));
        else
            % disp('debug')
        end
        status = 0;
    catch
        status = 1;
        return
    end
end

function [A1p,A2p, displacement] = local_register_sfovs_fft(A1p,A2p,margin_tol)
    if margin_tol == 0
        A1p = A1p(1:(end-margin_tol),:);
        A2p = A2p((margin_tol+1):end,:);
        return
    end
    % mask out top half and remove margin
    ovlp_wd0 = size(A1p,1) - margin_tol;
    stt = floor(ovlp_wd0/2);
    A1pt = A1p((1+stt):(end-margin_tol),:);
    A2pt = A2p((margin_tol+1+stt):end,:);
    A1pt = imfilter(A1pt,fspecial('log',25,2),'symmetric');
    A2pt = imfilter(A2pt,fspecial('log',25,2),'symmetric');
    % Apply more weight on estimated displacement position from the low
    % resolution sFoV stitching
    XCorr = abs(ifft2(fft2(A1pt).*conj(fft2(A2pt))/length(A1pt(:))));
%     subplot(3,1,1)
%     imagesc(XCorr)
    Conf = mean(maxk(XCorr(:),9))/nanstd(XCorr(:));
    mask = false(size(XCorr));
    mask(1) = true;
    mask = fftshift(mask);
    D = bwdist(mask);
    D = exp(-D.^2/(4*margin_tol^2/9));
    D = ifftshift(D);
    % Compute the weighted cross-correlation. Use addition instead of
    % multiplication to apply weight to accomodate empty images
    XCorr = (XCorr - median(XCorr(:),'omitnan'))+ max(0.5e-2,3*nanstd(XCorr(:))).*D;
%     subplot(3,1,2)
%     imagesc(XCorr)
    [~,indx] = max(XCorr(:));
    [dy,dx] = ind2sub(size(XCorr),indx);
    dx = dx - 1; dy = dy-1;
    dx(dx>(size(XCorr,2)/2)) = dx(dx>(size(XCorr,2)/2)) - size(XCorr,2);
    dy(dy>(size(XCorr,1)/2)) = dy(dy>(size(XCorr,1)/2)) - size(XCorr,1);
    if Conf > 20
        displacement = [dx,dy];
    else
        displacement = [nan,nan];
    end
    A2p = imtranslate(A2p,[dx,dy-margin_tol],'nearest','FillValues',nan);
    valididx = ~isnan(A2p);
    % crop out the overlaping regions in both images
    A1p = A1p(any(valididx,2),any(valididx,1));
    A2p = A2p(any(valididx,2),any(valididx,1));
%     subplot(3,1,3)
%     imagesc(cat(3,A1p,A2p,A1p)/255)
end

function [jitter_amp,jitter_freq,skew_amp, skew_length] = local_detect_imagetop_problem(A1p,A2p,thres)
    ctr_T = 9.5; % center frequency of the jitter
%     conf_thre = 2;
    X = 0:(size(A1p,2)-1);
    X(X>size(A1p,2)/2) = X(X>size(A1p,2)/2) - size(A1p,2);
    % remove some noise by Gaussian filter: very important for images with
    % sparse image content or charging contrast
    A1p = imgaussfilt(A1p,1);
    A2p = imgaussfilt(A2p,1);
    % remove the DC part to sharpen the auto-correlation spectrum
    A1p = A1p - imfilter(A1p,ones(1,101)/101,'symmetric');
    A2p = A2p - imfilter(A2p,ones(1,101)/101,'symmetric');
    % apply weight on smaller displacement: neighboring rows shouldn't move
    % too much
    mask = false(1,size(A1p,2));
    mask(1) = true;
    D = bwdist(fftshift(mask));
    D = ifftshift(exp(-D.^2/16));
    % compute the cross-correlation coeffient of the neighboring rows
    tmp1 = ifft(fft(A1p(1:end-1,:)').*conj(fft(A1p(2:end,:)')))'/size(A1p,2);
    tmp1 = tmp1./nanstd(A1p(1:end-1,:),1,2)./nanstd(A1p(2:end,:),1,2);
    ss1 = nanstd(tmp1,0,2);
    % use the ratio between global peak and peak in large displacement
    % regions to estiment the confidence value
    rr1 = min((1- max(tmp1(:,abs(X)>20),[],2)./max(tmp1,[],2))*2,1);
    % apply weight on smaller values
    tmp1 = (max(tmp1-0.1,0) + max(ss1,0.05).*D).*(D>0.001);
    dx1 = nanmean(tmp1.^4.*X,2)./nanmean(tmp1.^4,2);
    dx1(isnan(dx1)) = 0;
    % do the same thing for the second image
    tmp2 = ifft(fft(A2p(1:end-1,:)').*conj(fft(A2p(2:end,:)')))'/size(A2p,2);
    tmp2 = tmp2./nanstd(A2p(1:end-1,:),1,2)./nanstd(A2p(2:end,:),1,2);
    ss2 = nanstd(tmp2,0,2);
    rr2 = min((1- max(tmp2(:,abs(X)>20),[],2)./max(tmp2,[],2))*2,1);
    tmp2 = (max(tmp2-0.1,0) + max(ss2,0.05).*D).*(D>0.001);
    dx2 = nanmean(tmp2.^4.*X,2)./nanmean(tmp2.^4,2);
    dx2(isnan(dx2)) = 0;
    % the relative drifting between the two images
    dx = (dx2(:)-dx1(:)).*min(rr1(:),rr2(:));
    Nc = length(dx);
    % the top half
    idx1 = 1:min(ceil(Nc/2),Nc-1);
    % the lower half
    idx2 = max(1,floor(Nc*1/2)):Nc;
    dx = dx - nanmean(dx(idx2));
    curv = cumsum(imfilter(dx,ones(5,1)/5,'replicate'));
    % the scan may not be linear, so the overlping regions may have
    % slightly different scale, which will give a linear offset. remove.
    xx = reshape(0:(Nc-1),size(curv));
    A = [xx(idx2),ones(length(idx2),1)]\curv(idx2);
    curv = curv - [xx(:),ones(length(xx(:)),1)]*A;
    % use the correlation at x=0 displacement to do preliminary judgement.
    % If correlation stay similar along y, consider no issue. Otherwise use
    % the exponetial fitting.
    rcorr = 1-sum(A1p(1:end-1,:).*A2p(1:end-1,:),2)./...
        (abs(sum(A1p(1:end-1,:).*A1p(2:end,:),2)).*abs(sum(A2p(1:end-1,:).*A2p(2:end,:),2))).^0.5;
    rcorr(isinf(rcorr)) = nan;
    rcorr = rcorr.^2;
    % assuming lower half fit well
    rcorr = max(0,rcorr - mean(rcorr(idx2)));
    % try exponential fit on the correlation coefficeint
    xxt = xx(idx1(:));
    rcorrt = rcorr(idx1(:));
    t1 = rcorrt.*log(rcorrt);
    t1(isnan(t1)) = 0;
    a0 = sum(xxt.^2.*rcorrt)*sum(t1) - sum(xxt.*rcorrt)*sum(xxt.*t1);
    b0 = sum(rcorrt)*sum(xxt.*t1) - sum(xxt.*rcorrt)*sum(t1);
    c0 = sum(rcorrt)*sum(xxt.^2.*rcorrt) - (sum(xxt.*rcorrt))^2;
    a0 = exp(a0/c0);
    b0 = b0/c0;
    % estimate goodness of the fitting. If bad fitting, consider no issue
    e0 = rcorr - a0*exp(b0*xx);
    e0 = nansum(abs(rcorr(:)))/nansum(abs(e0(:)));
    % take care of singular cases
    if e0 < 0.5 || isnan(e0) || b0>=0 || isinf(a0) || isnan(b0) || isinf(b0)
        a0 = 0;
    end
    
    % exponential fit the relative drift curve
    curvt = max(0,curv*sign(nanmean(curv(1:min(5,Nc)))));
    a = max(curvt(idx1));
    b = log(1-abs(a/sum(curvt(:))));
    if a == 0 || abs(a/sum(curvt(:)))>=1
        ct = [0,0,0];
        curv_fit = 0*curv;
    else
        ct = [exp(b*xx(idx1)),xx(idx1)/max(xx(idx1)),ones(size(xx(idx1)))]\curv(idx1);
        curv_fit = [exp(b*xx(:)),xx(:)/max(xx(idx1)),ones(size(xx(:)))]*ct;
        curv_fit(idx2) = 0;
    end
    skew_amp = min(abs(ct(1)),max(abs(curv(idx1))));
    skew_length = max(0,(-1/b)/length(curv));

    % Detect jitter by finding peaks around ctr_T in the drift curve power
    % spectrum.
%     if a0 == 0
%         jitter_spect = abs(fft(curv))/length(curv);
%     else
%         jitter_spect = max(0,abs(fft(curv))-abs(fft(curv_fit)))/length(curv);
%     end
    jitter_spect = max(0,abs(fft(curv))-abs(fft(curv_fit)))/length(curv);
    freqs = 0:(Nc-1);
    freqs(freqs > Nc/2) = Nc - freqs(freqs > Nc/2);
    % aplly more weight around cycle/ctr_T pixels
    wt = exp(-(Nc./freqs(:) - ctr_T).^2/(2*5^2));
    [jitter_amp,jitter_freq] = max(jitter_spect(:).*wt(:));
    jitter_freq = jitter_freq-1;
    if jitter_freq > Nc/2
        jitter_freq = Nc - jitter_freq;
    end
    jitter_freq = jitter_freq/Nc;
    % if a strong exponential decay in y-directioon correlation, but no
    % skew or jitter detected, could be compression by charging. Force
    % positive skew output
    % if skew_amp <= thres.skew_thresh && jitter_amp < thres.jitter_thresh && a0 > 0.9
    %     skew_amp = thres.skew_thresh + 0.5;
    % end
    % if y-direction correlation doesn't chage much, consider mute the
    % output. Risks of false negative.
    if skew_amp > thres.skew_thresh && a0 < 0.1
        skew_amp = thres.skew_thresh;
    end
    % <debug>
    % subplot(4,1,1);imagesc(cat(3,A2p,A1p,A2p)/255);
    % subplot(4,1,2);hold off;plot(curv);hold on;plot(abs(a*exp(b*(xx+1))));
    % subplot(4,1,3);plot(curv-(a*exp(b*(xx+1)))); title(num2str([a,1/b]))
    % subplot(4,1,4);plot(jitter_spect(:).*wt(:));title(num2str([jitter_amp,1/jitter_freq]))
    % </debug>
end

function [TF, curv] = local_detect_scanfault_1(IMG, thre)
    mxratio = 2.5;
    IMG = single(IMG);
    vert_diff = mean(abs(imfilter(IMG,[-1;0;1],'symmetric')),2);
    horz_diff = mean(abs(imfilter(IMG,[-1,0,1],'symmetric')),2);
    curv = vert_diff./horz_diff;
    curv = min(curv, mxratio);
    curv = imclose(curv,ones(11,1));
    marker = zeros(size(curv),'single');
    marker(1:10) = mxratio;
    curv = curv - imreconstruct(marker, curv);
    curv = max(0,curv-quantile(curv,0.2));
    if max(curv) > thre
        TF = true;
    else
        TF = false;
    end
end