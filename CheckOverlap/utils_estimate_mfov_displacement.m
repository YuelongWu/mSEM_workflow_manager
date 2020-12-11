function [displacement, conf] = utils_estimate_mfov_displacement(mosaicstack, mosaic_mask, displacement_vector, d_mfov, supp_sz)
    if nargin < 5
        supp_sz = 5;
    end
    mosaic_ht = size(mosaicstack,1);
    mosaic_wd = size(mosaicstack,2);
    supp_mask = ones(size(mosaic_mask),'single');
    % mosaicstack = mosaicstack + nanstd(mosaicstack(:)).*randn(size(mosaicstack));
    F = fft2(mosaicstack);
    xcorr_matrix = real(ifft2(F(:,:,1).*conj(F(:,:,2))));
    xcorr_matrix = xcorr_matrix.*(mosaic_mask>0);
    % xcorr_matrix = imgaussfilt(max(xcorr_matrix,0),0.5,'Padding','symmetric');
    [conf0, midx] = max(xcorr_matrix(:)+max(1,std(xcorr_matrix(mosaic_mask>0))*mosaic_mask(:)));
    [row,col] = ind2sub([mosaic_ht,mosaic_wd],midx);
    supp_mask(midx) = -mosaic_ht*mosaic_wd;
    supp_mask = imfilter(single(supp_mask), fspecial('disk',supp_sz),'circular')>0.5;
    conf = sum(maxk(xcorr_matrix(~supp_mask & mosaic_mask & (xcorr_matrix>0.5*conf0)),3))/mean(maxk(xcorr_matrix(supp_mask & mosaic_mask),5));
    dx = col - 1 - mosaic_wd*round((col - d_mfov(1) - displacement_vector(1))/mosaic_wd);
    dy = row - 1 - mosaic_ht*round((row - d_mfov(2) - displacement_vector(2))/mosaic_ht);
    dx = dx - displacement_vector(1);
    dy = dy - displacement_vector(2);
    dx  = dx - mosaic_wd*round((dx - d_mfov(1))/mosaic_wd);
    dy  = dy - mosaic_ht*round((dy - d_mfov(2))/mosaic_ht);
    displacement = [dx,dy];
    %%% debug%%%%%%%
%     if conf < 3
%         ddx = col - 1 - mosaic_wd*round(col/mosaic_wd);
%         ddy = row - 1 - mosaic_ht*round(row/mosaic_ht);
%         imagesc(cat(3,abs(mosaicstack(:,:,1)),abs(imtranslate(mosaicstack(:,:,2),[ddx,ddy])),abs(mosaicstack(:,:,1)))/255)
%         disp(conf)
%     end
    
end