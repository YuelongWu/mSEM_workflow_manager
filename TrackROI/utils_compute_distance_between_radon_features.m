function [Mdist, Mtheta] = utils_compute_distance_between_radon_features(Mradon1, Mradon2)
    % number of features
    Nft1 = size(Mradon1,3);
    Nft2 = size(Mradon2,3);
    % dimensions of Radon matrix
    Ntht = size(Mradon1,2);  % theta
    Nbin = size(Mradon1,1);  % bin
    
    Mtheta = zeros(Nft1,Nft2,'uint8');
    Mdist = - ones(Nft1,Nft2,'single');
    
    Vradon1 = reshape(Mradon1,Nbin*Ntht,Nft1);
    Vradon2 = reshape(Mradon2,Nbin*Ntht,Nft2);
    
    Vradon1 = (Vradon1 - repmat(nanmean(Vradon1),Nbin*Ntht,1))./repmat(nanstd(Vradon1),Nbin*Ntht,1);
    Vradon2 = (Vradon2 - repmat(nanmean(Vradon2),Nbin*Ntht,1))./repmat(nanstd(Vradon2),Nbin*Ntht,1);
    for k = 1:(2*Ntht)
        Mdist1 = Vradon1'*Vradon2/(Ntht*Nbin);
        idx = (Mdist1>Mdist);
        Mdist(idx) = Mdist1(idx);
        Mtheta(idx) = k;
        Mradon2 = reshape(Vradon2,Nbin,Ntht,Nft2);
        Mradon2 = circshift(Mradon2,1,2);
        Mradon2(:,1,:) = Mradon2(end:-1:1,1,:);
        Vradon2 = reshape(Mradon2,Nbin*Ntht,Nft2);
    end
    Mdist = 1- Mdist;
end