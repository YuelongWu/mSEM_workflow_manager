function ref_idxs = utils_select_neighbors_for_reference(refnum,idx_r,sid_r,Nstack)
    if isnan(sid_r(refnum))
        [mm,mi] = mink(abs(refnum-idx_r),Nstack);
        mi(mm > Nstack) = [];
        ref_idxs = idx_r(mi);
    else
        [mm,mi] = mink(abs(sid_r(refnum)-sid_r(idx_r)),Nstack);
        mi(mm > Nstack | isnan(mm)) = [];
        ref_idxs = idx_r(mi);
    end
end