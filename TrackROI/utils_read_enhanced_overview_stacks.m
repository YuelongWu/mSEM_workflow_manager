function ovvstack = utils_read_enhanced_overview_stacks(img_dirs)
    ovvstack = [];
    for k = 1:length(img_dirs)
        img = imread(img_dirs{k});
        if k == 1
            ovvstack = nan(size(img,1),size(img,2),length(img_dirs), 'single');
        end
        ovvstack(:,:,k) = utils_enhance_nucleus_and_blood_vessels(img(:,:,1));
    end
end