function ref_info = utils_get_alignment_reference_info(result_dir,scl)
    ref_info = struct;
    % margin to leave around the reference images
    ref_info.margin = 125;
    ref_info.offset = zeros(3);
    ref_info.offset(3,1:2) = ref_info.margin;
    [ref_file, ref_path] = uigetfile([result_dir,filesep,'*.png'],'Select the reference image');
    if isnumeric(ref_file)
        ref_info.ref_img = [];
        return
    end
    ref_info.ref_dir = [ref_path,ref_file];
    disp(['Reference image: ', ref_info.ref_dir]);
    if strcmp(ref_path(end),filesep)
        ref_path = ref_path(1:end-1);
    end
    batch_name = fileparts(ref_path);
    batch_name = batch_name(max(1,end-16):end);
    section_name = strrep(ref_file,'.png','');
    try
        section_name_cell = split(section_name,'_');
        section_name = section_name_cell{end};
    catch
    end

    ref_info.UUID = [batch_name,char(0),section_name];
    if scl ~=1
        IMG0 = imresize(imread(ref_info.ref_dir),scl,'nearest');
    else
        IMG0 = imread(ref_info.ref_dir);
    end
    IMG0 = IMG0(:,:,1);  % in case of RGB
    [XX, YY] = meshgrid(1:size(IMG0,2),1:size(IMG0,1));
    ref_xc = nanmean(XX(IMG0<255));
    ref_yc = nanmean(YY(IMG0<255));
    ref_info.ref_img = IMG0;
    ref_info.mask = local_generate_mask(IMG0);
    ref_info.centroid = [ref_xc,ref_yc] + ref_info.margin;
end


function mask = local_generate_mask(img)
    img = single(img);
    thresh = 200;
    area_ratio = 0.25;
    mm = mean(img(img>thresh & img<255));
    if isnan(mm)
        mm = 255;
    end
    mask = img < (2*mm - 255);
    mask = imfill(mask,'holes');
    mask = imopen(imclose(mask, strel('disk',3)),strel('disk',3));
    L = double(mask);
    CC = bwconncomp(mask);
    for k = 1:CC.NumObjects
        idx = CC.PixelIdxList{k};
        L(idx) = length(idx);
    end
    L = L/max(L(:));
    mask = imdilate(L >= area_ratio,strel('disk',2));
end