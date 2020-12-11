function sampled_mfov_id = utils_uniformly_sample_mfovs(mfov_x, mfov_y)
    % sample a subset(~9) of mfovs for sfov overlap check
    x_mid = nanmean(mfov_x);
    y_mid = nanmean(mfov_y);
    x_max = (1.5*max(mfov_x) + x_mid)/2.5;
    y_max = (1.5*max(mfov_y) + y_mid)/2.5;
    x_min = (1.5*min(mfov_x) + x_mid)/2.5;
    y_min = (1.5*min(mfov_y) + y_mid)/2.5;
    x_sample = [x_min;x_min;x_min;x_mid;x_mid;x_mid;x_max;x_max;x_max];
    y_sample = [y_min;y_mid;y_max;y_min;y_mid;y_max;y_min;y_mid;y_max];
%     x_sample = [x_min;x_min;x_mid;x_mid;x_max;x_max];
%     y_sample = [y_min;y_mid;y_min;y_max;y_mid;y_max];
    sampled_mfov_id = nan(length(x_sample),1);
    for k = 1:length(x_sample)
        [~, idx] = min((mfov_x-x_sample(k)).^2+(mfov_y-y_sample(k)).^2);
        sampled_mfov_id(k) = idx;
    end
    sampled_mfov_id = sampled_mfov_id(~isnan(sampled_mfov_id));
    sampled_mfov_id = unique(sampled_mfov_id);
end