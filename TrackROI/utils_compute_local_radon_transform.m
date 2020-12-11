function radon_matrix = utils_compute_local_radon_transform(imgf, XY, filterbank)
    Lf = length(filterbank.filters{1});
    marginW = ceil(Lf/2);
    img_lg = zeros(size(imgf,1)+2*marginW,size(imgf,2)+2*marginW,'single');
    img_lg(marginW+(1:size(imgf,1)),marginW+(1:size(imgf,2))) = imgf;
    Nt = size(filterbank.offsets,3);
    Nb = size(filterbank.offsets,1);
    Nfeat = size(XY,1);
    radon_matrix = zeros(Nb,Nfeat,Nt,'single');
    for t = 1:Nt
        imgff = imfilter(img_lg,filterbank.filters{t},'replicate');
        xx = round(repmat(filterbank.offsets(:,1,t),1,Nfeat) + repmat(XY(:,1)',Nb,1) + marginW);
        yy = round(repmat(filterbank.offsets(:,2,t),1,Nfeat) + repmat(XY(:,2)',Nb,1) + marginW);
        nindx = sub2ind(size(imgff),yy,xx);
        radon_matrix(:,:,t) = imgff(nindx);
    end
    
    radon_matrix = permute(radon_matrix,[1,3,2]);
end