% Align the overview image stack
% The script first ask the user to select the folder (contains overview
% images, can be a batch folder or a wafer folder) to process, then ask for
% the reference image. If no reference image are specified, use the first
% image in the select folder as reference.

% The output image will be saved in the "aligned_overviews" folder in the
% oringinal folder. Black images means the alignment failed. in the output
% folder, "reference_image.txt" indicates the path to the original image.

% Algorithm:
% The script uses morphological reconstruction after contrast equalization
% to estimate the background and enhance the nucleaus and blood vessle
% features. After applying a gaussian filter to the enhanced image, feature
% point locations are defined as local maximum in the filtered image. The
% sinogram of the neighborhood of each feature point serve as the
% discriptors for points matching, and RANSAC is used to do the actual
% alignment.

% Yuelong Wu, June 2018
close all; clear; clc;
addpath('TrackROI');

% Number of angles to sample when generating the sinogram
Ntheta = 12;
% Width of the "projection beam" when generating the sinogram
BeamWd = 3;
% Number of images in the queue whose median image served as the reference
% when aligning each image. Only successfully aligned image will enter the
% queue.
Nstack = 5;
scl = 0.5;

% threshold for scale and shear and rotation
t1 = 0.35;  % scaling
t2 = 0.4;  % shearing
t3 = 1.5;  % rotation

% function used for enhance features
enhance_fun = @enhance_simple_inverse;
% enhance_fun = @enhance_simple_inverse;
% whether to save the result depends on if any information is updated
anyluck = false;

% define the position of the external reference
extrefpos = 0;
%%
% the result folder containing the overview image to align.
try
    addpath('ConfigFiles');
    load('mSEM_retake_manager_default_folder.mat')
    result_dir = uigetdir(result_dir,'Select the result folder');
catch
    result_dir = '';
    result_dir = 'F:\U19_Fish1_5\RetakeManager';
    result_dir = uigetdir(result_dir,'Select the result folder');
end
if isnumeric(result_dir)
    disp('No folder selected.')
    return
end

[imglist, ifrender] = utils_get_overview_img_list(result_dir);
Nimg = length(imglist);
if isempty(ifrender)
    disp('No overview image found in the selected folder.');
    return;
end

output_dir = [result_dir, filesep, 'aligned_overviews'];
if ~exist(output_dir,'dir')
    mkdir(output_dir);
end

% check if need to align the whole thing or only add
% sections to existing aligned stack
newstack = true;
if exist([output_dir, filesep, 'alignment_info.mat'], 'file')
    load([output_dir, filesep, 'alignment_info.mat']);
    imglist0 = alignment_info.imglist;
    imglist0 = imglist0([imglist0(:).isaligned]);
    % allow the user to delete a certain section to re-align
    already_written = dir([output_dir,filesep,'*.png']);
    already_written = {already_written(:).name};
    already_written = strrep(already_written,'.png','');
    notdeleted = contains({imglist0(:).section_name},already_written);
    imglist0 = imglist0(notdeleted);
    % some sections were sucessfully aligned in previous runs
    if ~isempty(imglist0)
        ref_info = alignment_info.ref_info;
        % check if the user manually changed the mask image
        if exist([output_dir,filesep,'mask.png'],'file')
            mask0 = imread([output_dir,filesep,'mask.png']);
            mask = mask0(:,:,1) == 255;
            if any(ref_info.mask(:)~=mask(:))
                ref_info.mask = mask;
                mask_updated = true;
                anyluck = true;
            else
                mask_updated = false;
            end
        else
            mask_updated = false;
        end
        % update imglist from the previous aligment
        [paligned, pidx] = ismember({imglist(:).UUID},{imglist0(:).UUID});
        if any(paligned)
            imglist(paligned) = imglist0(pidx(paligned));
            newstack = false;
        end
    end
end
% align the entire stack from the very beginning.
if newstack
    % ask the user to select a reference image
    ref_info = utils_get_alignment_reference_info(result_dir,scl);
    if isempty(ref_info.ref_img)
        disp('No referece image selected. Abort overview alignment.');
        return
    end
    anyluck = true;
    % try to guess a reference mask to caculate the overlap ratio
    imwrite(uint8(cat(3,uint8(255*ref_info.mask) + 0.8*ref_info.ref_img,...
        0.8*ref_info.ref_img,0.8*ref_info.ref_img)),[output_dir,filesep,'mask.png']);
    % see if the reference image is in the result folder
    ref_idx = find(strcmp({imglist(:).UUID},ref_info.UUID));
    if isempty(ref_idx)
        % reference image is from outside the stack
        ref_idx = extrefpos;
        IMG0 = ref_info.ref_img;
        tform = eye(3) + ref_info.offset;
        IMG1 = imwarp(IMG0, affine2d(tform),'nearest',...
            'outputview',imref2d(size(IMG0)+2*ref_info.margin),...
            'FillValues',255);
        ref_info.inner_ref = false;
    else
        % reference image is from inside the stack
        imglist(ref_idx).isreference = true;
        imglist(ref_idx).isaligned = true;
        imglist(ref_idx).A2D = eye(3);
        imglist(ref_idx).missing_area = 0;
        imglist(ref_idx).rotation = 0;
        imglist(ref_idx).displacement = [0,0];
        IMG0 = ref_info.ref_img;
        tform = imglist(ref_idx).A2D + ref_info.offset;
        IMG1 = imwarp(IMG0, affine2d(tform),'nearest',...
            'outputview',imref2d(size(IMG0)+2*ref_info.margin),...
            'FillValues',255);
        if ifrender(ref_idx)
            imwrite(uint8(IMG1),[output_dir,filesep,imglist(ref_idx).section_name,'.png']);
            imglist(ref_idx).isrendered = true;
        end
        ref_info.inner_ref = true;
    end
    Tref = enhance_fun(single(IMG1));

end

ref_mask = imwarp(ref_info.mask, affine2d(eye(3)+ref_info.offset),'nearest',...
    'outputview',imref2d(size(ref_info.mask)+2*ref_info.margin),'FillValues',0);
tot_area = sum(ref_mask(:));
[XX, YY] = meshgrid(1:size(ref_mask,2),1:size(ref_mask,1));
outputsz = size(ref_mask);
refcrd = imref2d(size(ref_mask));
filterbank = utils_generate_radon_filter_bank(BeamWd, Ntheta);
if newstack
    % align from the very beginning
    RefStack = repmat(Tref,1,1,Nstack);
    StackPt = 2;
    T0 = Tref;
    [XY0, ~] = utils_detect_features_localmax_blur(T0);
    Mradon0 = utils_compute_local_radon_transform(T0, XY0, filterbank);
    A0 = eye(3);
    % <-- <-- <-- <-- <-- <-- <-- <-- <-- <-- <-- <-- <-- <-- <-- <-- <-- <-- <-- <-- <--
    for k = (ref_idx-1):-1:1
        % -------------------------------------------------------------------%
        if scl == 1
            IMG1 = imread([imglist(k).folder, filesep, imglist(k).name]);
            IMG1 = IMG1(:,:,1);
        else
            IMG1o = imread([imglist(k).folder, filesep, imglist(k).name]);
            IMG1o = IMG1o(:,:,1);
            IMG1 = imresize(IMG1o,scl,'nearest');
        end
        T1 = enhance_fun(single(IMG1));
        [XY1, ~] = utils_detect_features_localmax_blur(T1);
        Mradon1 = utils_compute_local_radon_transform(T1, XY1, filterbank);
        [Mdist, Mtheta] = utils_compute_distance_between_radon_features(Mradon0, Mradon1);
        Mtheta = ones(size(Mtheta));
        [indexpairs, metrics, dtheta] = utils_align_radon_features(Mdist, Mtheta, Ntheta);
        A = utils_exhaustic_get_transformation_matrix(XY0,XY1,indexpairs,metrics);
        imglist(k).A2D = A - ref_info.offset;
        if any(isnan(A(:)))
            disp(['Failed to match features: ', imglist(k).batch_name,' ',imglist(k).section_name]);
            continue;
        end
        [~,S,~] = svd(A(1:2,1:2)/A0(1:2,1:2));
        [U,~,V] = svd(A(1:2,1:2));
        R = U*V';
        imglist(k).rotation = wrapToPi(atan2(R(3),R(1)))*180/pi;
        if (S(1)*S(4) > 0) && (abs(log(S(1)*S(4))) < t1) && (abs(log(S(1)/S(4))) < t2) % && (wrapToPi(abs(dtheta + atan2(R(3),R(1))))<(t3*pi/Ntheta))
            imglist(k).isaligned = true;
            IMG1t = imwarp(IMG1, affine2d(A),'nearest','OutputView',refcrd,'FillValues',255);
            xc = nanmean(XX(IMG1t<255));
            yc = nanmean(YY(IMG1t<255));
            imglist(k).displacement = [xc,yc] - ref_info.centroid;
            imglist(k).missing_area = sum(ref_mask(IMG1t==255))/tot_area;
            % only put into reference stack if the section is not retaken
            if ifrender(k)
                A0 = A;
                imwrite(uint8(IMG1t),[output_dir,filesep,imglist(k).section_name,'.png']);
                imglist(k).isrendered = true;
                T1t = imwarp(T1, affine2d(A),'OutputView',refcrd,'FillValues',0);
                RefStack(:,:,StackPt) = T1t;
                StackPt = StackPt + 1;
                if StackPt > Nstack
                    StackPt = StackPt - Nstack;
                end
                % update reference
                T0 = quantile(RefStack,0.75,3);
                [XY0, ~] = utils_detect_features_localmax_blur(T0);
                Mradon0 = utils_compute_local_radon_transform(T0, XY0, filterbank);
            end
        else
            disp(['Transformation exceeds deformation constraint: ', imglist(k).batch_name,' ',imglist(k).section_name])
            imglist(k).isaligned = false;
            try
                IMG1t = imwarp(IMG1, affine2d(A),'nearest','OutputView',refcrd,'FillValues',255);
                if ifrender(k)
                    imwrite(uint8(IMG1t),[output_dir,filesep,imglist(k).section_name,'.png']);
                    imglist(k).isrendered = true;
                end
                xc = nanmean(XX(IMG1t<255));
                yc = nanmean(YY(IMG1t<255));
                imglist(k).displacement = [xc,yc] - ref_info.centroid;
                imglist(k).missing_area = sum(ref_mask(IMG1t==255))/tot_area;
            catch
                disp('    Failed to apply transform.');
            end
        end
        % -------------------------------------------------------------------%
    end
    % --> --> --> --> --> --> --> --> --> --> --> --> --> --> --> --> --> --> --> --> -->
    RefStack = repmat(Tref,1,1,Nstack);
    StackPt = 2;
    T0 = Tref;
    [XY0, ~] = utils_detect_features_localmax_blur(T0);
    Mradon0 = utils_compute_local_radon_transform(T0, XY0, filterbank);
    A0 = eye(3);
    for k = (ref_idx+1):1:Nimg
        % -------------------------------------------------------------------%
        if scl == 1
            IMG1 = imread([imglist(k).folder, filesep, imglist(k).name]);
            IMG1 = IMG1(:,:,1);
        else
            IMG1o = imread([imglist(k).folder, filesep, imglist(k).name]);
            IMG1o = IMG1o(:,:,1);
            IMG1 = imresize(IMG1o,scl,'nearest');
        end
        T1 = enhance_fun(single(IMG1));
        [XY1, ~] = utils_detect_features_localmax_blur(T1);
        Mradon1 = utils_compute_local_radon_transform(T1, XY1, filterbank);
        [Mdist, Mtheta] = utils_compute_distance_between_radon_features(Mradon0, Mradon1);
        Mtheta = ones(size(Mtheta));
        [indexpairs, metrics, dtheta] = utils_align_radon_features(Mdist, Mtheta, Ntheta);
        A = utils_exhaustic_get_transformation_matrix(XY0,XY1,indexpairs,metrics);
        imglist(k).A2D = A - ref_info.offset;
        if any(isnan(A(:)))
            disp(['Failed to match features: ', imglist(k).batch_name,' ',imglist(k).section_name]);
            continue;
        end
        [~,S,~] = svd(A(1:2,1:2)/A0(1:2,1:2));
        [U,~,V] = svd(A(1:2,1:2));
        R = U*V';
        imglist(k).rotation = wrapToPi(atan2(R(3),R(1)))*180/pi;
        if (S(1)*S(4) > 0) && (abs(log(S(1)*S(4))) < t1) && (abs(log(S(1)/S(4))) < t2) % && (wrapToPi(abs(dtheta + atan2(R(3),R(1))))<(t3*pi/Ntheta))
            imglist(k).isaligned = true;
            IMG1t = imwarp(IMG1, affine2d(A),'nearest','OutputView',refcrd,'FillValues',255);
            xc = nanmean(XX(IMG1t<255));
            yc = nanmean(YY(IMG1t<255));
            imglist(k).displacement = [xc,yc] - ref_info.centroid;
            imglist(k).missing_area = sum(ref_mask(IMG1t==255))/tot_area;
            % only put into reference stack if the section is not retaken
            if ifrender(k)
                A0 = A;
                imwrite(uint8(IMG1t),[output_dir,filesep,imglist(k).section_name,'.png']);
                imglist(k).isrendered = true;
                T1t = imwarp(T1, affine2d(A),'OutputView',refcrd,'FillValues',0);
                RefStack(:,:,StackPt) = T1t;
                StackPt = StackPt + 1;
                if StackPt > Nstack
                    StackPt = StackPt - Nstack;
                end
                % update reference
                T0 = quantile(RefStack,0.75,3);
                [XY0, ~] = utils_detect_features_localmax_blur(T0);
                Mradon0 = utils_compute_local_radon_transform(T0, XY0, filterbank);
            end
        else
            disp(['Transformation exceeds deformation constraint: ', imglist(k).batch_name,' ',imglist(k).section_name])
            imglist(k).isaligned = false;
            try
                IMG1t = imwarp(IMG1, affine2d(A),'nearest','OutputView',refcrd,'FillValues',255);
                if ifrender(k)
                    imwrite(uint8(IMG1t),[output_dir,filesep,imglist(k).section_name,'.png']);
                    imglist(k).isrendered = true;
                end
                xc = nanmean(XX(IMG1t<255));
                yc = nanmean(YY(IMG1t<255));
                imglist(k).displacement = [xc,yc] - ref_info.centroid;
                imglist(k).missing_area = sum(ref_mask(IMG1t==255))/tot_area;
            catch
                disp('    Failed to apply transform.');
            end
        end
        % -------------------------------------------------------------------%
    end
else
    % complete the earlier alignment
    % flags to record which section has been fully processed
    flag_p = false(Nimg,1);
    prendered = [imglist(:).isrendered];
    if any(xor(prendered(:),ifrender(:)))
        anyluck = true;
    end
    section_id = [imglist(:).section_id];
    idx_r = find(prendered);
    % rendered section id
    sid_r = section_id; sid_r(~prendered) = nan;
    % find the closest aligned & rendered section as the references for each image
    [ref_dis, ref_idx] = bwdist(prendered);
    ref_idx = single(ref_idx).*(1-paligned);
    ref_list = unique(ref_idx);
    ref_list = ref_list(ref_list>0);
    RefStack = nan(outputsz(1),outputsz(2),Nstack,'single');
    if ~isempty(ref_list)
      % some of the sections need aligment
        anyluck = true;
        for rk = 1:length(ref_list)
            % read in some neighbors of the reference to increase the robustness
            ref_num = ref_list(rk);
            align_idx = find(ref_idx == ref_num);
            ref_idxs = utils_select_neighbors_for_reference(ref_num,idx_r,sid_r,Nstack);
            RefStack = nan + RefStack;
            for tk = 1:length(ref_idxs)
                rid = ref_idxs(tk);
                IMG1t = imread([output_dir,filesep,imglist(rid).section_name,'.png']);
                IMG1t = IMG1t(:,:,1);
                if ~flag_p(rid)
                    if ifrender(rid)
                        imglist(rid).isrendered = true;
                    else
                        imglist(rid).isrendered = false;
                    end
                    if mask_updated
                        imglist(rid).missing_area = sum(ref_mask(IMG1t==255))/tot_area;
                    end
                    flag_p(rid) = true;
                end
                RefStack(:,:,tk) = enhance_fun(single(IMG1t));
            end
            Tref = quantile(RefStack,0.75,3);
            RefStack = nan + RefStack;
            RefStack(:,:,1) = Tref;
            StackPt = 2;
            T0 = Tref; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [XY0, ~] = utils_detect_features_localmax_blur(T0);
            Mradon0 = utils_compute_local_radon_transform(T0, XY0, filterbank);
            A0 = eye(3);

            if min(align_idx) < ref_num
                % <-- <-- <-- <--
                for k = (ref_num-1):-1:min(align_idx)
                    if all(align_idx ~= k)
                        continue;
                    end
                  % -------------------------------------------------------------------%
                    if scl == 1
                        IMG1 = imread([imglist(k).folder, filesep, imglist(k).name]);
                        IMG1 = IMG1(:,:,1);
                    else
                        IMG1o = imread([imglist(k).folder, filesep, imglist(k).name]);
                        IMG1o = IMG1o(:,:,1);
                        IMG1 = imresize(IMG1o,scl,'nearest');
                    end
                    T1 = enhance_fun(single(IMG1));
                    [XY1, ~] = utils_detect_features_localmax_blur(T1);
                    Mradon1 = utils_compute_local_radon_transform(T1, XY1, filterbank);
                    [Mdist, Mtheta] = utils_compute_distance_between_radon_features(Mradon0, Mradon1);
                    Mtheta = ones(size(Mtheta));
                    [indexpairs, metrics, dtheta] = utils_align_radon_features(Mdist, Mtheta, Ntheta);
                    A = utils_exhaustic_get_transformation_matrix(XY0,XY1,indexpairs,metrics);
                    imglist(k).A2D = A - ref_info.offset;
                    if any(isnan(A(:)))
                        disp(['Failed to match features: ', imglist(k).batch_name,' ',imglist(k).section_name]);
                        imglist(k).isrendered = false;
                        continue;
                    end
                    [~,S,~] = svd(A(1:2,1:2)/A0(1:2,1:2));
                    [U,~,V] = svd(A(1:2,1:2));
                    R = U*V';
                    imglist(k).rotation = wrapToPi(atan2(R(3),R(1)))*180/pi;
                    if (S(1)*S(4) > 0) && (abs(log(S(1)*S(4))) < t1) && (abs(log(S(1)/S(4))) < t2) % && (wrapToPi(abs(dtheta + atan2(R(3),R(1))))<(t3*pi/Ntheta))
                        imglist(k).isaligned = true;
                        IMG1t = imwarp(IMG1, affine2d(A),'nearest','OutputView',refcrd,'FillValues',255);
                        xc = nanmean(XX(IMG1t<255));
                        yc = nanmean(YY(IMG1t<255));
                        imglist(k).displacement = [xc,yc] - ref_info.centroid;
                        imglist(k).missing_area = sum(ref_mask(IMG1t==255))/tot_area;
                        % only put into reference stack if the section is not retaken
                        if ifrender(k)
                            A0 = A;
                            if any(strcmpi(already_written,imglist(k).section_name))
                                % do not overwrite at the first round
                                flag_p(k) = false;
                            else
                                imwrite(uint8(IMG1t),[output_dir,filesep,imglist(k).section_name,'.png']);
                                imglist(k).isrendered = true;
                                flag_p(k) = true;
                            end
                            T1t = imwarp(T1, affine2d(A),'OutputView',refcrd,'FillValues',0);
                            RefStack(:,:,StackPt) = T1t;
                            StackPt = StackPt + 1;
                            if StackPt > Nstack
                                StackPt = StackPt - Nstack;
                            end
                            % update reference
                            T0 = quantile(RefStack,0.75,3);
                            [XY0, ~] = utils_detect_features_localmax_blur(T0);
                            Mradon0 = utils_compute_local_radon_transform(T0, XY0, filterbank);
                        else
                                imglist(k).isrendered = false;
                        end
                    else
                        disp(['Transformation exceeds deformation constraint: ', imglist(k).batch_name,' ',imglist(k).section_name])
                        imglist(k).isaligned = false;
                        try
                            IMG1t = imwarp(IMG1, affine2d(A),'nearest','OutputView',refcrd,'FillValues',255);
                            xc = nanmean(XX(IMG1t<255));
                            yc = nanmean(YY(IMG1t<255));
                            imglist(k).displacement = [xc,yc] - ref_info.centroid;
                            imglist(k).missing_area = sum(ref_mask(IMG1t==255))/tot_area;
                            if ifrender(k)
                                if any(strcmpi(already_written,imglist(k).section_name))
                                    % do not overwrite at the first round
                                    flag_p(k) = false;
                                else
                                    imwrite(uint8(IMG1t),[output_dir,filesep,imglist(k).section_name,'.png']);
                                    imglist(k).isrendered = true;
                                    flag_p(k) = true;
                                end
                            else
                                flag_p(k) = true;
                                imglist(k).isrendered = false;
                            end
                        catch
                            flag_p(k) = true;
                            disp('    Failed to apply transform.');
                        end
                    end
                    % -------------------------------------------------------------------%
                end
                RefStack = nan + RefStack;
                RefStack(:,:,1) = Tref;
                StackPt = 2;
                T0 = Tref;
                [XY0, ~] = utils_detect_features_localmax_blur(T0);
                Mradon0 = utils_compute_local_radon_transform(T0, XY0, filterbank);
                A0 = eye(3);
            end

            for k = (ref_num+1):1:max(align_idx)
                if all(align_idx ~= k)
                    continue;
                end
              % -------------------------------------------------------------------%
                if scl == 1
                    IMG1 = imread([imglist(k).folder, filesep, imglist(k).name]);
                    IMG1 = IMG1(:,:,1);
                else
                    IMG1o = imread([imglist(k).folder, filesep, imglist(k).name]);
                    IMG1o = IMG1o(:,:,1);
                    IMG1 = imresize(IMG1o,scl,'nearest');
                end
                T1 = enhance_fun(single(IMG1));
                [XY1, ~] = utils_detect_features_localmax_blur(T1);
                Mradon1 = utils_compute_local_radon_transform(T1, XY1, filterbank);
                [Mdist, Mtheta] = utils_compute_distance_between_radon_features(Mradon0, Mradon1);
                Mtheta = ones(size(Mtheta));
                [indexpairs, metrics, dtheta] = utils_align_radon_features(Mdist, Mtheta, Ntheta);
                A = utils_exhaustic_get_transformation_matrix(XY0,XY1,indexpairs,metrics);
                imglist(k).A2D = A - ref_info.offset;
                if any(isnan(A(:)))
                    disp(['Failed to match features: ', imglist(k).batch_name,' ',imglist(k).section_name]);
                    continue;
                end
                [~,S,~] = svd(A(1:2,1:2)/A0(1:2,1:2));
                [U,~,V] = svd(A(1:2,1:2));
                R = U*V';
                imglist(k).rotation = wrapToPi(atan2(R(3),R(1)))*180/pi;
                if (S(1)*S(4) > 0) && (abs(log(S(1)*S(4))) < t1) && (abs(log(S(1)/S(4))) < t2) % && (wrapToPi(abs(dtheta + atan2(R(3),R(1))))<(t3*pi/Ntheta))
                    imglist(k).isaligned = true;
                    IMG1t = imwarp(IMG1, affine2d(A),'nearest','OutputView',refcrd,'FillValues',255);
                    xc = nanmean(XX(IMG1t<255));
                    yc = nanmean(YY(IMG1t<255));
                    imglist(k).displacement = [xc,yc] - ref_info.centroid;
                    imglist(k).missing_area = sum(ref_mask(IMG1t==255))/tot_area;
                    % only put into reference stack if the section is not retaken
                    if ifrender(k)
                        A0 = A;
                        if any(strcmpi(already_written,imglist(k).section_name))
                            % do not overwrite at the first round
                            flag_p(k) = false;
                        else
                            imwrite(uint8(IMG1t),[output_dir,filesep,imglist(k).section_name,'.png']);
                            imglist(k).isrendered = true;
                            flag_p(k) = true;
                        end
                        T1t = imwarp(T1, affine2d(A),'OutputView',refcrd,'FillValues',0);
                        RefStack(:,:,StackPt) = T1t;
                        StackPt = StackPt + 1;
                        if StackPt > Nstack
                            StackPt = StackPt - Nstack;
                        end
                        % update reference
                        T0 = quantile(RefStack,0.75,3);
                        [XY0, ~] = utils_detect_features_localmax_blur(T0);
                        Mradon0 = utils_compute_local_radon_transform(T0, XY0, filterbank);
                    else
                        flag_p(k) = true;
                        imglist(k).isrendered = false;
                    end
                else
                    disp(['Transformation exceeds deformation constraint: ', imglist(k).batch_name,' ',imglist(k).section_name])
                    imglist(k).isaligned = false;
                    try
                        IMG1t = imwarp(IMG1, affine2d(A),'nearest','OutputView',refcrd,'FillValues',255);
                        xc = nanmean(XX(IMG1t<255));
                        yc = nanmean(YY(IMG1t<255));
                        imglist(k).displacement = [xc,yc] - ref_info.centroid;
                        imglist(k).missing_area = sum(ref_mask(IMG1t==255))/tot_area;
                        if ifrender(k)
                            if any(strcmpi(already_written,imglist(k).section_name))
                                % do not overwrite at the first round
                                flag_p(k) = false;
                            else
                                imwrite(uint8(IMG1t),[output_dir,filesep,imglist(k).section_name,'.png']);
                                imglist(k).isrendered = true;
                                flag_p(k) = true;
                            end
                        else
                            flag_p(k) = true;
                            imglist(k).isrendered = false;
                        end
                    catch
                        flag_p(k) = true;
                        disp('    Failed to apply transform.');
                    end
                end
                % -------------------------------------------------------------------%
            end

        end
    end
    for k = 1:Nimg
        if flag_p(k)
            continue;
        end
        if paligned(k)
          % previously aligned
            if (~mask_updated) && ~ifrender(k)
              % no mask update, no render requirement
              if xor(imglist(k).isrendered, ifrender(k))
                  anyluck = true;
                  imglist(k).isrendered = ifrender(k);
              end
              % no need to generate or read the transformed images
              continue
            end
            if imglist(k).isrendered && ifrender(k) && any(strcmpi(already_written,imglist(k).section_name))
                % preivously rendered and not overwritten, directly read from the output folder
                if mask_updated
                    IMG1t = imread([output_dir,filesep,imglist(k).section_name,'.png']);
                    imglist(k).missing_area = sum(ref_mask(IMG1t==255))/tot_area;
                end
                % already rendered, render status correct; only updating mask
                continue;
            end
            if scl == 1
                IMG1 = imread([imglist(k).folder, filesep, imglist(k).name]);
                IMG1 = IMG1(:,:,1);
            else
                IMG1o = imread([imglist(k).folder, filesep, imglist(k).name]);
                IMG1o = IMG1o(:,:,1);
                IMG1 = imresize(IMG1o,scl,'nearest');
            end
            IMG1t = imwarp(IMG1, affine2d(imglist(k).A2D + ref_info.offset),'nearest','OutputView',refcrd,'FillValues',255);
            if mask_updated
                imglist(k).missing_area = sum(ref_mask(IMG1t==255))/tot_area;
            end
            if ifrender(k)
                imwrite(uint8(IMG1t),[output_dir,filesep,imglist(k).section_name,'.png']);
                anyluck = true;
            end
            imglist(k).isrendered = ifrender(k);
        else
          % new alignment, but image not saved in the first round due to conflicts
            try
                if ifrender(k)
                    if scl == 1
                        IMG1 = imread([imglist(k).folder, filesep, imglist(k).name]);
                        IMG1 = IMG1(:,:,1);
                    else
                        IMG1o = imread([imglist(k).folder, filesep, imglist(k).name]);
                        IMG1o = IMG1o(:,:,1);
                        IMG1 = imresize(IMG1o,scl,'nearest');
                    end
                    IMG1t = imwarp(IMG1, affine2d(imglist(k).A2D + ref_info.offset),'nearest','OutputView',refcrd,'FillValues',255);
                    imwrite(uint8(IMG1t),[output_dir,filesep,imglist(k).section_name,'.png']);
                    imglist(k).isrendered = true;
                end
            catch
                disp(['Failed to apply transform: ', imglist(k).batch_name,' ',imglist(k).section_name])
            end
        end
    end
end

if anyluck
    alignment_info = struct;
    alignment_info.imglist = imglist;
    alignment_info.ref_info = ref_info;
    save([output_dir, filesep, 'alignment_info.mat'],'alignment_info');
end