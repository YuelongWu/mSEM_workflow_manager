function overviewimg = utils_generate_overview_img(overviewstack, mfov_stitch_x,mfov_stitch_y,sfov_coord,ds_scl)
    ds_x = repmat(mfov_stitch_x(:)', size(sfov_coord,1),1) + repmat(sfov_coord(:,1),1,length(mfov_stitch_x(:)));
    ds_y = repmat(mfov_stitch_y(:)', size(sfov_coord,1),1) + repmat(sfov_coord(:,2),1,length(mfov_stitch_y(:)));
    ds_x = (ds_x - min(ds_x(:))) * ds_scl;
    ds_y = (ds_y - min(ds_y(:))) * ds_scl;
    ds_x = round(ds_x);
    ds_y = round(ds_y);
    ht = size(overviewstack,1);
    wd = size(overviewstack,2);
    overviewimg = zeros(max(ds_y(:))+ht, max(ds_x(:))+wd, 'uint8');
    for k = 1:1:length(ds_x(:))
        xx = ds_x(k);
        yy = ds_y(k);
        if (xx>=0) && (yy>=0)
            overviewimg(yy+(1:ht),xx+(1:wd)) = max(overviewstack(:,:,k),1);
        end
    end
end