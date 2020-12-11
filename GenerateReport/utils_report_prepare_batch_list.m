function [batch_list, wafer_info] = utils_report_prepare_batch_list(section_list,result_dir,batch_id)
    interval_thresh = 48*3600;  % the threshold of interval time
    if nargin < 3
        [~, ~, batch_id] = unique({section_list(:).batch_timestamp});
    end
    override = vertcat(section_list(:).override);
    override_scanfault = vertcat(override(:).scanfault);
    override_skew = vertcat(override(:).skew);
    override_jitter = vertcat(override(:).jitter);

    Nbatch = max(batch_id);
    wafer_info.batch_num = Nbatch;

    stt_times = vertcat(section_list(:).start_time);
    end_times = vertcat(section_list(:).end_time);
    mfov_nums = vertcat(section_list(:).mFoV_num);
    durations = max(vertcat(section_list(:).duration),[],2);
    AFASs = vertcat(section_list(:).AFAS);
    discardeds = vertcat(section_list(:).discarded);
    retakens = vertcat(section_list(:).retaken);
    disk_spaces = vertcat(section_list(:).storage);
    toretakes = vertcat(section_list(:).user_decision) == -1;
    kepts = (~toretakes) & (~retakens) & (~discardeds) & (~AFASs);

    scanfault_nums = vertcat(section_list(:).scanfault_num).*(1-override_scanfault(:));
    skew_nums = vertcat(section_list(:).distort_num).*(1-override_skew(:));
    jitter_nums = vertcat(section_list(:).jitter_num).*(1-override_jitter(:));

    scan_times = vertcat(section_list(:).scan_time);
    stage_times = vertcat(section_list(:).stage_movement_time);
    focus_times = vertcat(section_list(:).focus_time);
    stig_times = vertcat(section_list(:).stig_time);
    b2f_times = vertcat(section_list(:).b2f_time);

    user_comments = {section_list(:).user_comment};
    off_targets = contains(user_comments(:),{'OFF-TARGET'});
    partial_sections = contains(user_comments(:),{'BROKEN-SECTION';'COMING-IN-SECTION';'PARTIAL-SECTION'});
    bad_focuss = contains(user_comments(:),{'BAD-STIG';'SOFT-FOCUS';'BEAM-TO-FIBER-ERROR'});

    batch_info = struct;
    for k = 1:1:Nbatch
        idx = batch_id == k;
        idx1 = find(idx,1);
        batch_name = fileparts(section_list(idx1).folder);
        result_folder = [result_dir,filesep,batch_name];
        if isempty(batch_name)
            [~,batch_name] = fileparts(result_dir);
        end
        batch_info.batch_name = batch_name;
        batch_info.start_time = min(stt_times(idx));
        batch_info.end_time = max(end_times(idx));
        batch_info.run_time = max([nansum(durations(idx)),seconds(batch_info.end_time-batch_info.start_time)]);
        batch_info.ROI_num = sum(idx(:));
        batch_info.kept_ROI = sum(kepts(idx));
        batch_info.kept_ROI_time = nansum(durations(idx&kepts));
        batch_info.scan_time = nansum(scan_times(idx));
        batch_info.stage_time = nansum(stage_times(idx));
        batch_info.focus_time = nansum(focus_times(idx));
        batch_info.stig_time = nansum(stig_times(idx));
        batch_info.b2f_time = nansum(b2f_times(idx));
        batch_info.AFAS = sum(AFASs(idx));
        batch_info.mfov_num = nansum(mfov_nums(idx));
        batch_info.jitter_num = nansum(jitter_nums(idx));
        batch_info.skew_num = nansum(skew_nums(idx));
        batch_info.scanfault_num = nansum(scanfault_nums(idx));
        batch_info.off_target = sum(off_targets(idx));
        batch_info.bad_focus = sum(bad_focuss(idx));
        if exist([result_folder,filesep,'batch_info.txt'],'file')
            fid = fopen([result_folder,filesep,'batch_info.txt'],'r');
            tmpstr = fread(fid,inf,'*char');
            fclose(fid);
            batch_info.additional_info = tmpstr(:)';
        else
            batch_info.additional_info = '';
        end
        if k == 1
            batch_list = repmat(batch_info,Nbatch+1,1);
        else
            batch_list(k) = batch_info;
        end
    end
    batch_list(end).batch_name = 'Total';
    batch_list(end).start_time = min([batch_list(1:end-1).start_time]);
    batch_list(end).end_time = max([batch_list(1:end-1).end_time]);
    batch_list(end).run_time = nansum([batch_list(1:end-1).run_time]);
    batch_list(end).ROI_num = nansum([batch_list(1:end-1).ROI_num]);
    batch_list(end).kept_ROI = nansum([batch_list(1:end-1).kept_ROI]);
    batch_list(end).kept_ROI_time = nansum([batch_list(1:end-1).kept_ROI_time]);
    batch_list(end).scan_time = nansum([batch_list(1:end-1).scan_time]);
    batch_list(end).stage_time = nansum([batch_list(1:end-1).stage_time]);
    batch_list(end).focus_time = nansum([batch_list(1:end-1).focus_time]);
    batch_list(end).stig_time = nansum([batch_list(1:end-1).stig_time]);
    batch_list(end).b2f_time = nansum([batch_list(1:end-1).b2f_time]);
    batch_list(end).AFAS = nansum([batch_list(1:end-1).AFAS]);
    batch_list(end).mfov_num = nansum([batch_list(1:end-1).mfov_num]);
    batch_list(end).jitter_num = nansum([batch_list(1:end-1).jitter_num]);
    batch_list(end).skew_num = nansum([batch_list(1:end-1).skew_num]);
    batch_list(end).scanfault_num = nansum([batch_list(1:end-1).scanfault_num]);
    batch_list(end).off_target = nansum([batch_list(1:end-1).off_target]);
    batch_list(end).bad_focus = nansum([batch_list(1:end-1).bad_focus]);
    batch_list(end).additional_info = '';
    % get wafer level stats
    if Nbatch == 1
        wafer_info.EM_time = seconds(max(end_times) - min(stt_times));
        wafer_info.long_intvl = 0;
        wafer_info.run_time = wafer_info.EM_time;
        wafer_info.short_intvl = 0;
        wafer_info.short_intvl_avg = 0;
        batch_list(1).intvl = 0;
        batch_list(2).intvl = 0;
    else
        [bstt_time,idx] = sort([batch_list(1:end-1).start_time]);
        batch_list(1:end-1) = batch_list(idx);
        bend_time = [batch_list(1:end-1).end_time];
        intvls = max(0,seconds(bstt_time(2:end)-bend_time(1:end-1)));
        intvlst = [intvls(:);nan;nansum(intvls(:))];
        stupid_matlab_cell = num2cell(intvlst);
        [batch_list(:).intvl] = stupid_matlab_cell{:};
        shrt_intvl = nansum(intvls(intvls<interval_thresh));
        short_intvl_avg = max(0,nanmean(intvls(intvls<interval_thresh)));
        long_intvl = nansum(intvls(:)) - shrt_intvl;
        wafer_info.EM_time = seconds(max(end_times) - min(stt_times)) - long_intvl;
        wafer_info.long_intvl = long_intvl;
        wafer_info.run_time = batch_list(end).run_time;
        wafer_info.short_intvl = shrt_intvl;
        wafer_info.short_intvl_avg = short_intvl_avg;
    end
    wafer_info.total_ROI = length(section_list(:));
    wafer_info.kept_ROI = sum(kepts);
    wafer_info.kept_ROI_time = nansum(durations(kepts));
    wafer_info.kept_ROI_storage = nansum(disk_spaces(kepts));
    wafer_info.retake = sum(~kepts);
    wafer_info.retake_time = nansum(durations(~kepts));
    wafer_info.retake_storage = nansum(disk_spaces(~kepts));
    wafer_info.storage = nansum(disk_spaces(:));
    wafer_info.AFAS = sum(AFASs(:));
    wafer_info.AFAS_storage = nansum(disk_spaces(AFASs));
    wafer_info.AFAS_time = nansum(durations(AFASs));
    wafer_info.off_target = sum(off_targets(:));
    wafer_info.off_target_storage = nansum(disk_spaces(off_targets));
    wafer_info.off_target_time = nansum(durations(off_targets));
    wafer_info.bad_focus = sum(bad_focuss(:));
    wafer_info.bad_focus_storage = nansum(disk_spaces(bad_focuss));
    wafer_info.bad_focus_time = nansum(durations(bad_focuss));
    wafer_info.partial_section = sum(partial_sections(~retakens));
    wafer_info.jitter_rate = batch_list(end).jitter_num/batch_list(end).mfov_num;
    wafer_info.skew_rate = batch_list(end).skew_num/batch_list(end).mfov_num;
    wafer_info.scanfault_rate = batch_list(end).scanfault_num/batch_list(end).mfov_num;
end