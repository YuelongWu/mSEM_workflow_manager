function tablestr = utils_batch_table(batch_list)
    nl = [char(13),newline];
    idt1 = char(9);
    Nb = length(batch_list);
    TRs = cell(Nb,1);
    for k = 1:Nb
        TRs{k} = local_tr_one_batch(batch_list(k));
    end
    tablestr = ['<table id="batchTable">',nl,...
    local_tr_batch_thead,...
    idt1,'<tbody>',...
    horzcat(TRs{:}),...
    idt1,'</tbody>',...
    '</table>',nl];
end

function trstr = local_tr_one_batch(batch_info)
    nb = '&nbsp;&nbsp;';
    nl = [char(13),newline];
    idt2 = [char(9),char(9)]; idt3 = [char(9),char(9),char(9)];
    td_batchname = [idt3, '<td style="border-right:5px double silver;">',batch_info.batch_name,nb,'</td>',nl];
    td_runtime = [idt3,'<td>',num2str(batch_info.run_time/3600,'%.3f'),' hr',nb,'</td>',nl];
    td_downtime = [idt3,'<td>',strrep([num2str(batch_info.intvl/3600,'%.3f'),' hr'], 'NaN hr','--'),nb,'</td>',nl];
    td_ROInum = [idt3,'<td>',num2str(batch_info.ROI_num,'%d'),nb,'</td>',nl];
    td_ROIkept = [idt3,'<td>',num2str(batch_info.kept_ROI,'%d'),' ',...
        local_percent_span_tag_p(batch_info.kept_ROI/batch_info.ROI_num),nb,'</td>',nl];
    td_ROIkeptime = [idt3,'<td style="border-right:3px solid silver;">',num2str(batch_info.kept_ROI_time/3600,'%.3f'),' hr',...
        local_percent_span_tag_p(batch_info.kept_ROI_time/batch_info.run_time),nb,'</td>',nl];
    td_scantime = [idt3,'<td>',num2str(batch_info.scan_time/3600,'%.3f'),' hr',...
        local_percent_span_tag_p(batch_info.scan_time/batch_info.run_time),nb,'</td>',nl];
    td_stagetime = [idt3,'<td>',num2str(batch_info.stage_time/3600,'%.3f'),' hr',...
        local_percent_span_tag_p(batch_info.stage_time/batch_info.run_time),nb,'</td>',nl];
    td_focustime = [idt3,'<td>',num2str(batch_info.focus_time/3600,'%.3f'),' hr',...
        local_percent_span_tag_p(batch_info.focus_time/batch_info.run_time),nb,'</td>',nl];
    td_stigtime = [idt3,'<td>',num2str(batch_info.stig_time/3600,'%.3f'),' hr',...
        local_percent_span_tag_p(batch_info.stig_time/batch_info.run_time),nb,'</td>',nl];
    td_b2ftime = [idt3,'<td style="border-right:3px solid silver;">',num2str(batch_info.b2f_time/3600,'%.3f'),' hr',...
        local_percent_span_tag_p(batch_info.b2f_time/batch_info.run_time),nb,'</td>',nl];
    td_AFAS = [idt3,'<td title="AFAS failure">',num2str(batch_info.AFAS,'%d'),...
        local_percent_span_tag_p(batch_info.AFAS/batch_info.ROI_num),nb,'</td>',nl];
    td_badfocus = [idt3,'<td title="soft focus/bad stig/b2f error">',num2str(batch_info.bad_focus,'%d'),...
        local_percent_span_tag_p(batch_info.bad_focus/batch_info.ROI_num),nb,'</td>',nl];
    td_offtarget = [idt3,'<td>',num2str(batch_info.off_target,'%d'),...
        local_percent_span_tag_p(batch_info.off_target/batch_info.ROI_num),nb,'</td>',nl];
    td_jitterrate = [idt3,'<td title="per 100 mfovs">',num2str(max(0,batch_info.jitter_num*100/batch_info.mfov_num),'%.3f'),nb,'</td>',nl];
    td_skewrate = [idt3,'<td title="per 100 mfovs">',num2str(max(0,batch_info.skew_num*100/batch_info.mfov_num),'%.3f'),nb,'</td>',nl];
    td_scanfaultrate = [idt3,'<td title="per 100 mfovs" style="border-right:3px solid silver;">',num2str(max(0,batch_info.scanfault_num*100/batch_info.mfov_num),'%.3f'),nb,'</td>',nl];
    td_addinfo = [idt3,'<td>',batch_info.additional_info,nb,'</td>',nl];
    trstr = [td_batchname,td_runtime,td_downtime,td_ROInum,td_ROIkept,td_ROIkeptime,...
        td_scantime,td_stagetime,td_focustime,td_stigtime,td_b2ftime,...
        td_AFAS,td_badfocus,td_offtarget,td_jitterrate,td_skewrate,td_scanfaultrate,td_addinfo];
    if strcmpi(batch_info.batch_name,'Total')
        trstr = [idt2,'<tr style="font-weight:bold;">',nl,trstr,'</tr>',nl];
    else
        trstr = [idt2,'<tr>',nl,trstr,'</tr>',nl];
    end
end

function trstr = local_tr_batch_thead
    nl = [char(13),newline];
    idt1 = char(9); idt2 = [char(9),char(9)]; idt3 = [char(9),char(9),char(9)];
    th_batchname = [idt3, '<th>batch folder name</th>',nl];
    th_runtime = [idt3,'<th>EM run time</th>',nl];
    th_downtime = [idt3,'<th title="down time after the batch">wait time</th>',nl];
    th_ROInum = [idt3,'<th>total ROIs</th>',nl];
    th_ROIkept = [idt3,'<th>ROIs kept</th>',nl];
    th_ROIkeptime = [idt3,'<th title="time spent on generating the final versions of the data">time on kept ROIs</th>',nl];
    th_scantime = [idt3,'<th>acq time</th>',nl];
    th_stagetime = [idt3,'<th>stage time</th>',nl];
    th_focustime = [idt3,'<th>auto-focus time</th>',nl];
    th_stigtime = [idt3,'<th>auto-stig time</th>',nl];
    th_b2ftime = [idt3,'<th>b2f time</th>',nl];
    th_AFAS = [idt3,'<th title="AFAS failure ratio">AFAS ROIs</th>',nl];
    th_badfocus = [idt3,'<th title="soft focus/bad stig/b2f error">bad focus ROIs</th>',nl];
    th_offtarget = [idt3,'<th>off-target ROIs</th>',nl];
    th_jitterrate = [idt3,'<th title="jitter per 100 mfovs">jitter rate</th>',nl];
    th_skewrate = [idt3,'<th title="skew per 100 mfovs">skew rate</th>',nl];
    th_scanfaultrate = [idt3,'<th title="scanfault per 100 mfovs">scanfault rate</th>',nl];
    th_addinfo = [idt3,'<th>additional info</th>',nl];
    trstr = [idt1,'<thead>',nl,idt2,'<tr>',nl,th_batchname,th_runtime, th_downtime,th_ROInum,th_ROIkept,th_ROIkeptime,...
        th_scantime,th_stagetime,th_focustime,th_stigtime,th_b2ftime,...
        th_AFAS,th_badfocus,th_offtarget,th_jitterrate,th_skewrate,th_scanfaultrate,th_addinfo,...
        idt2,'</tr>',nl,idt1,'</thead>'];
end


% function p_str = local_percent_span_tag(p,fmtstr)
%     if nargin < 2
%         fmtstr = '%.1f';
%     end
%     p_str = ['<span style="color:silver;"> *',...
%         num2str(p*100,fmtstr),'% </span>'];
% end

function p_str = local_percent_span_tag_p(p,fmtstr)
    if nargin < 2
        fmtstr = '%.1f';
    end
    p_str = ['<span style="color:gray;"> (',...
        num2str(max(0,p)*100,fmtstr),'%) </span>'];
end