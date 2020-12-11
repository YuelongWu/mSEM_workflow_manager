function process_one_batch_timer_callback(vTimer, ~, batch_dir, sys_result_dir, result_dir, user_options)

TimeoutThreshold = 1; % 1 hr time out
try
    [job_queue, status] = update_job_queue(batch_dir, sys_result_dir, getfield(vTimer.UserData,'processed_queue'), 0);
    if status.errRaised
        stop(vTimer);
        read_recipients_and_send_emails('[mSEM Notification] RetakeManager Error', 'The RetakeManager encountered an error and stopped working.',[1,3])
        return;
    end
    
    Nj = length(job_queue);
    if Nj == 0
        tUserData = vTimer.UserData;
        if tUserData.waitflag
            disp('Waiting for acquisition...')
            tUserData.waitflag = false; 
            tUserData.idleTime =  1;
        else
            tUserData.idleTime =  tUserData.idleTime + 1;
        end

        vTimer.UserData = tUserData;
        if (tUserData.idleTime>0) && (mod(tUserData.idleTime,round((TimeoutThreshold *3600/vTimer.Period)))==0)
            try
                current_section_dir = tUserData.processed_queue{end};
                if ~isempty(current_section_dir)
                    [~, current_section_name] = fileparts(current_section_dir);
                    crt_sec_str = [' Latest section: ', current_section_name];
                else
                    crt_sec_str = '';
                end
             catch
                crt_sec_str = '';
            end
            try
                tUserData = vTimer.UserData;
                tgeneral_info = tUserData.general_info;
                if tgeneral_info.doIMQAPlot || tgeneral_info.AFAS
                    beam_arc_str = '';
                    crt_mfov_str = '';
                else
                    beam_arc_str = '(Abnormal)';
                    crt_mfov_str = [' (mFoV#:',num2str(tgeneral_info.mfov_num),')'];
                end
            catch
                beam_arc_str = '';
                crt_mfov_str = '';
            end
            if tUserData.idleTime >= round((2*3600/vTimer.Period))
                alert_group = [1,2,3];
            else
                alert_group = 1;
            end
            if user_options.use_email_alert
                read_recipients_and_send_emails(['[mSEM Notification] Acquisition timed out', beam_arc_str], [num2str(tUserData.idleTime*vTimer.Period/60,'%.0f'),'min timed out without new ROIs acquired.', crt_sec_str, crt_mfov_str],alert_group);
            end
        end
        if  tUserData.idleTime > (4*3600/vTimer.Period)
             fprintf('\n4hr timeout reached.\n')
             stop(vTimer);  
        end
    else
         tUserData = vTimer.UserData;
         tUserData.waitflag = true;
         tUserData.idleTime =  0;
         vTimer.UserData = tUserData;
        for k = 1:1:Nj     
            section_dir = job_queue{k}.SectionName;
            fprintf('\n')
            disp(['Start to processing: ', section_dir]);
            disp(datestr(now,'yyyy-mm-dd HH:MM:SS'));
            [~,sectionName] = fileparts(section_dir);
            sys_sec_dir = [sys_result_dir,filesep,sectionName];
            res_sec_dir = [result_dir,filesep,sectionName];
            if ~exist(sys_sec_dir,'dir')
                mkdir(sys_sec_dir);
            end
            if ~exist(res_sec_dir,'dir')
                mkdir(res_sec_dir);
            end

            [general_info, IMQA_info, coord_info, prot_info] = Check_All_Metadata_Files(section_dir, sys_sec_dir, job_queue{k}, 1);
            
           
            
            general_info.doImgCheck = general_info.doImgCheck && user_options.doImgCheck;
            general_info.doMfovOverlapCheck = general_info.doMfovOverlapCheck && user_options.doMfovOverlapCheck;
            general_info.doSfovOverlapCheck = general_info.doSfovOverlapCheck && user_options.doSfovOverlapCheck;
            general_info.doIMQAPlot = general_info.doIMQAPlot && user_options.doIMQAPlot;
            general_info.doJittering = general_info.doJittering && user_options.doJittering;
            general_info.doROITracking = general_info.doJittering && user_options.doJittering;
            [overlap_status, add_info] = Check_Overlap_For_One_Section(section_dir, coord_info, general_info, sys_sec_dir, res_sec_dir, 1);
            
            tUserData = vTimer.UserData;
            tUserData.processed_queue = [tUserData.processed_queue;{section_dir}];
            vTimer.UserData = tUserData;
            % prepare user mat file
            report_info = prepare_user_mat_data(general_info, IMQA_info, coord_info, overlap_status, add_info, prot_info);
            ovv_info = prepare_ovv_mat_data(general_info, IMQA_info, coord_info, add_info, report_info);
            if report_info.doIMQAPlot
                fidflag = fopen([res_sec_dir,filesep,'IMQA_ready'],'w');
                fclose(fidflag);
            end
            save([res_sec_dir,filesep,'summary.mat'],'report_info');
            save([res_sec_dir,filesep,'ovv_info.mat'],'ovv_info');
            tUserData = vTimer.UserData;
            general_info.scanfault_status = ovv_info.scanfault_status;
            tUserData.general_info = general_info;
            vTimer.UserData = tUserData;
            % write flag file
            if (~general_info.metaErrRaised) && (~overlap_status.errRaised)
                fidflag = fopen([sys_sec_dir, filesep,'processed'],'w');
                fclose(fidflag);
            end
            
            %%%%%%%
            try
            tUserData = vTimer.UserData;
            if general_info.AFAS
                tUserData.AFASCount =  tUserData.AFASCount + 1;
            else
                if tUserData.AFASCount >= 4
                    try
                        current_section_dir = tUserData.processed_queue{end};
                        if ~isempty(current_section_dir)
                            [~, current_section_name] = fileparts(current_section_dir);
                            crt_sec_str = [' Latest section: ', current_section_name];
                        else
                            crt_sec_str = '';
                        end
                     catch
                        crt_sec_str = '';
                     end
                    read_recipients_and_send_emails('[mSEM Notification] AFAS Recovered', ['Successfully acquired a new ROI.', crt_sec_str, 1])
                end
                tUserData.AFASCount =  0;
            end
            vTimer.UserData = tUserData;
            if  tUserData.AFASCount == 4
                 try
                    current_section_dir = tUserData.processed_queue{end};
                    if ~isempty(current_section_dir)
                        [~, current_section_name] = fileparts(current_section_dir);
                        crt_sec_str = [' Latest section: ', current_section_name];
                    else
                        crt_sec_str = '';
                    end
                 catch
                    crt_sec_str = '';
                 end
                 if user_options.use_email_alert
                    read_recipients_and_send_emails('[mSEM Notification] AFAS Failure', ['AFAS failure occurred in 4 consecutive ROI.', crt_sec_str],[1,2,3])
                 end
            end
            catch
            end
            %%%%%%%
            
            % save coordinates files
            if overlap_status.sfovOverlapCheckFinished || overlap_status.mfovOverlapCheckFinished
                coord_saved = save_stitched_image_coordinates(section_dir,coord_info, add_info);
                if ~coord_saved
                    fprintf(2,'\t\tFail to save the stitched coordinates files to the server.\n')
                    fprintf(1,'\t\tSave to the result folder instead.\n')
                    save_stitched_image_coordinates(res_sec_dir,coord_info, add_info);
                end
            end
        end
    end
    
    if status.AcqusitionFinished
        try
            tUserData = vTimer.UserData;
            current_section_dir = tUserData.processed_queue{end};
            if ~isempty(current_section_dir)
                [~, current_section_name] = fileparts(current_section_dir);
                crt_sec_str = [' Latest section: ', current_section_name];
            else
                crt_sec_str = '';
            end
        catch
            crt_sec_str = '';
        end
        
        try
            tUserData = vTimer.UserData;
            tgeneral_info = tUserData.general_info;
            if tgeneral_info.doIMQAPlot || tgeneral_info.AFAS
                beam_arc_str = '';
                crt_mfov_str = '';
            else
                beam_arc_str = '(Abnormal)';
                if tgeneral_info.scanfault_status > 0
                    beam_arc_str = '(Beam arc)';
                end
                crt_mfov_str = [' (mFoV#:',num2str(tgeneral_info.mfov_num),')'];
            end
        catch
            beam_arc_str = '';
            crt_mfov_str = '';
        end
        if isempty(beam_arc_str)
            alert_group = 1;
        else
            alert_group = [1,2,3];
        end
        if user_options.use_email_alert
            read_recipients_and_send_emails(['[mSEM Notification] Workflow stopped',beam_arc_str], ['The current workflow has stopped.', crt_sec_str, crt_mfov_str],alert_group)
        end
        fprintf('\nNo more sections to process.\n')
        stop(vTimer);
    end
catch timerME
    try
       stop(vTimer);
       delete(vTimer);
    catch
    end
    if user_options.use_email_alert
        read_recipients_and_send_emails('[mSEM Notification] RetakeManager Error', 'The RetakeManager encountered an error and stopped working.',[1,3])
    end
    fprintf(2,'Unexpected error happened when executing process_one_batch_timer_callback.\n');
    fprintf(2,['\tMATLAB error message: ', strrep(timerME.message,'\','\\'),'\n']);
    fprintf(2,'\tAbort.\n');
end
end
