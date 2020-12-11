function [overlap_status, add_info] = Check_Overlap_For_One_Section(section_dir, coord_info, general_info, sys_result_dir, result_dir, verbose)
    % All the image processing stuff. Function named Check_OVerlap due to historical reasion
    % Perform image file counting & sFoV/mFoV overlap check & overview image preparation for ROI tracking.

    % coord_info & general_info: return from Check_All_Metadata_Files.m
    % sys_result_dir: local path to store intermediate results, not exposed to user.
    % result_dir: user-defined result folder
    % overlap_status: if a task has been finished
    % add_info: the results of the task

    % Yuelong Wu, Jan, 2019, re-written to increase readability & incorperate full-res check.
    ds_scl = 1/8;   % down-sample ratio from thumbnails to overview images

    pread = true;
    doScanFaultCheck = true;

    sfov_stitch_conf_thresh = 1.35;  % confidence threshold for sfov stitching
    mfov_stitch_conf_thresh = 5;  % confidence threshold for mfov stitching
    scanfault_thresh = 0.3; % threshold for detecting scanfault
    jitter_thresh = 0.15; % threshold for detecting jitter
    skew_thresh = 8; % threshold for detecting skew
    run_profiler = false;

    beam_num = 61;
    if nargin < 6
        verbose = true;
    end

    tstt = tic;
    if run_profiler
        profile('on')
    end
    try
        scanfaultfolerCreated = false;
        toperrfolderCreated = false;
        fullres_thres = struct;
        fullres_thres.scanfault_thresh = scanfault_thresh;
        fullres_thres.jitter_thresh = jitter_thresh;
        fullres_thres.skew_thresh = skew_thresh;
        mfov_num = general_info.mfov_num;
        [overlap_status, add_info] = local_initialize_output(beam_num, mfov_num);
        fullres_stitch_displacement = nan(2,mfov_num); % the displacement from full resolution stitching
        add_info.ds_scl = ds_scl;
        add_info.fullres_thres = fullres_thres;
        
        sys_output_dir = [sys_result_dir, filesep, 'overlap_info.mat'];
         % can save & return any point from here
        [result_parent,section_name] = fileparts(result_dir);
        ovv_dir = [result_parent, filesep, 'overview_imgs']; % folder to same overview images
        if ~exist(ovv_dir,'dir')
            mkdir(ovv_dir);
        end
        % sfov_overlap_dir = [result_parent,filesep,'maps',filesep,'sfov_overlap'];
        % if ~exist(sfov_overlap_dir,'dir')
        %     mkdir(sfov_overlap_dir);
        % end
        mfov_overlap_dir = [result_parent,filesep,'maps',filesep,'mfov_overlap'];
        if ~exist(mfov_overlap_dir,'dir')
            mkdir(mfov_overlap_dir);
        end
        scanfaultskew_dir = [result_parent,filesep,'maps',filesep,'charging_scanfault'];
        if ~exist(scanfaultskew_dir,'dir')
            mkdir(scanfaultskew_dir);
        end
        jitter_dir = [result_parent,filesep,'maps',filesep,'jitter'];
        if ~exist(jitter_dir,'dir')
            mkdir(jitter_dir);
        end
        % if 0 mfov, skip all the steps
        if mfov_num == 0
            if verbose
                fprintf(1,'\tNo mfov to process...\n');
            end
            save(sys_output_dir,'overlap_status','add_info');
            return
        end

        if verbose
            fprintf(1,'\tBuilding image inventories and checking overlap...\n');
        end
        doImgCheck = general_info.doImgCheck;
        doOtherCheck = general_info.doROITracking && general_info.doSfovOverlapCheck && ...
            general_info.doMfovOverlapCheck && general_info.doJittering;

        [beam_coord,~,directional_bsfov_idx] = config_beam_coord_vectors;
        % get mfov coordinates
        talpha = coord_info.thumb_alpha;
        tbeta = coord_info.thumb_beta;
        [mfov_x, mfov_y] = utils_get_target_mfov_xy(coord_info.thumbnail_coord.x,...
            coord_info.thumbnail_coord.y,talpha,tbeta,beam_coord);
        add_info.mfov_target_x = mfov_x;
        add_info.mfov_target_y = mfov_y;

        % if no need to do any check
        if (~doImgCheck) && (~doOtherCheck)
            save(sys_output_dir,'overlap_status','add_info');
            return
        end

        thumbpath = coord_info.thumbnail_coord.imgpath;
        fullrespath = coord_info.img_coord.imgpath;
        add_info.ovvstack_read = false(beam_num,mfov_num);
        thumb_sz = utils_get_img_size(section_dir,thumbpath);
        add_info.thumbsize = thumb_sz;
        % if only do image counting but not other checks:
        if doImgCheck && (~doOtherCheck)
            fprintf(1,'\t\tChecking image files...\n');
            try
                [add_info, overlap_status, overview_stack] = local_only_count_files(section_dir, mfov_num, ...
                    add_info, coord_info, overlap_status);
            catch
                fprintf(2,'\t\tFiles counting failed..\n');
            end
            try
                [~, sfov_coord, ~, ~] = utils_analyze_sfov_overlap_old(coord_info.thumb_alpha, ...
                    coord_info.thumb_beta, size(overview_stack,1), size(overview_stack, 2));
                overview_stack = local_normalize_overviewstack(overview_stack);
                overviewimg = utils_generate_overview_img(overview_stack, add_info.mfov_target_x,add_info.mfov_target_y, sfov_coord,ds_scl);
                imwrite(255-overviewimg,[ovv_dir,filesep,section_name,'.png']);
            catch
                fprintf(2,'\t\tOverview generation failed..\n');
            end
            save(sys_output_dir,'overlap_status','add_info');
            return
        end

    % From now on doOthrecheck = true
        % find the thumbnail image size
        thumb_scl = median((coord_info.img_coord.x(:))./(coord_info.thumbnail_coord.x(:)),'omitnan');
        
        % If no thumbnail found, still try to do image check and then return
        if any(isnan(thumb_sz))
            if verbose
                fprintf(2,'\t\tCannot find or open any thumbnail images: ');
                fprintf(1,'sFoV/mFoV overlap check will NOT be performed.\n');
            end
            try
                [add_info, overlap_status] = local_only_count_files(section_dir, mfov_num, ...
                    add_info, coord_info, overlap_status);
            catch
                fprintf(2,'\t\tFiles counting failed..\n');
            end
            save(sys_output_dir,'overlap_status','add_info');
            return
        end
        fullres_sz = utils_get_img_size(section_dir,fullrespath);
        if any(isnan(fullres_sz))
            doFullResCheck = false;
            add_info.fullres_check_status = 2*ones(1,mfov_num,'single');
        else
            add_info.fullressize = fullres_sz;
            doFullResCheck = true;
        end
        % prelocate memory for overview stack
        ovvsz = size(imresize(zeros(thumb_sz),ds_scl));
        overview_stack = nan(ovvsz(1),ovvsz(2),beam_num,mfov_num,'single');


    %% ---------------------------- sfov stitching  -------------------------- %%
        if verbose
            fprintf(1, '\tStitching sFoVs...\n');
        end
        %  sfov id on the boundary
        border_sfov_idx = (beam_num+4-(12*beam_num-3)^0.5):beam_num;
        N_border = length(border_sfov_idx);
        % plan the read-in order for mFoV overlap check to minimize RAM usage and read times
        if mfov_num > 1
            [route_mfov_idx, NmfovRAM, adjacent_mfovs, d_mfov, ~] = ...
                utils_plan_overlap_check_route(mfov_x,mfov_y,coord_info.thumb_alpha,coord_info.thumb_beta);
        else
            route_mfov_idx = 1;
            NmfovRAM = 1;
            adjacent_mfovs = nan(6,1,'single');
            d_mfov = ones(6,2) * norm(5*coord_info.thumb_beta + 4*coord_info.thumb_alpha);
        end
        add_info.mfovAdjacencies = adjacent_mfovs;
        add_info.d_mfov = d_mfov;
        %  read in the first sfov in each mfov to select sfov stitching mfovs
        [sfov1st, thumb_bytes1] = utils_read_thumbnail_stack(section_dir,thumbpath(1,:),thumb_sz,pread);
        sfov1st = utils_remove_background_erode(sfov1st);
        overview_stack(:,:,1,:) = local_downsample_image_stack(sfov1st, ds_scl);
        add_info.ovvstack_read(1,:) = true;
        add_info.thumBytes(1,:) = thumb_bytes1;
        [~, sampled_mfov_id] = maxk(thumb_bytes1,9);
        Nmfov = length(sampled_mfov_id);
        % prelocate RAM to save border mfov images
        QLen = min(mfov_num, NmfovRAM + Nmfov);  % length of the mfov stitching queue
        mfov_queue = zeros(thumb_sz(1),thumb_sz(2), N_border,QLen,'uint8');
        mfov_queue_ids = nan(QLen, 1, 'single');
        crntQpos = 1;
        rflag = true(size(thumbpath,1),1); % flag to tell utils_read_thumbnail_stack which sfov to read
        rflag(1) = false;
        for k = 1:Nmfov
            midx = sampled_mfov_id(k);
            % only read sfov 2-61 because sfov 1 already read
            [mfov_stack, thumb_bytes] = utils_read_thumbnail_stack(section_dir,thumbpath(:,midx),thumb_sz,pread,rflag);
            mfov_stack = utils_remove_background_erode(mfov_stack);
            mfov_stack(:,:,1) = sfov1st(:,:,1,midx);
            thumb_bytes(1) = thumb_bytes1(midx);

            % some house keeping stuff: 1. save thumbnail file size;
            %   2. put down-sampled image to overview stack, update ovv_stack read status;
            %   3. add boundary sfov thumbnails into the mfov overlap queue
            add_info.thumBytes(:,midx) = thumb_bytes;
            overview_stack(:,:,2:end,midx) = local_downsample_image_stack(mfov_stack(:,:,2:end), ds_scl);
            add_info.ovvstack_read(2:end,midx) = true;
            if crntQpos > QLen
                crntQpos = crntQpos - QLen;
            end
            mfov_queue(:,:,:,crntQpos) = mfov_stack(:,:,border_sfov_idx);
            mfov_queue_ids(crntQpos) = midx;
            crntQpos = crntQpos + 1;

            % stitch sampled mfovs
            [svs, scs] = utils_stitch_sfov_for_one_mfov(mfov_stack,talpha,tbeta);
            if k == 1
                sfov_vecs = cell(3,1);  % sfov relative positioning across each edge
                sfov_confs = cell(3,1); % confidence level of the sfov stitching at each edge
                for kd = 1:3
                    sfov_vecs{kd} = nan(size(svs{kd}, 1), size(svs{kd}, 2), Nmfov);  % Npairs x 2 x Nmfov
                    sfov_confs{kd} = nan(length(scs{kd}(:)), Nmfov); % Npairs x 1 x Nmfov
                end
            end
            for kd = 1:3
                sfov_vecs{kd}(:,:,k) = svs{kd};
                sfov_confs{kd}(:,k) = scs{kd};
            end
        end

        % apply weight according to the sfov thumbnail file size
        % (larger file size, less likely to have empty regions or blood vessles etc.)
        swts =  utils_get_sfov_wts_based_on_bytes(add_info.thumBytes(:,sampled_mfov_id));
        for kd = 1:3
            swt = swts{kd};
            swt(sfov_confs{kd} < sfov_stitch_conf_thresh) = 0;
            sfov_confs{kd} = max(0, utils_weighted_median(sfov_confs{kd}, swt, 2));
            % reshape the wts to match the data
            swt = repmat(permute(swt,[1,3,2]),1,size(sfov_vecs{kd}, 2),1);
            sfov_vecs{kd} = utils_weighted_median(sfov_vecs{kd}, swt, 3);
        end
        % analyze the stitched result to get sfov coord etc.
        [sfov_status, sfov_coord, mfov_img, stitched_alpha, stitched_beta, cornerpts_info] = ...
            utils_analyze_sfov_overlap(sfov_vecs, sfov_confs, sfov_stitch_conf_thresh, thumb_sz);
        % sfov_status: 0-normal;1-thin;2-gap;3-failed
        % try sfov stitch again, and this time replace the low-conf displacement with median of the others
        if sfov_status == 3 || sfov_status == 2
            if verbose
                fprintf(2,'\t\tFail to stitch sFoVs in the first attempt:');
                fprintf(1, 'trying to interpolate the low-confidence edges.\n');
            end
            sfov_rotation = utils_angle_between_vectors(coord_info.thumb_alpha,stitched_alpha);
            if sfov_rotation > 1
                tmp_rotated = true;
                kdd = 3;
            elseif sfov_rotation < -1
                tmp_rotated = true;
                kdd = 2;
            else
                tmp_rotated = false;
            end
            for kd = 1:3
                sfov_vec = sfov_vecs{kd};
                sfov_conf = sfov_confs{kd};
                if ~tmp_rotated
                    if sfov_status == 2 % if gap, replace outliers with median ans set weight to 0
                        outlier_idx = isoutlier(sfov_vec,'quartiles');
                        sfov_vec(outlier_idx) = nan;
                        sfov_conf(any(outlier_idx,2)) = 0;
                    end
                    m_svec_x =  median(sfov_vec(:,1),'omitnan');
                    m_svec_y =  median(sfov_vec(:,2),'omitnan');
                    sfov_vec(isnan(sfov_vec(:,1)),1) = m_svec_x;
                    sfov_vec(isnan(sfov_vec(:,2)),2) =  m_svec_y;
                    sfov_vecs{kd} = sfov_vec;
                    if any(sfov_conf > 0)   % minimize the weight for the intepolated values
                        % sfov_conf(sfov_conf==0) = sfov_stitch_conf_thresh + 0.1;
                        sfov_confs{kd} = sfov_conf;
                    end
                else
                    if kd == kdd
                        sfov_conf = 0 * sfov_conf;
                    else
                        outlier_idx = isoutlier(sfov_vec,'quartiles');
                        out_idx = any(outlier_idx,2);
                        sfov_conf(out_idx) = min( 0.1 + sfov_stitch_conf_thresh, sfov_conf(out_idx));
                    end
                    sfov_confs{kd} = sfov_conf;
                end
            end
            [sfov_status, sfov_coord, mfov_img, stitched_alpha, stitched_beta, cornerpts_info] = ...
                utils_analyze_sfov_overlap(sfov_vecs, sfov_confs, sfov_stitch_conf_thresh, thumb_sz);
        end

        switch sfov_status
            case 3      % if still cannot stitch, use coordinate files
                if verbose
                    fprintf(2,'\t\tFail to stitch sFoVs: ');
                    fprintf(1,'using coordinate files to determine sfov coordinate.\n');
                end
                % assume no variations in sfov placement
                stitched_alpha = coord_info.thumb_alpha;
                stitched_beta = coord_info.thumb_beta;
                [~, sfov_coord, ~, cornerpts_info] = utils_analyze_sfov_overlap_old(stitched_alpha, ...
                    stitched_beta, thumb_sz(1), thumb_sz(2));
                overlap_status.sfovOverlapCheckFinished = false;
            case 2
                if verbose
                    fprintf(2,'\t\tGaps present between sFoVs.')
                end
                overlap_status.sfovOverlapCheckFinished = true;
            case 1
                if verbose
                    fprintf(1,['\t\tsFoV stitching finished without error ',char(8718),'\n']);
                    fprintf(1,'\t\tWarning: thin overlap between sFoVs.\n');
                end
                overlap_status.sfovOverlapCheckFinished = true;
            otherwise
                if verbose
                    fprintf(1,['\t\tsFoV stitching finished without error ',char(8718),'\n']);
                end
                overlap_status.sfovOverlapCheckFinished = true;
        end
        % save ths sfov stitching status, corner_points of the mfov outline for later visualization
        %   and sfov coordinates
        add_info.sfov_stitch_status = sfov_status;
        add_info.cornerpts_info = cornerpts_info;
        add_info.sfov_coord = sfov_coord;
        % if stitch is successful, check if mFoV is rotated.
        if overlap_status.sfovOverlapCheckFinished
            sfov_rotation = utils_angle_between_vectors(coord_info.thumb_alpha,stitched_alpha);
            add_info.sfov_rotation = sfov_rotation;
            if verbose
                if (abs(add_info.sfov_rotation)) > 2
                    fprintf(2,['\t\tWarning: mFoV rotation detected (',num2str(add_info.sfov_rotation),' deg)\n']);
                end
            end
            % save the vectors: alpha beam 1 -> beam 2; beta: beam1 -> beam 3
            add_info.sfov_stitched_alpha = stitched_alpha;
            add_info.sfov_stitched_beta = stitched_beta;
            % output sfov overlap images to the user result folder
            imwrite(uint8(255*mfov_img),[result_dir,filesep,'sFoV_overlap.png']);
        else
            sfov_rotation = 0;
        end
        % preferrted direction that makes overlap larger to check jitter etc
        pref_direct =  sign(wthresh(sfov_rotation,'s',0.5));
        if isnan(pref_direct)
            pref_direct = 0;
        end

    %% ---------------------------- mfov stitching  -------------------------- %%
        if verbose
            fprintf(1,'\tStitching mFoVs and counting image files...\n');
        end
        % the boundary sFoVs along each direction
        % directional_bsfov_idx = [46:50;42:46;38:42;54:-1:50;58:-1:54;38,61:-1:58];
        dire_bq_idx = directional_bsfov_idx - min(directional_bsfov_idx(:))+1;
        % tolerance when searching for mFoV stitching
        tol_mfov = round((max(abs(sfov_rotation),0)/5 + 1)* min(thumb_sz));
        [border_template_idx, border_mask, mosaic_displacement] = ...
            utils_prepare_border_template(directional_bsfov_idx, sfov_coord,thumb_sz,d_mfov,tol_mfov);
        % pre-allocate memories for stitched boarder sFoVs
        border_template16 = zeros(size(border_mask{1},1),size(border_mask{1},2),2,'single');
        blen1 = length(border_template16(:))/2;
        border_template25 = zeros(size(border_mask{2},1),size(border_mask{2},2),2,'single');
        blen2 = length(border_template25(:))/2;
        border_template34 = zeros(size(border_mask{3},1),size(border_mask{3},2),2,'single');
        blen3 = length(border_template34(:))/2;

        for m = 1:mfov_num

            m1 = route_mfov_idx(m);     % current mfov
            neighbor_mfovs_6 = adjacent_mfovs(:,m1);
            neighbor_mfovs = neighbor_mfovs_6(~isnan(neighbor_mfovs_6));    % all the neighboring mfovs
            relevant_mfovs = [m1; neighbor_mfovs];

            % --------first read in all relevant mFoVs into queue & count images -----%
            to_read = ~ismember(relevant_mfovs(:),mfov_queue_ids(:));
            for k = 1:length(relevant_mfovs(:))
                kidx = relevant_mfovs(k);
                if to_read(k)
                    [mfov_stack, thumb_bytes] = utils_read_thumbnail_stack(section_dir,thumbpath(:,kidx),thumb_sz,pread,rflag);
                    mfov_stack = utils_remove_background_erode(mfov_stack);
                    % some house keeping stuff: 1. save thumbnail file size;
                    %   2. put down-sampled image to overview stack, update ovv_stack read status;
                    %   3. add boundary sfov thumbnails into the mfov overlap queue
                    add_info.thumBytes(rflag,kidx) = thumb_bytes(rflag);
                    overview_stack(:,:,rflag,kidx) = local_downsample_image_stack(mfov_stack(:,:,rflag), ds_scl);
                    add_info.ovvstack_read(rflag,kidx) = true;
                    crntQpos = find(isnan(mfov_queue_ids),1);
                    mfov_queue(:,:,:,crntQpos) = mfov_stack(:,:,border_sfov_idx);
                    mfov_queue_ids(crntQpos) = kidx;
                end
                % Count the image files
                if isnan(add_info.imgCount(kidx)) || isnan(add_info.thumbCount(kidx))
                    mfov_folder = [section_dir, filesep, pad(num2str(kidx),6,'left','0')];
                    [thumb_count, img_count, mfov_bytes] = utils_count_files_in_mfov_folder(mfov_folder);
                    add_info.imgCount(kidx) = img_count;
                    add_info.thumbCount(kidx) = thumb_count;
                    add_info.mfovBytes(kidx) = mfov_bytes;
                end
            end
            % ---------------------------------------------------------------------- %

            % --------- do jitter/charging/scanfault test for current mFoV --------- %
            % select two sfovs to do test
            thumb_bytes = add_info.thumBytes(:,m1);
            missing_imgs = cellfun(@isempty,fullrespath(:,m1));
            thumb_bytes(missing_imgs) = nan;
            if sfov_status == 2 % gap between sfovs
                sfov_pairs = utils_select_sfovs_based_on_bytes_gap(thumb_bytes, sfov_coord);
            else
                sfov_pairs = utils_select_sfovs_based_on_bytes(thumb_bytes, pref_direct);
            end
            add_info.fullres_sampled_sfov(:,m1) = sfov_pairs(:);
            if doFullResCheck
                if any(isnan(sfov_pairs))
                    add_info.fullres_check_status = 3; % coordinate error
                    continue;
                else
                    % check the jitter, scanfault etc.
                    % if m1 == 47
                    %    disp('debug')
                    % end
                    [fullres_check, fullres_status, err_imgs] = utils_full_res_check(section_dir,fullrespath(sfov_pairs,m1),...
                        sfov_coord(sfov_pairs,:)*thumb_scl,fullres_sz, doScanFaultCheck, fullres_thres);
                    add_info.fullres_check_status(m1) = fullres_status;
                    add_info.stage_jitter_amp(m1) = fullres_check.jitter_amp;
                    add_info.stage_jitter_freq(m1) = fullres_check.jitter_freq;
                    add_info.top_distortion_amp(m1) = fullres_check.top_distort_amp;
                    add_info.top_distortion_length(m1) = fullres_check.top_distort_length;
                    add_info.mfov_scanfault(m1) = fullres_check.scanfault;
                    add_info.mfov_scanfault_pos(m1) = fullres_check.scanfault_pos;
                    fullres_stitch_displacement(:,m1) = fullres_check.displacement(:);

                    % save the scanfault images, if any
                    if ~isempty(err_imgs.scanfault)
                        scanfault_dir = [result_dir,filesep, 'scanfault'];
                        if ~scanfaultfolerCreated
                            if ~exist(scanfault_dir,'dir')
                                mkdir(scanfault_dir);
                            end
                            scanfaultfolerCreated = true;
                        end
                        imwrite(err_imgs.scanfault, [scanfault_dir,filesep,'mFoV',num2str(m1),'_Row',...
                            num2str(fullres_check.scanfault_pos),'.jpg']);
                    end
                    if ~isempty(err_imgs.top_err)
                        toperr_dir = [result_dir,filesep, 'distortion_jitter'];
                        if ~toperrfolderCreated
                            if ~exist(toperr_dir,'dir')
                                mkdir(toperr_dir);
                            end
                            toperrfolderCreated = true;
                        end
                        if fullres_check.top_distort_amp > 0
                            tmpstr1 = 'distortion_';
                        else
                            tmpstr1 = [];
                        end
                        if fullres_check.jitter_amp > 0
                            tmpstr2 = 'jitter_';
                        else
                            tmpstr2 = [];
                        end
                        imwrite(err_imgs.top_err, [toperr_dir,filesep,tmpstr1,tmpstr2, ...
                            'mFoV',num2str(m1),'.jpg']);
                    end
                end
            end
            % ---------------------------------------------------------------------- %

            % -------------------------- check mFoV overlap ------------------------ %
            % use neighbor_mfovs_6 to get direction info
            for k = 1:length(neighbor_mfovs_6)
                m2 = neighbor_mfovs_6(k);
                if isnan(m2)
                    continue
                end
                % find the indexing number in the mFoV queue
                qidx1 = find(mfov_queue_ids == m1,1);
                qidx2 = find(mfov_queue_ids == m2,1);
                switch min(k, 7-k)
                case 1
                    tmpstack = imfilter(single(cat(3,mfov_queue(:,:,dire_bq_idx(k,:),...
                        qidx1),mfov_queue(:,:,dire_bq_idx(7-k,:),qidx2))),...
                        fspecial('log'),'symmetric');
                    border_template16(:) = nanmean(tmpstack(:));
                    border_template16([border_template_idx{k};border_template_idx{7-k}+blen1])= tmpstack;
                    [mfov_displc, conf] = utils_estimate_mfov_displacement(border_template16, border_mask{k},...
                        mosaic_displacement(k,:), d_mfov(k,:));
                case 2
                    tmpstack = imfilter(single(cat(3,mfov_queue(:,:,dire_bq_idx(k,:),...
                        qidx1),mfov_queue(:,:,dire_bq_idx(7-k,:),qidx2))),...
                        fspecial('log'),'symmetric');
                    border_template25(:) = nanmean(tmpstack(:));
                    border_template25([border_template_idx{k};border_template_idx{7-k}+blen2]) = tmpstack;
                    [mfov_displc, conf] = utils_estimate_mfov_displacement(border_template25, border_mask{k},...
                        mosaic_displacement(k,:), d_mfov(k,:));
                case 3
                    tmpstack = imfilter(single(cat(3,mfov_queue(:,:,dire_bq_idx(k,:),...
                        qidx1),mfov_queue(:,:,dire_bq_idx(7-k,:),qidx2))),...
                        fspecial('log'),'symmetric');
                    border_template34(:) = nanmean(tmpstack(:));
                    border_template34([border_template_idx{k};border_template_idx{7-k}+blen3])=tmpstack;
                    [mfov_displc, conf] = utils_estimate_mfov_displacement(border_template34, border_mask{k},...
                        mosaic_displacement(k,:), d_mfov(k,:));
                end
                add_info.mfovRelativePositionX(k,m1) = mfov_displc(1);
                add_info.mfovRelativePositionX(7-k,m2) = -mfov_displc(1);
                add_info.mfovRelativePositionY(k,m1) = mfov_displc(2);
                add_info.mfovRelativePositionY(7-k,m2) = -mfov_displc(2);
                add_info.mfovRelativeConf(k,m1) = conf;
                add_info.mfovRelativeConf(7-k,m2) = conf;
                adjacent_mfovs(k,m1) = nan;
                adjacent_mfovs(7-k,m2) = nan;
            end
            % release queue
            for k = 1:length(relevant_mfovs)
                if all(isnan(adjacent_mfovs(:,relevant_mfovs(k))))
                    mfov_queue_ids(mfov_queue_ids == relevant_mfovs(k)) = nan;
                end
            end
            % ---------------------------------------------------------------------- %
        end
    %% ---------------------------- combine results  -------------------------- %%
        % ------------------------- update status ------------------------------ %
        if all(~isnan(add_info.imgCount)) && all(~isnan(add_info.thumbCount))
            overlap_status.imgNumberCheckFinished = true;
            if verbose
                fprintf(1,'\t\tImage file count finished without error.\n');
            end
        else
            if verbose
                fprintf(2,'\t\tImage file count not finished.\n');
            end
        end
        if all(~isnan(add_info.stage_jitter_amp(add_info.thumbCount>0 & add_info.imgCount>0)))
            overlap_status.stageJitteringCheckFinished = true;
            if verbose
                fprintf(1,'\t\tStage settling check finished without error.\n');
            end
        else
            if verbose
                fprintf(2,'\t\tStage settling check not finished.\n');
            end
        end
        if all(~isnan(add_info.top_distortion_amp(add_info.thumbCount>0 & add_info.imgCount>0)))
            overlap_status.imageChargingCheckFinished = true;
            if verbose
                fprintf(1,'\t\tImage distortion check finished without error.\n');
            end
        else
            if verbose
                fprintf(2,'\t\tImage distortion check not finished.\n');
            end
        end
        if all(~isnan(add_info.mfov_scanfault(add_info.thumbCount>0 & add_info.imgCount>0)))
            overlap_status.scanfaultCheckFinished = true;
            if verbose
                fprintf(1,'\t\tScan-fault check finished whitout error.\n');
            end
        else
            if verbose
                fprintf(2,'\t\tScan-fault check not finished.\n');
            end
        end
        adjacent_mfovs(:,add_info.thumbCount==0) = nan;
        adjacent_mfovs(ismember(adjacent_mfovs,find(add_info.thumbCount==0))) = nan;
        if all(isnan(adjacent_mfovs(:)))
            overlap_status.mfovOverlapCheckFinished = true;
            if verbose
                fprintf(1,'\t\tmFoVs stitching finished whitout error.\n');
            end
        else
            if verbose
                fprintf(2,'\t\tmFoVs stitching not finished.\n');
            end
        end
            % -------------------------print results---------------------- %
        if verbose && overlap_status.imgNumberCheckFinished
            mfov_id_thumb_missing = find(add_info.thumbCount ~= coord_info.thumbnail_coord.expected_img_count);
            mfov_id_img_missing = find(add_info.imgCount ~= coord_info.img_coord.expected_img_count);
            if ~isempty(mfov_id_img_missing)
                fprintf(2,'\t\tmFovs with full-res images missing: ');
                fprintf(1, [utils_convert_id_vector_into_str(mfov_id_img_missing),'\n']);
            end
            if ~isempty(mfov_id_thumb_missing)
                fprintf(2,'\t\tmFovs with thumbnail images missing: ');
                fprintf(1, [utils_convert_id_vector_into_str(mfov_id_thumb_missing),'\n']);
            end
            if isempty(mfov_id_img_missing) && isempty(mfov_id_thumb_missing)
                fprintf(1,['\t\tNo image file missing ',char(8718),'\n']);
            end
        end
        if verbose && overlap_status.stageJitteringCheckFinished
            jitter_num = nansum(add_info.stage_jitter_amp>0);
            if jitter_num > 0
                fprintf(2,['\t\t',num2str(jitter_num),' mFoVs have stage settling error\n']);
            else
                fprintf(1,['\t\tNo stage settling error detected ',char(8718),'\n']);
            end
        end
        if verbose && overlap_status.imageChargingCheckFinished
            distort_num = nansum(add_info.top_distortion_amp>0);
            if distort_num > 0
                fprintf(2,['\t\t',num2str(distort_num),' mFoVs have image distortion at the top\n']);
            else
                fprintf(1,['\t\tNo image distortion detected ',char(8718),'\n']);
            end
        end
        if verbose && doScanFaultCheck && overlap_status.scanfaultCheckFinished
            scanfault_num = nansum(add_info.mfov_scanfault(:));
            if scanfault_num > 0
                fprintf(2,['\t\t',num2str(scanfault_num),' mFoVs have scan-fault error\n']);
            else
                fprintf(1,['\t\tNo scan-fault detected ',char(8718),'\n']);
            end
        end
        % ---------------------------------------------------------------------- %

        % ------------ adjust sFoV stitching use full-res results -------------- %
        if overlap_status.sfovOverlapCheckFinished
            add_info = utils_adjust_sfov_stitch(add_info, fullres_stitch_displacement/thumb_scl);
        end
        % ---------------------------------------------------------------------- %

        % ---------- estimate absolute mfov coordinates to find gaps ----------- %
        if overlap_status.mfovOverlapCheckFinished
            [mfov_stitched_x, mfov_stitched_y, mfov_stitched_groups]= ...
                utils_compute_absolute_mfov_coord(add_info.mfovRelativePositionX,...
                add_info.mfovRelativePositionY, add_info.mfovRelativeConf, ...
                mfov_stitch_conf_thresh, add_info.mfovAdjacencies, d_mfov, mfov_x, mfov_y);
            add_info.mfov_stitched_x = mfov_stitched_x;
            add_info.mfov_stitched_y = mfov_stitched_y;
            add_info.mfov_stitched_groups = mfov_stitched_groups;
            [gapMfovPairs, lowConfMfovPairs] = utils_analysis_mfov_overlap(add_info);
            add_info.gapsMfovPairs = gapMfovPairs;
            add_info.lowConfMfovPairs = lowConfMfovPairs;
            if verbose
                if ~isempty(gapMfovPairs)
                    fprintf(2,['\t\t',num2str(size(gapMfovPairs,1)),' gaps present between mFoVs.\n']);
                end
                if ~isempty(lowConfMfovPairs)
                    fprintf(1,['\t\tWarning: ',num2str(size(lowConfMfovPairs,1)),' mFoV overlap regions with low-confidence.\n']);
                end
                if isempty(gapMfovPairs) && isempty(lowConfMfovPairs)
                    fprintf(1,['\t\tNo gaps found between mFoVs ',char(8718),'\n']);
                end
            end
        end
        % ---------------------------------------------------------------------- %
        % ----------- save overlap map & output overlap gap images ------------- %
        houtfig = figure(921);
        clf(houtfig,'reset');
        set(houtfig,'Visible','off')
        set(houtfig,'Units','normalized');
        set(houtfig,'OuterPosition',[0.03 0.24 0.8 0.75]);
        set(houtfig,'Units','points');
        Pos = get(houtfig,'Position');
        set(houtfig,'PaperUnits','points');
        set(houtfig,'PaperSize',[Pos(3),Pos(4)]);
        set(houtfig,'PaperPosition',[0, 0, Pos(3),Pos(4)]);
        
        % mFoV overlap & image count
        if overlap_status.mfovOverlapCheckFinished
            missing_img = ~((add_info.thumbCount >= coord_info.thumbnail_coord.expected_img_count) & ...
                (add_info.imgCount >= coord_info.img_coord.expected_img_count));
            if ~isempty(gapMfovPairs) || ~isempty(lowConfMfovPairs) || any(missing_img)
                clf(houtfig);
                visualize_mfov_overlap(add_info,general_info.section_dirn,missing_img,houtfig);
                print(houtfig,[mfov_overlap_dir, filesep, section_name,'.pdf'],'-painters','-dpdf');
            end
            % output overlap gap images
            utils_output_overlap_err_img([result_dir,filesep,'overlap_errors'], general_info, coord_info, ...
                add_info, gapMfovPairs, [], directional_bsfov_idx, pread);
        else
            add_info.mfov_stitched_x = mfov_x;
            add_info.mfov_stitched_y = mfov_y;
        end
        if overlap_status.imageChargingCheckFinished || overlap_status.scanfaultCheckFinished
            if any(add_info.top_distortion_amp>0) || any(add_info.mfov_scanfault>0)
                clf(houtfig);
                visualize_top_distortion(add_info,general_info.section_dirn,houtfig)
                print(houtfig,[scanfaultskew_dir, filesep, section_name,'.pdf'],'-painters','-dpdf');
            end
        end
        if overlap_status.stageJitteringCheckFinished
            if any(add_info.stage_jitter_amp>0)
                clf(houtfig);
                visualize_stage_jitter(add_info,general_info.section_dirn,houtfig)
                print(houtfig,[jitter_dir, filesep, section_name,'.pdf'],'-painters','-dpdf');
            end
        end
        close(houtfig);
        % ---------------------------------------------------------------------- %

        % -------------------- save result/overview_imgs ----------------------- %
        save(sys_output_dir,'overlap_status','add_info');
        % if mfov_num > 2000
        %     save([sys_result_dir, filesep, 'ovvstack.mat'], 'overview_stack');
        % end
        overview_stack = local_normalize_overviewstack(overview_stack);
        overviewimg = utils_generate_overview_img(overview_stack, add_info.mfov_stitched_x,add_info.mfov_stitched_y,add_info.sfov_coord,ds_scl);
        imwrite(255-overviewimg,[ovv_dir,filesep,section_name,'.png']);
        if all(add_info.ovvstack_read(:))
           overlap_status.overviewImgGenerated = true; 
        end
        fprintf(1,['\t\tOverview image generated',char(8718),'\n']);
        % ---------------------------------------------------------------------- %
        if run_profiler
            profile('off')
            profile('viewer')
        end
        if verbose
            elps_t = toc(tstt);
            fprintf(1,['\t\tElapsed time: ',num2str(elps_t),' seconds.\n']);
        end
    catch overlapME
        if verbose
            fprintf(2,'\t\tUnexpected error happened when checking overlap status.\n')
            fprintf(2,['\t\t\tMATLAB err msg: ', strrep(overlapME.message,'\','\\'),'\n'])
        end
        try
            read_recipients_and_send_emails('[mSEM Notification] RetakeManager Error',['Check_Overlap_For_One_Section:', strrep(overlapME.message,'\','\\')],3)
        catch
        end
        overlap_status.errRaised = true;
        save(sys_output_dir,'overlap_status','add_info','overlapME');
        if doOtherCheck
            try
                overview_stack = local_normalize_overviewstack(overview_stack);
                overviewimg = utils_generate_overview_img(overview_stack, add_info.mfov_stitched_x,add_info.mfov_stitched_y,add_info.sfov_coord,ds_scl);
                imwrite(255-overviewimg,[ovv_dir,filesep,section_name,'.png']);
            catch
            end
        end
    end
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%% subfunctions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function overview_stack = local_normalize_overviewstack(overview_stack)
    % overview_stack = uint8(overview_stack*7);
    overview_stack = uint8(overview_stack*250/quantile(overview_stack(:),0.995));
end

function ds_stack = local_downsample_image_stack(input_stack, scl)
    ds_stack = imresize(single(input_stack), scl);
end

function [overlap_status, add_info] = local_initialize_output(beam_num, mfov_num)
    overlap_status = struct;
    overlap_status.errRaised = false;
    overlap_status.sfovOverlapCheckFinished = false;
    overlap_status.mfovOverlapCheckFinished = false;
    overlap_status.imgNumberCheckFinished = false;
    overlap_status.overviewImgGenerated = false;
    overlap_status.stageJitteringCheckFinished = false;
    overlap_status.imageChargingCheckFinished = false;
    overlap_status.scanfaultCheckFinished = false;

    add_info = struct;
    add_info.gapsMfovPairs = [];
    add_info.lowConfMfovPairs = [];
    add_info.mfovAdjacencies = nan(6,mfov_num,'single');
    add_info.d_mfov = nan(6,2);
    add_info.mfovRelativePositionX = nan(6,mfov_num,'single');
    add_info.mfovRelativePositionY = nan(6,mfov_num,'single');
    add_info.mfovRelativeConf = nan(6,mfov_num,'single');
    add_info.imgCount = nan(1,mfov_num,'single');
    add_info.thumbCount = nan(1,mfov_num,'single');
    add_info.mfovBytes = zeros(1,mfov_num,'single');
    add_info.thumBytes = nan(beam_num,mfov_num,'single');
    add_info.thumbsize = [0,0];
    add_info.fullressize = [0,0];
    add_info.mfov_target_x = nan(1,mfov_num);
    add_info.mfov_target_y = nan(1,mfov_num);
    add_info.mfov_stitched_x = nan(1,mfov_num);
    add_info.mfov_stitched_y = nan(1,mfov_num);
    add_info.mfov_stitched_groups = ones(1,mfov_num,'single');
    add_info.sfov_stitched_alpha = [nan;nan];
    add_info.sfov_stitched_beta = [nan;nan];
    add_info.sfov_coord = nan(beam_num,2);
    add_info.sfov_stitch_status = 0;
    add_info.sfov_rotation = nan;
    add_info.fullres_sampled_sfov = nan(2,mfov_num,'single');
    add_info.stage_jitter_amp = nan(1,mfov_num,'single');
    add_info.stage_jitter_freq = nan(1,mfov_num,'single');
    add_info.top_distortion_amp = nan(1,mfov_num,'single');
    add_info.top_distortion_length = nan(1,mfov_num,'single');
    add_info.mfov_scanfault = nan(1,mfov_num,'single');
    add_info.mfov_scanfault_pos = nan(1,mfov_num,'single');
    % fullres_check_status: 3-coordinate error; 2-reading error;
    %   1-computational error; 0-normal.
    add_info.fullres_check_status = nan(1,mfov_num,'single');
    add_info.cornerpts_info = struct;
    add_info.cornerpts_info.cornerpts = zeros(1,2);
    add_info.cornerpts_info.concave_bool = false;
    add_info.cornerpts_info.corner_direct = 1;
end

function [add_info, overlap_status, ovv_stack] = local_only_count_files(section_dir, mfov_num, add_info, coord_info, overlap_status, pread)
    if nargin < 6
        pread = true;
    end
    fprintf(1,'\t\tChecking image files...\n');
    ovv_stack = 0;
    ovvRAM = true;
    beam_num = size(add_info.sfov_coord,1);
    for m = 1:mfov_num
        mfov_folder = [section_dir, filesep, pad(num2str(m),6,'left','0')];
        if nargout > 2
            instack = add_info.ovvstack_read(:,m);
            if any(~instack)
                if ovvRAM
                    ovvsz = size(imresize(zeros(add_info.thumbsize),add_info.ds_scl));
                    ovv_stack = nan(ovvsz(1),ovvsz(2),beam_num,mfov_num,'single');
                    ovvRAM = false;
                end
                [mfov_stack, ~] = utils_read_thumbnail_stack(section_dir,coord_info.thumbnail_coord.imgpath(:,m),...
                    add_info.thumbsize,pread,~instack);
                mfov_stack = utils_remove_background_erode(mfov_stack);
                ovv_stack(:,:,~instack, m) = local_downsample_image_stack(mfov_stack(:,:,~instack), add_info.ds_scl);
                add_info.ovvstack_read(:,m) = true;
            end
        end
        [thumb_count, img_count, mfov_bytes] = utils_count_files_in_mfov_folder(mfov_folder);
        add_info.mfovBytes(m) = mfov_bytes;
        add_info.imgCount(m) = img_count;
        add_info.thumbCount(m) = thumb_count;
    end
    if all(~isnan(add_info.imgCount)) && all(~isnan(add_info.thumbCount))
        overlap_status.imgNumberCheckFinished = true;
        verbose = true;
        if verbose
            mfov_id_thumb_missing = find(add_info.thumbCount < coord_info.thumbnail_coord.expected_img_count);
            mfov_id_img_missing = find(add_info.imgCount < coord_info.img_coord.expected_img_count);
            fprintf(1,'\t\tImage file validation finished.\n');
            if ~isempty(mfov_id_img_missing)
                fprintf(2,'\t\tmFovs with full-res images missing: ');
                fprintf(1, [utils_convert_id_vector_into_str(mfov_id_img_missing),'\n']);
            end
            if ~isempty(mfov_id_thumb_missing)
                fprintf(2,'\t\tmFovs with thumbnail images missing: ');
                fprintf(1, [utils_convert_id_vector_into_str(mfov_id_thumb_missing),'\n']);
            end
            if isempty(mfov_id_img_missing) && isempty(mfov_id_thumb_missing)
                fprintf(1,['\t\t0 image files missing ',char(8718),'\n']);
            end
        end
    end
end
