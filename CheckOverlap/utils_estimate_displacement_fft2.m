function [displacement, conf] = utils_estimate_displacement_fft2(imgstack1, imgstack2, tgt_dx, tgt_dy, supp_sz, sclf)
    if nargin < 6
        sclf = 1;
        if nargin <5
            supp_sz = 3;
        end
    end
    imght = size(imgstack1,1);
    imgwd = size(imgstack1,2);
    N = size(imgstack1,3);
    xcorr_matrix = abs(ifft2(fft2(imgstack1).*conj(fft2(imgstack2))));
    mask = ones(size(xcorr_matrix));
    displacement = nan(N,2);
    conf = zeros(N,1);
    d_err = zeros(N,1);
    tgt_broadcast = (length(tgt_dx)==1);
    for k = 1:N
        xc = xcorr_matrix(:,:,k);
        [conf0, midx] = max(xc(:));
        [row,col] = ind2sub([imght,imgwd],midx);
        mask(row,col,k) = -imght*imgwd;
        dx = col-1;
        dy = row-1;
        if tgt_broadcast
            dx = dx - imgwd*round((dx-tgt_dx)/imgwd);
            dy = dy - imght*round((dy-tgt_dy)/imght);
            d_err(k) = max(abs(dx-tgt_dx),abs(dy-tgt_dy));
        else
            dx = dx - imgwd*round((dx-tgt_dx(k))/imgwd);
            dy = dy - imght*round((dy-tgt_dy(k))/imght);
            d_err(k) = max(abs(dx-tgt_dx(k)),abs(dy-tgt_dy(k)));
        end
        displacement(k,:) = [dx, dy];
        conf(k) = conf0;
    end
    d_err = max(d_err - median(d_err,'omitnan'),0);
    conf = conf./(1+0.1*(d_err/(sclf*5)).^2);
    mask = imfilter(mask, fspecial('disk',supp_sz),'circular');
    % subplot(1,2,1);imagesc(xcorr_matrix(:,:,3))
    xcorr_matrix = xcorr_matrix.*(mask>0.5);
    % subplot(1,2,2);imagesc(xcorr_matrix(:,:,3))
    conf2 = squeeze(max(max(xcorr_matrix)));
    confb = squeeze(nanmean(nanmean(xcorr_matrix)));
    conf = (conf-confb(:))./(conf2(:)-confb(:));
end