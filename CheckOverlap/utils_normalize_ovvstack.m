function ovvstack = utils_normalize_ovvstack(ovvstack)
    wd = 3;
    [hN, he] = histcounts(ovvstack(:),0:0.1:50);
    [pks,locs] = findpeaks(imfilter(hN(2:end-1), ones(3,1),'replicate'),'MinPeakDistance',5,'MinPeakProminence',0.5);
    [~,idx] = max(pks.*locs);
    hc = he(locs(idx)) - wd/2;
    ovvstack = uint8((ovvstack-hc)*150/hc + 127);
    ovvstack = min(max(ovvstack,2),253);
end