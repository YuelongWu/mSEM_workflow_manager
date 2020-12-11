function trstr = utils_tr_one_section(sec_info, crnt_batch, crnt_sec, sec_id)
    nl = [char(13),newline];
    idt2 = [char(9),char(9)]; idt3 = [char(9),char(9),char(9)];
    checkmark = '&#10003;';
    returnmark = '&#13;';

    % relative result_dir
    sec_info.folder = strrep(sec_info.folder,'\','/');
    if isempty(sec_info.folder)
        sec_dir = './';
        batch_dir = '../';
        wafer_dir = '../../';
    else
        [bn,~] = fileparts(sec_info.folder);
        if isempty(bn)
            sec_dir = [sec_info.folder,'/'];
            batch_dir = './';
            wafer_dir = '../';
        else
            sec_dir = [sec_info.folder,'/'];
            batch_dir = [bn, '/'];
            wafer_dir = './';
        end
    end
    [~, id_sec] = fileparts(sec_info.section_dir);
    % label to decide the color label on the section name column
    % 0-normal; 1-warning; 2-error
    section_class = 0;
    err_msgs = '';
    wrn_msgs = '';

    % table cell for user decision
    % column name: status
    div_class = 'ud';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    if sec_info.AFAS
        innerHTML = 'AFAS fail';
        section_class = max(section_class, 2);
        err_msgs = strcat(err_msgs,'AFAS Failure,');
        if sec_info.retaken
            td_class = ' class="userNormal"';
            tooltip_str = ' title="AFAS failed and retaken"';
        else
            td_class = ' class="userRetake"';
            tooltip_str = ' title="AFAS failed"';
        end
    elseif sec_info.discarded
        innerHTML = 'discarded';
        td_class = ' class="userDiscard"';
        tooltip_str = ' title="discarded by the user"';
    elseif sec_info.errorRaised
        innerHTML = 'SW error';
        tooltip_str = [' title="Retake Manager Encountered an error',...
            returnmark,'Please contact me (Yuelong)..."'];
        section_class = max(section_class, 2);
        err_msgs = strcat(err_msgs,'RetakeManager error,');
        if sec_info.retaken
            td_class = ' class="userNormal"';
        else
            td_class = ' class="userRetake"';
        end
    elseif sec_info.user_decision == -1
        if sec_info.retaken
            innerHTML = 'retaken';
            td_class = ' class="userNormal"';
            tooltip_str = '';
        else
            innerHTML = 'to retake';
            td_class = ' class="userRetake"';
            tooltip_str = ' title="need retake"';
        end
    elseif sec_info.user_decision == 0
        innerHTML = 'TBD';
        tooltip_str = ' title="the section has NOT been verified by the user"';
        if sec_info.retaken
            innerHTML = 'retaken';
            tooltip_str = ' title="the section has NOT been verified by the user but retaken"';
            td_class = ' class="userNormal"';
        else
            td_class = ' class="userRetake"';
        end
    else
        innerHTML = 'keep';
        td_class = ' class="userNormal"';
        tooltip_str = '';
    end
    td_tag = {['<td',tooltip_str,td_class,'>'],'</td>'};
    td_userDecision = [idt3,local_enclose_innerHTML(innerHTML,div_tag,td_tag),nl];

    % table cell for batch timestamp
    % column name: batch timestamp
    div_class = 'bts';
    a_tag = {['<a href="file:/',strrep(sec_info.section_dir,'\','/'),'">'],'</a>'};
    innerHTML = sec_info.batch_timestamp;
    if crnt_batch
        div_tag = {['<div class="',div_class,'" style="font-weight:bold">'],'</div>'};
        td_tag = {'<td title="timestamp in batch folder name&#13;this is the latest batch">','</td>'};
    else
        div_tag = {['<div class="',div_class,'">'],'</div>'};
        td_tag = {'<td title="timestamp in batch folder name">','</td>'};
    end
    td_batchTimestamp = [idt3,local_enclose_innerHTML(innerHTML,div_tag,a_tag,td_tag),nl];

    % table cell for mFoV number
    % column name: mFoV #
    div_class = 'mnb';
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
    else
        innerHTML = num2str(sec_info.mFoV_num);
    end
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    if sec_info.mFoV_num > 0
        td_tag = {['<td title="', innerHTML ' mFoVs in this section">'],'</td>'};
    elseif sec_info.AFAS
        td_tag = {'<td title="AFAS Failure">','</td>'};
    elseif sec_info.errorRaised
        td_tag = {'<td title="Retake manager error">','</td>'};
    elseif sec_info.mFoV_num == 0
        td_tag = {'<td title="No mFoV acquired in this section" class="errorElem">','</td>'};
        section_class = max(section_class, 2);
        err_msgs = strcat(err_msgs,'No mFoV found,');
    else % shouldn't arrive here
        td_tag = {'<td title="Retake manager could not find mFoV number for this section" class="swbugElem">','</td>'};
    end
    td_mfovNum = [idt3,local_enclose_innerHTML(innerHTML,div_tag,td_tag),nl];

    % table cell for FSP status
    % column name: FSP #
    div_class = 'fsp';
    innerHTML = [num2str(sec_info.FSP_num(1)),'/',num2str(sec_info.FSP_num(2))];
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    if max(sec_info.FSP_num) == 0 || (sec_info.FSP_num(1)==0 && ~sec_info.AFAS)
        innerHTML = 'manual';
        td_tag = {'<td title="FSPs were done manually">','</td>'};
    elseif sec_info.FSP_num(1) == sec_info.FSP_num(2)
        td_tag = {'<td title="All FSPs successful">','</td>'};
    else
        failed_FSP = num2str(sec_info.FSP_num(2) - sec_info.FSP_num(1));
        td_tag = {['<td title="',failed_FSP,' FSPs failed" class="warngElem">'],'</td>'};
    end
    if sec_info.B2F_fail
        td_tag = {'<td title="B2F failure" class="errorElem">','</td>'};
        section_class = max(section_class, 1);
        wrn_msgs = strcat(wrn_msgs,'B2F failure,');
    end
    td_fspNum = [idt3,local_enclose_innerHTML(innerHTML,div_tag,td_tag),nl];

    % table cell for time duration
    % column name: duration
    div_class = 'drt';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    t_tot = max(sec_info.duration);
    if isnan(t_tot)
        innerHTML = 'N/A';
        td_class = ' class="warngElem"';
        tooltip_str = 'Time information not available.';
    else
        innerHTML = [num2str(t_tot/60,'%.1f'), ' min'];
        td_class = '';
        scan_ratio = sec_info.scan_time/t_tot;
        fsp_ratio = (sec_info.focus_time + sec_info.stig_time + sec_info.b2f_time)/t_tot;
        stage_ratio = sec_info.stage_movement_time/t_tot;
        if any(isnan([scan_ratio,fsp_ratio,stage_ratio]))
            tooltip_str = 'protocal.txt file not available';
        else
            tooltip_str = ['scan:', num2str(round(scan_ratio*100)),'%, ',...
                'focus:', num2str(round(fsp_ratio*100)),'%, ',...
                'stage:', num2str(round(stage_ratio*100)),'%'];
        end
    end
    if ~isempty(sec_info.tile_setup)
        tooltip_str = [tooltip_str,returnmark,sec_info.tile_setup];
    end
    td_tag =  {['<td title="',tooltip_str,'"',td_class,'>'],'</td>'};
    td_duration = [idt3,local_enclose_innerHTML(innerHTML,div_tag,td_tag),nl];

    % table cell for missing full resolution imaging
    % column name: full-res imgs
    div_class = 'fri';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    missimgs = sec_info.fullres_image_missing;
    dupimgs = abs(missimgs(missimgs<0));
    missimgs = missimgs(missimgs>0);
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        td_tag = {'<td class="ovflw">','</td>'};
    else
        if isempty(missimgs) && isempty(dupimgs) % no issue
            if ~sec_info.imgNumberCheckFinished
                innerHTML = 'not finished';
                td_tag = {'<td title="Image counting not finished" class="swbugElem">','</td>'};
                section_class = max(section_class, 2);
                err_msgs = strcat(err_msgs,'Image counting not finished,');
            else
                innerHTML = checkmark;
                td_tag = {'<td title="No full-resolution image missing" class="ovflw">','</td>'};
            end
        elseif ~isempty(missimgs) && ~isempty(dupimgs) % both missing images and duplicated images
            missimgstr = utils_convert_id_vector_into_str_report(missimgs);
            dupimgstr = utils_convert_id_vector_into_str_report(dupimgs);
            innerHTML = ['<span class="errorElem">',missimgstr,'</span> $#8286; ',...
                '<span class="warngElem">',dupimgstr,'</span>'];
            td_tag = {['<td title="mFoV with missing full-res images: ', missimgstr,returnmark,...
                'mFoV with duplicated full-res images:',dupimgstr,'" class="ovflw">'],'</td>'};
            section_class = max(section_class, 2);
            err_msgs = strcat(err_msgs,'Missing images,');
        elseif ~isempty(missimgs) % only missing images
            missimgstr = utils_convert_id_vector_into_str_report(missimgs);
            innerHTML = missimgstr;
            td_tag = {['<td title="mFoV with missing full-res images: ', missimgstr,...
                '" class="ovflw errorElem">'],'</td>'};
            section_class = max(section_class, 2);
            err_msgs = strcat(err_msgs,'Missing images,');
        else % only duplicate images
            dupimgstr = utils_convert_id_vector_into_str_report(dupimgs);
            if ~sec_info.imgNumberCheckFinished
                innerHTML = ['<span class="warngElem">',dupimgstr,'</span>'];
                td_tag = {['<td title="Image counting not finished',returnmark,'mFoV with duplicated full-res images: ', dupimgstr,...
                    '" class="ovflw swbugElem">'],'</td>'};
                section_class = max(section_class, 2);
                err_msgs = strcat(err_msgs,'Image counting not finished,');
            else
                innerHTML = dupimgstr;
                td_tag = {['<td title="mFoV with duplicated full-res images: ', dupimgstr,...
                    '" class="ovflw warngElem">'],'</td>'};
            end
        end
    end
    td_fullresImg = [idt3,local_enclose_innerHTML(innerHTML,div_tag,td_tag),nl];

    % table cell for missing thumbnail imaging
    % column name: thumbnail imgs
    div_class = 'tni';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    missimgs = sec_info.thumb_image_missing;
    dupimgs = abs(missimgs(missimgs<0));
    missimgs = missimgs(missimgs>0);
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        td_tag = {'<td class="ovflw">','</td>'};
    else
        if isempty(missimgs) && isempty(dupimgs) % no issue
            innerHTML = checkmark;
            td_tag = {'<td title="No thumbnails image missing" class="ovflw">','</td>'};
        elseif ~isempty(missimgs) && ~isempty(dupimgs) % both missing images and duplicated images
            missimgstr = utils_convert_id_vector_into_str_report(missimgs);
            dupimgstr = utils_convert_id_vector_into_str_report(dupimgs);
            innerHTML = ['<span class="errorElem">',missimgstr,'</span> $#8286; ',...
                '<span class="warngElem">',dupimgstr,'</span>'];
            td_tag = {['<td title="mFoV with missing thumbnails: ',missimgstr,returnmark,...
                'mFoV with duplicated thumbnails:',dupimgstr,'" class="ovflw">'],'</td>'};
            section_class = max(section_class, 1);
            wrn_msgs = strcat(wrn_msgs,'Missing thumbnails,');
        elseif ~isempty(missimgs) % only missing images
            missimgstr = utils_convert_id_vector_into_str_report(missimgs);
            innerHTML = missimgstr;
            td_tag = {['<td title="mFoV with missing thumbnails: ',missimgstr,...
                '" class="ovflw errorElem">'],'</td>'};
            section_class = max(section_class, 1);
            wrn_msgs = strcat(wrn_msgs,'Missing thumbnails,');
        else % only duplicate images
            dupimgstr = utils_convert_id_vector_into_str_report(dupimgs);
            innerHTML = dupimgstr;
            td_tag = {['<td title="mFoV with duplicated thumbnails: ', dupimgstr,...
                '" class="ovflw warngElem">'],'</td>'};
        end
    end
    td_thumbImg = [idt3,local_enclose_innerHTML(innerHTML,div_tag,td_tag),nl];

    % table cell for missing full resolution coordinates
    % column name: full-res coord
    div_class = 'frc';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    miss_img_coord = sec_info.fullres_coord_missing;
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        td_tag = {'<td class="ovflw">','</td>'};
    else
        if isempty(miss_img_coord) % no issue
            innerHTML = checkmark;
            td_tag = {'<td title="No full-resolution coordinates missing" class="ovflw">','</td>'};
        else  % missing full-res coord
            misscoordstr = utils_convert_id_vector_into_str_report(miss_img_coord);
            innerHTML = misscoordstr;
            td_tag = {['<td title="mFoV with missing full-res coordinates: ', misscoordstr,...
                '" class="ovflw errorElem">'],'</td>'};
        end
    end
    td_fullresCoord = [idt3,local_enclose_innerHTML(innerHTML,div_tag,td_tag),nl];
    % table cell for missing thumbnail coordinates
    % column name: thumbnail coord
    div_class = 'tnc';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    miss_thumb_coord = sec_info.thumb_coord_missing;
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        td_tag = {'<td class="ovflw">','</td>'};
    else
        if isempty(miss_thumb_coord) % no issue
            innerHTML = checkmark;
            td_tag = {'<td title="No thumbnail coordinates missing" class="ovflw">','</td>'};
        else  % missing thumbnail coord
            misscoordstr = utils_convert_id_vector_into_str_report(miss_thumb_coord);
            innerHTML = misscoordstr;
            td_tag = {['<td title="mFoV with missing thumbnail coordinates: ', misscoordstr,...
                '" class="ovflw errorElem">'],'</td>'};
        end
    end
    td_thumbCoord = [idt3,local_enclose_innerHTML(innerHTML,div_tag,td_tag),nl];
    % if both coords missing, raise error flag; if only one missing, raise warning
    if (~isempty(miss_thumb_coord) || ~isempty(miss_img_coord)) && (~sec_info.AFAS) && (~sec_info.errorRaised)
        if any(ismember(miss_thumb_coord,miss_img_coord))
            section_class = max(section_class, 2);
            err_msgs = strcat(err_msgs,'Missing coordinates,');
        else
            section_class = max(section_class, 1);
            wrn_msgs = strcat(wrn_msgs,'Missing coordinates,');
        end
    end

    % table cell for region_metadata
    % column name: metadata
    div_class = 'rmd';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        td_tag = {'<td>','</td>'};
    elseif sec_info.regionmetadata_status == 0
        innerHTML = checkmark;
        td_tag = {'<td title="region_metadata.csv is complete">','</td>'};
    elseif sec_info.regionmetadata_status == 1
        innerHTML = 'corrupted';
        if sec_info.IMQA_status
            td_tag = {'<td title="region_metadata.csv is corrupted" class="warngElem">','</td>'};
            section_class = max(section_class, 1);
            wrn_msgs = strcat(wrn_msgs,'Corrupted region_metadata.csv,');
        else
            td_tag = {'<td title="region_metadata.csv is corrupted" class="errorElem">','</td>'};
            section_class = max(section_class, 2);
            err_msgs = strcat(err_msgs,'Corrupted region_metadata.csv,');
        end
    else
        innerHTML = 'missing';
        td_tag = {'<td title="region_metadata.csv is missing" class="errorElem">','</td>'};
        section_class = max(section_class, 2);
        err_msgs = strcat(err_msgs,'Missing region_metadata.csv,');
    end
    td_regionmetadata =  [idt3,local_enclose_innerHTML(innerHTML,div_tag,td_tag),nl];

    % table cell for FocusMap.txt
    % column name: focus map
    div_class = 'fm';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        td_tag = {'<td>','</td>'};
    elseif sec_info.focusmap_status == 0
        innerHTML = checkmark;
        td_tag = {'<td title="FocusMap.txt is complete">','</td>'};
    elseif sec_info.focusmap_status == 1
        innerHTML = 'corrupted';
        td_tag = {'<td title="FocusMap.txt is corrupted" class="warngElem">','</td>'};
        section_class = max(section_class, 1);
        wrn_msgs = strcat(wrn_msgs,'Corrupted FocusMap.txt,');
    else
        innerHTML = 'missing';
        td_tag = {'<td title="FocusMap.txt is missing" class="warngElem">','</td>'};
        section_class = max(section_class, 1);
        wrn_msgs = strcat(wrn_msgs,'Missing FocusMap.txt,');
    end
    td_focusmap =  [idt3,local_enclose_innerHTML(innerHTML,div_tag,td_tag),nl];

    % table cell for protocol.txt
    % column name: protocol
    div_class = 'prt';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        td_tag = {'<td>','</td>'};
    elseif sec_info.protocol_status == 0
        innerHTML = checkmark;
        td_tag = {'<td title="protocol.txt is complete">','</td>'};
    elseif sec_info.protocol_status == 1
        innerHTML = 'corrupted';
        td_tag = {'<td title="protocol.txt is corrupted" class="warngElem">','</td>'};
    else
        innerHTML = 'missing';
        td_tag = {'<td title="protocol.txt is missing" class="warngElem">','</td>'};
        section_class = max(section_class, 1);
        wrn_msgs = strcat(wrn_msgs,'Missing protocol.txt,');
    end
    td_protocol =  [idt3,local_enclose_innerHTML(innerHTML,div_tag,td_tag),nl];

    % table cell for workflow.xaml
    % column name: workflow
    div_class = 'wf';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        td_tag = {'<td>','</td>'};
    elseif sec_info.workflow_status == 0
        innerHTML = checkmark;
        td_tag = {'<td title="workflow.xaml exists">','</td>'};
    else
        innerHTML = 'missing';
        td_tag = {'<td title="workflow.xaml is missing" class="warngElem">','</td>'};
    end
    td_workflow = [idt3,local_enclose_innerHTML(innerHTML,div_tag,td_tag),nl];

    % table cell for alignment status
    % column name: ROI align
    div_class = 'roi';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        td_tag = {'<td>','</td>'};
    else
        switch abs(sec_info.align_status)
        case 0
            innerHTML = 'TBD';
            td_title = 'The user has NOT aligned this section yet';
            td_class = ' class="warngElem"';
        case 1
            innerHTML = [num2str(sec_info.align_rotation,'%.1f'),'&#176;'];
            td_title = ['ROI rotation: ', num2str(sec_info.align_rotation,'%.2f'),'&#176;',returnmark,...
                'ROI shift: x ', num2str(sec_info.align_displacement(1),'%.0f'),'um, y ',...
                num2str(sec_info.align_displacement(2),'%.0f'),'um'];
            if sec_info.align_missingarea > 0.0005
                if sec_info.align_missingarea > 0.05
                    td_class = ' class="errorElem"';
                else
                    td_class = ' class="warngElem"';
                end
                section_class = max(section_class, 1);
                wrn_msgs = strcat(wrn_msgs,'ROI shift,');
                if sec_info.align_missingarea > 0.001
                    miss_area_str = [num2str(sec_info.align_missingarea*100,'%.1f'),'%'];
                elseif sec_info.align_missingarea > 0.0001
                    miss_area_str = [num2str(sec_info.align_missingarea*1000,'%.1f'),'&#8240;'];
                else
                    miss_area_str = [num2str(sec_info.align_missingarea*10000,'%.1f'),'&#8241;'];
                end
                innerHTML = [innerHTML,' (',miss_area_str,')'];
                td_title = [td_title,returnmark,'Missing area: ', miss_area_str];
            else
                td_class = '';
            end
        case 2
            innerHTML = 'reference';
            td_class = '';
            td_title = 'Reference image';
        case 3
            innerHTML = 'Failed';
            td_title = 'Aligment failed';
            td_class  = ' class="errorElem"';
            section_class = max(section_class, 1);
            wrn_msgs = strcat(wrn_msgs,'ROI alignment failed,');
        end
        % if the current section is rendered, link to the redered image and bold the text
        if sec_info.align_status > 0
            a_tag = {['<a href="',[wafer_dir,'aligned_overviews/',sec_info.section_name,'.png'],'">'],'</a>'};
            innerHTML = local_enclose_innerHTML(innerHTML,{'<b>','</b>'},a_tag);
            td_title = ['Rendered', returnmark, td_title];
        end
        td_tag = {['<td title="',td_title,'"', td_class,'>'],'</td>'};
    end
    td_roi = [idt3,local_enclose_innerHTML(innerHTML,div_tag,td_tag),nl];

    % table cell for sFoV stitching
    % column name: sFoV stitch
    div_class = 'sfvst';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    a_tag = {['<a href="',sec_dir,'sFoV_overlap.png">'],'</a>'};
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        td_tag = {'<td>','</td>'};
        a_tag = {'',''};
    elseif isnan(sec_info.sfov_rotation) || (sec_info.sfov_stitch_status == 3)
        innerHTML = 'failed';
        td_tag = {'<td title="Failed to stitch sFoVs" class="errorElem">','</td>'};
        a_tag = {'',''};
        section_class = max(section_class, 2);
        err_msgs = strcat(err_msgs,'sFoV stitch failed,');
    else
        innerHTML = [num2str(sec_info.sfov_rotation,'%.2f'),'&#176;'];
        if sec_info.sfov_stitch_status == 2
            if sec_info.override.sfov_overlap
                td_tag = {'<td title="User overrode sFoV gaps" class="errorElemOverriden">','</td>'};
            else
                td_tag = {'<td title="Overlap gaps detected between sFoVs" class="errorElem">','</td>'};
                section_class = max(section_class, 2);
                err_msgs = strcat(err_msgs,'sFoV overlap gaps,');
            end
        elseif abs(sec_info.sfov_rotation) > 1
            if sec_info.override.sfov_overlap
                td_tag = {'<td title="User overrode mFoV rotation" class="warngElemOverriden">','</td>'};
            else
                td_tag = {'<td title="mFoV rotation detected" class="warngElem">','</td>'};
                section_class = max(section_class, 1);
                wrn_msgs = strcat(wrn_msgs,'mFoV rotation,');
            end
        elseif sec_info.sfov_stitch_status == 1
            if sec_info.override.sfov_overlap
                td_tag = {'<td title="User overrode thin sFoV overlap" class="warngElemOverriden">','</td>'};
            else
                td_tag = {'<td title="Thin sFoV overlap detected" class="warngElem">','</td>'};
                section_class = max(section_class, 1);
                wrn_msgs = strcat(wrn_msgs,'Thin sFoV overlap,');
            end
        else
            td_tag = {'<td>','</td>'};
        end
    end
    td_sfovStitch = [idt3,local_enclose_innerHTML(innerHTML,div_tag,a_tag,td_tag),nl];

    % table cell for mFoV stitching
    % column name: mFoV stitch
    div_class = 'mfvst';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    a_tag = {['<a href="',batch_dir,'maps/mfov_overlap/',id_sec,'.pdf">'],'</a>'};
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        td_tag = {'<td>','</td>'};
        a_tag = {'',''};
    elseif ~sec_info.mfovOverlapCheckFinished && ~(sec_info.mFoV_gaps_num > 0)
        innerHTML = 'not finished';
        td_tag = {'<td title="The mFoV stitching did NOT finish" class="swbugElem">','</td>'};
        a_tag = {'',''};
        section_class = max(section_class, 2);
        err_msgs = strcat(err_msgs,'mFoV stitch not finished,');
    elseif sec_info.mFoV_gaps_num == 0 && sec_info.mFoV_lowconf_num == 0
        innerHTML = '0 (0)';
        td_tag = {'<td title="No mFoV overlap issue detected">','</td>'};
        a_tag = {'',''};
    else
        if sec_info.mFoV_gaps_num > 0
            if sec_info.override.mfov_overlap
                str1 = ['<span class="errorElemOverriden">',num2str(sec_info.mFoV_gaps_num),' </span>'];
                td_title = [num2str(sec_info.mFoV_gaps_num),' gaps (user overriden)'];
                td_class = '';
            else
                str1 = ['<span class="errorElem">',num2str(sec_info.mFoV_gaps_num),' </span>'];
                td_title = [num2str(sec_info.mFoV_gaps_num),' gaps'];
                section_class = max(section_class, 2);
                err_msgs = strcat(err_msgs,'mFoV overlap gaps,');
                td_class = ' class="errorElem"';
            end
        else  % no mFoV overlap gaps
            str1 = '0 ';
            td_title = '';
            td_class = '';
        end
        if sec_info.mFoV_lowconf_num > 0
            str2 = ['(<span class="warngElem">',num2str(sec_info.mFoV_lowconf_num),'</span>)'];
            if isempty(td_title)
                td_title = [num2str(sec_info.mFoV_lowconf_num),' low-confidence overlap'];
            else
                td_title = [td_title,returnmark,num2str(sec_info.mFoV_lowconf_num),' low-confidence overlap'];
            end
            if isempty(td_class)
                td_class = ' class="warngElem"';
            end
%             if sec_info.mFoV_lowconf_num > sec_info.mFoV_num*3*0.01
%                 section_class = max(section_class, 1);
%             end
            wrn_msgs = strcat(wrn_msgs,'mFoV overlap low-conf,');
        else
            str2 = '(0)';
        end
        innerHTML = [str1, str2];
        td_tag = {['<td title="',td_title,'"',td_class,'>'],'</td>'};
    end
    td_mfovStitch = [idt3,local_enclose_innerHTML(innerHTML,div_tag,a_tag,td_tag),nl];

    % table cell for jitter
    % column name: jitter
    div_class = 'jt';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        a_tag = {'',''};
        td_tag = {'<td>','</td>'};
    elseif sec_info.jitter_num > 0
        innerHTML = num2str(sec_info.jitter_num);
        a_tag = {['<a href="',batch_dir,'maps/jitter/',id_sec,'.pdf">'],'</a>'};
        if sec_info.override.jitter
            td_tag = {['<td title="',num2str(sec_info.jitter_num),' mFoVs with jitter at the top (user overriden)" class="errorElemOverriden">'],'</td>'};
        else
            td_tag = {['<td title="',num2str(sec_info.jitter_num),' mFoVs with jitter at the top" class="errorElem">'],'</td>'};
            section_class = max(section_class, 1);
            wrn_msgs = strcat(wrn_msgs,'mFoV jitter,');
        end
    elseif ~sec_info.stageJitteringCheckFinished
        innerHTML = 'not finished';
        a_tag = {'',''};
        td_tag = {'<td title="Jitter check did NOT finish" class="swbugElem">','</td>'};
        section_class = max(section_class, 1);
        wrn_msgs = strcat(wrn_msgs,'Jitter check not finished,');
    else
        innerHTML = checkmark;
        a_tag = {'',''};
        td_tag = {'<td title="No jitter detected">','</td>'};
    end
    td_jitter = [idt3,local_enclose_innerHTML(innerHTML,div_tag,a_tag,td_tag),nl];

    % table cell for skew
    % column name: skew
    div_class = 'skw';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        a_tag = {'',''};
        td_tag = {'<td>','</td>'};
    elseif sec_info.distort_num > 0
        innerHTML = num2str(sec_info.distort_num);
        a_tag =  {['<a href="',batch_dir,'maps/charging_scanfault/',id_sec,'.pdf">'],'</a>'};
        if sec_info.override.skew
            td_tag = {['<td title="',num2str(sec_info.distort_num),' mFoVs with skew at the top (user overriden)" class="errorElemOverriden">'],'</td>'};
        else
            td_tag = {['<td title="',num2str(sec_info.distort_num),' mFoVs with skew at the top" class="errorElem">'],'</td>'};
            section_class = max(section_class, 1);
            wrn_msgs = strcat(wrn_msgs,'Top skew,');
        end
    else
        a_tag = {'',''};
        if ~sec_info.imageChargingCheckFinished
            innerHTML = 'not finished';
            td_tag = {'<td title="Skew check did NOT finish" class="swbugElem">','</td>'};
            section_class = max(section_class, 1);
            wrn_msgs = strcat(wrn_msgs,'Skew check not finished,');
        else
            innerHTML = checkmark;
            td_tag = {'<td title="No skew detected">','</td>'};
        end
    end
    td_skew =  [idt3,local_enclose_innerHTML(innerHTML,div_tag,a_tag,td_tag),nl];

    % table cell for scanfault
    % column name: scanfault
    div_class = 'scf';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        a_tag = {'',''};
        td_tag = {'<td>','</td>'};
    elseif sec_info.scanfault_num > 0
        innerHTML = num2str(sec_info.scanfault_num);
        a_tag =  {['<a href="',batch_dir,'maps/charging_scanfault/',id_sec,'.pdf">'],'</a>'};
        if sec_info.override.scanfault
            td_tag = {['<td title="',num2str(sec_info.scanfault_num),' mFoVs with scanfault (user overriden)" class="errorElemOverriden">'],'</td>'};
        else
            td_tag = {['<td title="',num2str(sec_info.scanfault_num),' mFoVs with scanfault" class="errorElem">'],'</td>'};
            section_class = max(section_class, 1);
            wrn_msgs = strcat(wrn_msgs,'Scanfault,');
        end
    else
        a_tag = {'',''};
        if ~sec_info.scanfaultCheckFinished
            innerHTML = 'not finished';
            td_tag = {'<td title="Scanfault check did NOT finish" class="swbugElem">','</td>'};
            section_class = max(section_class, 1);
            wrn_msgs = strcat(wrn_msgs,'Scanfault check not finished,');
        else
            innerHTML = checkmark;
            td_tag = {'<td title="No scanfault detected">','</td>'};
        end
    end
    td_scanfault =  [idt3,local_enclose_innerHTML(innerHTML,div_tag,a_tag,td_tag),nl];

    % table cell for IMQA value
    % column name: IMQA
    div_class = 'imqa';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        a_tag = {'',''};
        td_tag = {'<td>','</td>'};
    elseif sec_info.IMQA_status
        innerHTML = [num2str(sec_info.IMQA(1),'%.1f'),' &#177; ',num2str(sec_info.IMQA(2),'%.1f')];
        a_tag = {['<a href="',batch_dir,'image_qualities/',sec_info.section_name,'_imageQuality.jpg">'],'</a>'};
        softfocus = contains(sec_info.user_comment,'[SOFT-FOCUS]');
        badstig = contains(sec_info.user_comment,'[BAD-STIG]');
        b2ferr = contains(sec_info.user_comment,'[BEAM-TO-FIBER-ERROR]');
        if any([softfocus, badstig, b2ferr])
            tmpstr = {'soft focus','bad stig','b2f error'};
            tmpstr = tmpstr([softfocus, badstig, b2ferr]);
            td_tag = {['<td title="',strjoin(tmpstr,returnmark),'" class="errorElem">'],'</td>'};
            if sec_info.user_decision == -1
                section_class = max(section_class, 2);
                err_msgs = strcat(err_msgs,'User flagged focus issue,');
            end
        elseif sec_info.user_decision == 0
            td_tag = {'<td title="Image quality has NOT been verified by the user" class="warngElem">','</td>'};
        else
            td_tag = {'<td title="Image quality is good">','</td>'};
        end
    else
        innerHTML = 'N/A';
        a_tag = {'',''};
        td_tag = {'<td title="region_metadata.csv is NOT available" class="errorElem">','</td>'};
    end
    td_IMQA =  [idt3,local_enclose_innerHTML(innerHTML,div_tag,a_tag,td_tag),nl];

    % table cell for worst beams
    % column name: worst beams
    div_class = 'wstb';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    if sec_info.AFAS || sec_info.errorRaised
        innerHTML = '';
        a_tag = {'',''};
        td_tag = {'<td>','</td>'};
    elseif sec_info.IMQA_status
        innerHTML = strjoin(cellstr(num2str(sec_info.worst_beams(:))),',');
        a_tag = {['<a href="',batch_dir,'beam_qualities/',sec_info.section_name,'_beamQuality.pdf">'],'</a>'};
        td_tag = {'<td title="beam numbers with worst image quality scores">','</td>'};
    else
        innerHTML = 'N/A';
        a_tag = {'',''};
        td_tag = {'<td title="region_metadata.csv is NOT available" class="errorElem">','</td>'};
    end
    td_worstBeams =  [idt3,local_enclose_innerHTML(innerHTML,div_tag,a_tag,td_tag),nl];

    % table cell for user comment
    % column name: user comments
    div_class = 'uc';
    div_tag = {['<div class="',div_class,'">'],'</div>'};
    innerHTML = sec_info.user_comment;
    td_tag = {'<td title="user comments">','</td>'};
    td_userComments =  [idt3,local_enclose_innerHTML(innerHTML,div_tag,td_tag),nl];

    % hidden table cell for section id used for JS sorting
    div_class = 'secid';
    td_sectionID = [idt3,'<td class="',div_class,'">',sec_id,'</td>',nl];

    % decide the tr label
    innerHTML = sec_info.section_name;
    if section_class == 2
        tr_class = 'errorSection';
        if ~isempty(err_msgs)
            err_msgs = err_msgs(1:end-1);
            sec_msgs = strrep(err_msgs,',',returnmark);
        else
            sec_msgs = '&bull; Section with errors &bull;';
        end
    elseif section_class == 1
        tr_class = 'warngSection';
        if ~isempty(wrn_msgs)
            wrn_msgs = wrn_msgs(1:end-1);
            sec_msgs = strrep(wrn_msgs,',',returnmark);
        else
            sec_msgs = '&bull; Section with warnings &bull;';
        end
    else
        tr_class = 'normlSection';
        sec_msgs = '&bull; Good section &bull;';
    end
    if sec_info.AFAS || sec_info.errorRaised
        a_tag = {'',''};
    else
        a_tag = {['<a href="',batch_dir,'overview_imgs/',id_sec,'.png">'],'</a>'};
    end
    if sec_info.discarded && sec_info.retaken
        tr_class = 'retakSection discdSection';
        sec_msgs = ['&bull; Discarded and Retaken &bull;', returnmark, sec_msgs];
    elseif sec_info.discarded
        tr_class = 'discdSection';
        sec_msgs = ['&bull; Discarded &bull;', returnmark, sec_msgs];
    elseif sec_info.retaken
        tr_class = 'retakSection';
        sec_msgs = ['&bull; Retaken &bull;', returnmark, sec_msgs];
    else
        % I'm tired and bored...
    end
    if crnt_sec
        th_tag = {['<th title="',sec_msgs,'" id="latestSection">'],'</th>'};
    else
        th_tag = {['<th title="',sec_msgs,'">'],'</th>'};
    end
    th_secname = [idt3,local_enclose_innerHTML(innerHTML,a_tag,th_tag),nl];

    % table row header and tail tags
    tr_head = [idt2, '<tr class="',tr_class,'">',nl];
    tr_tail = [idt2,'</tr>',nl];

    trstr = [tr_head,...
        th_secname,...
        td_userDecision,...
        td_batchTimestamp,...
        td_mfovNum,...
        td_fspNum,...
        td_duration,...
        td_fullresImg,...
        td_thumbImg,...
        td_fullresCoord,...
        td_thumbCoord,...
        td_regionmetadata,...
        td_focusmap,...
        td_protocol,...
        td_workflow,...
        td_sfovStitch,...
        td_mfovStitch,...
        td_jitter,...
        td_skew,...
        td_scanfault,...
        td_roi,...
        td_IMQA,...
        td_worstBeams,...
        td_userComments,...
        td_sectionID,...
        tr_tail];
end

function elem = local_enclose_innerHTML(innerHTML, varargin)
    tags = vertcat(varargin{:});
    tag_heads = tags(end:-1:1,1);
    tag_tails = tags(:,2);
    elem = strjoin([tag_heads;{innerHTML};tag_tails],'');
end
