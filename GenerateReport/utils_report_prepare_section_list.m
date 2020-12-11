function section_list = utils_report_prepare_section_list(result_dir)
    section_list = dir([result_dir,filesep,'**',filesep,'summary.mat']);
    if isempty(section_list)
        return
    end
    % remove uneccessary field
    section_list = rmfield(section_list,{'date','bytes','isdir','datenum'});
    Nsec = length(section_list);

    % add the alignment information
    if exist([result_dir,filesep,'aligned_overviews',filesep,'alignment_info.mat'],'file')
        load([result_dir,filesep,'aligned_overviews',filesep,'alignment_info.mat'],'alignment_info');
        imglist = alignment_info.imglist;
        imgUUIDs = {imglist(:).UUID};
        stack_aligned = true;
    else
        % see if the current folder is a batch folder
        if strcmp(result_dir(end),filesep)
            result_dir = result_dir(1:end-1);
        end
        wafer_dir = fileparts(result_dir);
        if exist([wafer_dir,filesep,'aligned_overviews',filesep,'alignment_info.mat'],'file')
            load([wafer_dir,filesep,'aligned_overviews',filesep,'alignment_info.mat'],'alignment_info');
            imglist = alignment_info.imglist;
            imgUUIDs = {imglist(:).UUID};
            stack_aligned = true;
        else
            stack_aligned = false;
        end
    end

    for k = 1:Nsec
        load([section_list(k).folder, filesep,section_list(k).name],'report_info');
        prot_info = report_info.prot_info; % information from protocol file
        section_list(k).section_dir = report_info.sectionDir; % original data directory
        section_list(k).section_dirn = fileparts(fileparts(report_info.sectionDirN)); % original data directory with label_name
      %% general status
        % if the section was discarded
        if exist([section_list(k).folder, filesep, 'discard'],'file')
            section_list(k).discarded = true;
        else
            section_list(k).discarded = false;
        end
        % check the user input about the section:
        % -1: retake; 1: noretake; 0: not verified
        if exist([section_list(k).folder, filesep, 'yesretake'],'file')
            section_list(k).user_decision = int8(-1);
        elseif exist([section_list(k).folder, filesep, 'noretake'],'file')
            section_list(k).user_decision = int8(1);
        else
            section_list(k).user_decision = int8(0);
        end
        section_list(k).AFAS = report_info.AFAS;
        section_list(k).errorRaised = report_info.metaErrRaised || report_info.processErrRaised;

      %% Operation finish status
        section_list(k).sfovOverlapCheckFinished = report_info.sfovOverlapCheckFinished;
        section_list(k).mfovOverlapCheckFinished = report_info.mfovOverlapCheckFinished;
        section_list(k).imgNumberCheckFinished = report_info.imgNumberCheckFinished;
        section_list(k).stageJitteringCheckFinished = report_info.stageJitteringCheckFinished;
        section_list(k).imageChargingCheckFinished = report_info.imageChargingCheckFinished;
        section_list(k).scanfaultCheckFinished = report_info.scanfaultCheckFinished;
        section_list(k).coordCheckFinished = ~report_info.coordStatus.errRaised;

      %% Other information
        section_list(k).storage = report_info.mfovBytes + report_info.metaBytes; % disk space in GB
        [batch_name, section_name] = fileparts(report_info.sectionDir);
        batch_name = batch_name(max(1,end-16):end);
        try
            section_name_cell = split(section_name,'_');
            section_namet = section_name_cell{end};
        catch
            section_namet = section_name;
        end
        section_list(k).section_name = section_namet;
        section_list(k).batch_timestamp = batch_name;
        UUID = [batch_name, char(0), section_namet]; % UUID to locate the alignment information

        % tile setup shown as tooltip of the section name column
        tile_setup = '';
        if ~isnan(prot_info.scanspeed)
            tile_setup =strcat(tile_setup,'ScanSpeed SS',num2str(prot_info.scanspeed));
        end
        if ~isempty(prot_info.tile_setup)
            if ~isempty(tile_setup)
                tile_setup = strcat(tile_setup,'&#13;',prot_info.tile_setup);
            else
                tile_setup = prot_info.tile_setup;
            end
        end
        section_list(k).tile_setup = tile_setup;

        % mFoV number
        section_list(k).mFoV_num = report_info.mfovNum;

        % FSP number and status
        FSP_success = (~report_info.focusMapData.AF)&(~report_info.focusMapData.AS);
        section_list(k).FSP_num = [sum(FSP_success(:)), max(report_info.fspNum,length(FSP_success(:)))];
        section_list(k).B2F_fail = prot_info.b2f_num(1)<prot_info.b2f_num(2);

        % acquisition time
        section_list(k).duration = [report_info.duration, prot_info.duration];
        section_list(k).start_time = prot_info.startTime;
        section_list(k).end_time = prot_info.endTime;
        section_list(k).stage_movement_time = prot_info.stgmv_time;
        section_list(k).scan_time = prot_info.acq_time;
        section_list(k).focus_time = prot_info.focus_time;
        section_list(k).stig_time = prot_info.stig_time;
        section_list(k).b2f_time = prot_info.b2f_time;

        % image and coordinate count
        section_list(k).thumb_coord_missing = report_info.coordStatus.mFoVwMissingThumbs;
        section_list(k).fullres_coord_missing = report_info.coordStatus.mFoVwMissingImgs;
        % missing image: positive; duplicate image: negative
        section_list(k).thumb_image_missing = [report_info.missingThumb(:);-report_info.dupThumb(:)];
        section_list(k).fullres_image_missing = [report_info.missingFullRes(:);-report_info.dupFullRes(:)];

        % metadata status
        section_list(k).regionmetadata_status = report_info.regionMetadataStatus;
        section_list(k).focusmap_status = report_info.focusMapStatus;
        section_list(k).protocol_status = report_info.protocolStatus;
        section_list(k).workflow_status = report_info.workflowStatus;

        % sFoV stitching
        section_list(k).sfov_stitch_status = report_info.sfovStitchStatus;
        section_list(k).sfov_rotation = report_info.sfovRotation;

        % mFoV stitching
        section_list(k).mFoV_gaps_num = size(report_info.gapsMfovPairs,1);
        section_list(k).mFoV_lowconf_num = size(report_info.lowConfMfovPairs,1);

        % IMQA
        section_list(k).IMQA_status = report_info.doIMQAPlot;
        section_list(k).IMQA = report_info.IMQA;
        section_list(k).worst_beams = report_info.worst_beams;

        % jitter, top-distortion and scanfault (# of mFoVs)
        section_list(k).jitter_num = report_info.stageJitter;
        section_list(k).distort_num = report_info.imageDistort;
        section_list(k).scanfault_num = report_info.scanFault;

        % user comment
        if exist([section_list(k).folder, filesep, 'user_comment.txt'],'file')
            fiduc = fopen([section_list(k).folder,filesep,'user_comment.txt'],'r');
            ucstr = fread(fiduc,inf,'*char');
            fclose(fiduc);
            section_list(k).user_comment = ucstr(:)';
        else
            section_list(k).user_comment = '';
        end

        % user manual override information
        override = struct;
        override.sfov_overlap = false;
        override.mfov_overlap = false;
        override.scanfault = false;
        override.jitter = false;
        override.skew = false;
        if exist([section_list(k).folder,filesep,'user_override.mat'],'file')
            load([section_list(k).folder,filesep,'user_override.mat'],'override');
            override.sfov_overlap = override.sfov_overlap > 0;
            override.mfov_overlap = override.mfov_overlap > 0;
            override.scanfault = override.scanfault > 0;
            override.jitter = override.jitter > 0;
            override.skew = override.skew > 0;
        end
        section_list(k).override = override;

        % alignment infomation
        % align_status: 0:not aligned; 1: aligned; 2:reference; 3: failed
        %   negative: alignment not rendered; positive: alignment rendered
        if stack_aligned
            tmpidx = find(strcmpi(imgUUIDs,UUID));
            if isempty(tmpidx)
                section_list(k).align_status = int8(0);
                section_list(k).align_missingarea = nan;
                section_list(k).align_rotation = nan;
                section_list(k).align_displacement = [nan, nan];
            else
                tmp_info = imglist(tmpidx(1));
                if tmp_info.isreference
                    align_status = 2; % reference
                elseif tmp_info.isaligned
                    align_status = 1; % aligment successful
                else
                    align_status = 3; % alignment failed
                end
                if ~tmp_info.isrendered
                    align_status = -align_status;
                end
                section_list(k).align_status = int8(align_status);
                section_list(k).align_missingarea = tmp_info.missing_area;
                section_list(k).align_rotation = tmp_info.rotation;
                section_list(k).align_displacement = tmp_info.displacement;
                imgUUIDs(tmpidx) = {''};
            end
        else
            section_list(k).align_status = int8(0);
            section_list(k).align_missingarea = nan;
            section_list(k).align_rotation = nan;
            section_list(k).align_displacement = [nan, nan];
        end
        section_list(k).folder = strrep(section_list(k).folder,result_dir,'');
        if strcmpi(section_list(k).folder(1),filesep)
            section_list(k).folder = section_list(k).folder(2:end);
        end
    end

    % re-order the sections
    % sort by the batch date
    [~,idx] = sort({section_list(:).batch_timestamp});
    section_list = section_list(idx);
    % put discarded ones to the very begining
    [~,idx] = sort([section_list(:).discarded],'descend');
    section_list = section_list(idx);
    % parse section names to section numbers
    [section_id, region_id]= local_get_section_and_region_id({section_list(:).section_name});
    section_id = section_id + region_id/1000;
    stupid_matlab_cell = num2cell(section_id);
    [section_list.section_id] = stupid_matlab_cell{:};
    [section_id,idx] = sort(section_id,'ascend','MissingPlacement','last');
    section_list = section_list(idx);
    [~, ia, ~] = unique(section_id,'last');
    retaken = true(Nsec,1);
    retaken(ia) = false;
    stupid_matlab_cell = num2cell(retaken);
    [section_list.retaken] = stupid_matlab_cell{:};

    section_list = rmfield(section_list,'name');
end

function [section_id, region_id]= local_get_section_and_region_id(section_names)
    Ns = length(section_names);
    section_id = nan(Ns,1,'single');
    region_id = nan(Ns,1,'single');
    section_str = [strjoin(section_names, [char(13),newline]), char(13), newline];
    try
        scanned_cell = textscan(section_str, '%*s%f%f', 'Delimiter', {'S','R'}, ...
            'ReturnOnError', 0);
        section_id = scanned_cell{1};
        region_id = scanned_cell{2};
    catch
        for k = 1:Ns
            str1 = section_names{k};
            fmtstr = '%*s%f%f';
            [scanned_cell, failidx] = textscan(str1,fmtstr,'Delimiter',{'S','R'});
            if isempty(scanned_cell{1})
                continue;
            end
            if isempty(scanned_cell{2})
                if failidx == length(str1)
                    scanned_cell{2} = 0;
                else
                    c1 = str1(failidx+1);
                    scanned_cell{2} = min(double(c1),255);
                end
            end
            section_id(k) = scanned_cell{1};
            region_id(k) = scanned_cell{2};
        end
    end
end