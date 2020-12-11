function utils_update_text_color(hID, hIMQA, IMQA_val, IMQA_thresh)
    Nl = length(hID);
    if Nl
        colormat  = zeros(Nl,3);
        colormat(IMQA_val>=IMQA_thresh,2) = 0.75;
        % tmp = (IMQA_val(IMQA_val<IMQA_thresh) - min(IMQA_val(:)))/(IMQA_thresh - min(IMQA_val(:))+0.01);
        tmp = max(min((IMQA_val(IMQA_val<IMQA_thresh) - IMQA_thresh+15)/15,1),0);
        colormat(IMQA_val<IMQA_thresh,1) = 1-tmp;
        colormat(IMQA_val<IMQA_thresh,3) = tmp;
        colorcell = mat2cell(colormat,ones(1,Nl),3);
        set(hID, {'Color'},colorcell);
        set(hIMQA, {'Color'},colorcell);
    end
end
    