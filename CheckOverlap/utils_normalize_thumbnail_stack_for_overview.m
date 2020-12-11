function mfovstack = utils_normalize_thumbnail_stack_for_overview(mfovstack)
    globnorm = 40;
    mfovstack = single(mfovstack);
%     maxvert = single(min(max(20,quantile(max(mfovstack),0.25)),120)).^nmwt/75^nmwt;
%     maxhorz = single(min(max(20,quantile(max(permute(mfovstack,[2,1,3,4])),0.25)),120)).^nmwt/75^nmwt;
%     mfovstack = single(mfovstack)./medfilt1(min(maxvert,maxhorz),3,[],3,'omitnan','truncate');
    mfovstack1 = reshape(mfovstack,size(mfovstack,1)*size(mfovstack,2),size(mfovstack,3),size(mfovstack,4));
    mfovstack1(imerode(mfovstack<5,ones(3,3))) = nan;
    mfovstack1(mfovstack1==0) = nan;
    mednorm = permute(quantile(mfovstack1,0.75),[4,1,2,3]);
    
    if all(isnan(mednorm(:)))
        mednorm(:) = globnorm;
    else
        mednorm(isnan(mednorm)) = median(mednorm(:),'omitnan');
    end
    
    mfovstack = mfovstack./mednorm*globnorm;
%     for k = 1:(size(mfovstack,3)*size(mfovstack,4))
%         mfovstack(:,:,k) = adapthisteq(uint8(mfovstack(:,:,k)));
%     end
%     tmp2d = median(median(mfovstack,3),4);
%     tmp2d(tmp2d<mean(tmp2d(:))) = mean(tmp2d(:));
%     mfovstack = mfovstack./tmp2d*mean(tmp2d(:));
end