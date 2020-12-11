function [border_template_idx, border_mask, displacement_vector] = utils_prepare_border_template(directional_bsfov_idx,sfov_coord,imgsz,d_mfov,tolerance)
    % make a template for tile border sfovs together. border_mask gives the
    % region in the cross-correlation matrix that is considered legit by 
    % the tolerance
    
    % Yuelong Wu, May 2018
    
    border_mask = cell(6,1);
    border_template_idx = cell(6,1);
    displacement_vector = zeros(6,2);
    imght = imgsz(1);
    imgwd = imgsz(2);
    idx_matrix = zeros(imght*imgwd,size(directional_bsfov_idx,2));
    for k = 1:size(directional_bsfov_idx,1)
        border_sfov_x = sfov_coord(directional_bsfov_idx(k,:),1);
        border_sfov_y = sfov_coord(directional_bsfov_idx(k,:),2);
        border_sfov_x = round(border_sfov_x-min(border_sfov_x));
        border_sfov_y = round(border_sfov_y-min(border_sfov_y));
        border_sfov_x1 = sfov_coord(directional_bsfov_idx(7-k,:),1);
        border_sfov_y1 = sfov_coord(directional_bsfov_idx(7-k,:),2);
        border_sfov_x1 = round(border_sfov_x1-min(border_sfov_x1));
        border_sfov_y1 = round(border_sfov_y1-min(border_sfov_y1));
        mosaic_wd = max(max(border_sfov_x),max(border_sfov_x1)) + 2*imgwd;
        mosaic_ht = max(max(border_sfov_y),max(border_sfov_y1)) + 2*imght;
        tmp_template = false(mosaic_ht,mosaic_wd);
        for s = 1:size(directional_bsfov_idx,2)
            tmp_template(border_sfov_y(s)+(1:imght),border_sfov_x(s)+(1:imgwd)) = 1;
            idx_matrix(:,s) = find(tmp_template);
            tmp_template = 0 & tmp_template;
        end
        border_template_idx{k} = idx_matrix(:);
        displacement_vector(k,1) = min(sfov_coord(directional_bsfov_idx(7-k,:),1))-min(sfov_coord(directional_bsfov_idx(k,:),1));
        displacement_vector(k,2) = min(sfov_coord(directional_bsfov_idx(7-k,:),2))-min(sfov_coord(directional_bsfov_idx(k,:),2));
        tgt_dx = round(d_mfov(k,1) +  displacement_vector(k,1));
        tgt_dy = round(d_mfov(k,2) +  displacement_vector(k,2));
        tgt_dx = tgt_dx+1 - mosaic_wd*floor(tgt_dx/mosaic_wd);
        tgt_dy = tgt_dy+1 - mosaic_ht*floor(tgt_dy/mosaic_ht);
        tmp_template(tgt_dy,tgt_dx) = 1;
        D = false(2*round(tolerance/2)+1);
        D(1) = true;
        D = bwdist(ifftshift(D),'chessboard');
        D = exp(-D.^2/(2*(tolerance/3)^2));
        tmp_template = imfilter(single(tmp_template),double(D),'circular');
        border_mask{k} = tmp_template;
    end
end