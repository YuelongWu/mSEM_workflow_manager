function filterbank = utils_generate_radon_filter_bank(wd, Ntheta)
    blursz = ceil(wd/2);
    Nbin = 25;
    radonfilt1 = zeros(wd*Nbin+blursz*2,wd+blursz*2);
    radonfilt1(blursz+(1:wd*Nbin),blursz+(1:wd)) = 1;
    if blursz > 0
        radonfilt1  = imgaussfilt(radonfilt1, blursz/2);
    end
    radonfilt1 = radonfilt1/sum(radonfilt1(:));
    filterbank = struct;
    filterbank.filters = cell(Ntheta,1);
    filterbank.filters{1} = radonfilt1;
    filterbank.offsets = zeros(Nbin,2,Ntheta);
    binRange = wd*((1-Nbin):2:(Nbin-1))/2;
    filterbank.offsets(:,1,1) = binRange;
    filterbank.offsets(:,2,1) = 0;
    for k = 1:(Ntheta-1)
        theta = k*180/Ntheta;
        filterbank.filters{k+1} = local_crop_zero_boundary(imrotate(radonfilt1,theta));
        filterbank.offsets(:,1,k+1) = binRange*cosd(theta);
        filterbank.offsets(:,2,k+1) = -binRange*sind(theta);
    end
end

function img = local_crop_zero_boundary(img)
    idx1 = sum(img)>0;
    idx2 = sum(img,2)>0;
    img = img(idx2,idx1);
end