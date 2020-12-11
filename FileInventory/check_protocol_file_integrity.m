function [status,prot_info] = check_protocol_file_integrity(prot_dir, mfov_num, verbose)
    % check the integrity of the protocol file by looking if the operation
    % sequencial number is continuous. If mfov number is provided, see if
    % the stage settle is operated the same times as mfov number
    % status = 0: file intact; status = 1: file corrupted; 
    % status = 2: file missing; status = 99: unknown reason
    
    % Yuelong Wu, April 2018
    
    stage_delay_str = 'StageMovementDelay';
    status = 0;
    prot_info = struct;
    prot_info.startTime = NaT;
    prot_info.endTime = NaT;
    prot_info.duration = nan;
    prot_info.coord = [nan, nan];
    prot_info.stgmv_time = nan;
    prot_info.acq_time = nan;
    prot_info.focus_time = nan;
    prot_info.stig_time = nan;
    prot_info.b2f_time = nan;
    prot_info.b2f_num = [nan,nan];
    prot_info.scanspeed = nan;
    prot_info.tile_setup = '';

    if nargin < 3
        verbose = true;
    end
    if verbose
        fprintf('\tChecking the integrity of protocol.txt...\n')
    end
    try
        fid = fopen(prot_dir, 'r');
        if fid == -1
            status = 2; % file missing
            if verbose
                fprintf(2,'\t\tNo protocol.txt found!\n') 
            end
            return;
        else
            prot_data = fread(fid, '*char');
            fclose(fid);
        end
        
        if nargin < 2 % no mfov number provided, only check operation number
            txtscout = utils_textscan(prot_data,'%d%*s%*d%s%s%s%s%f',';');
            op_ids = txtscout{1};
            if nargout>1
                op_names = txtscout{3};
                input_val = txtscout{4};          
                date_num = datetime(txtscout{2},'InputFormat','MM/dd/yyyy HH:mm:ss.SSS');
                prot_info.startTime = min(date_num);
                prot_info.endTime = max(date_num);
                prot_info.duration = seconds(range(date_num));
                stg_x_idx = strcmp(op_names,'SetVariable(Stage_XPosition)');
                stg_y_idx = strcmp(op_names,'SetVariable(Stage_YPosition)');
                xx = str2double(input_val(stg_x_idx));
                yy = str2double(input_val(stg_y_idx));
                prot_info.coord = [median(xx,'omitnan'),median(yy,'omitnan')];
                
                outputval = txtscout{5};
                scanspeed_idx = find(strcmp(op_names,'SetScanspeed'),1,'last');
                if isempty(scanspeed_idx)
                    prot_info.scanspeed = nan;
                else
                    prot_info.scanspeed = str2double(input_val(scanspeed_idx));
                end
                gettiles_idx = find(strcmp(op_names,'GetTiles'),1);
                if isempty(gettiles_idx)
                    prot_info.tile_setup = '';
                else
                    prot_info.tile_setup = outputval{gettiles_idx};
                end
                
                time_cost = txtscout{6};
                stg_mv_idx = strcmp(op_names,'StageMovement');
                prot_info.stgmv_time = nansum(time_cost(stg_mv_idx));
                acq_idx = strcmp(op_names,'TriggerAcquisition');
                prot_info.acq_time = nansum(time_cost(acq_idx));
                foc_idx = strcmp(op_names,'AutoFocus');
                prot_info.focus_time = nansum(time_cost(foc_idx));
                stig_idx = strcmp(op_names,'AutoStig');
                prot_info.stig_time = nansum(time_cost(stig_idx));
                b2f_idx = strcmp(op_names,'BeamsToFibers');
                prot_info.b2f_time = nansum(time_cost(b2f_idx));
                b2f_success = sum(contains(outputval(b2f_idx),'True'));
                prot_info.b2f_num = [b2f_success,sum(b2f_idx(:))];
            end
            op_ids_incre = diff(sort(op_ids));
            if any(op_ids_incre ~= 1)
                status = 1;
                if verbose
                    fprintf(1,'\t\tprotocol.txt corrupted: ') 
                    fprintf(2, 'missing or duplicated operation entries.\n')
                end
            end
        else
            txtscout = utils_textscan(prot_data,'%d%*s%*d%s%s%s%s%f',';');
            op_ids = txtscout{1};
            op_names = txtscout{3};
            if nargout>1
                date_num = datetime(txtscout{2},'InputFormat','MM/dd/yyyy HH:mm:ss.SSS');
                prot_info.startTime = min(date_num);
                prot_info.endTime = max(date_num);
                prot_info.duration = seconds(range(date_num));
                input_val = txtscout{4};
                stg_x_idx = strcmp(op_names,'SetVariable(Stage_XPosition)');
                stg_y_idx = strcmp(op_names,'SetVariable(Stage_YPosition)');
                xx = str2double(input_val(stg_x_idx));
                yy = str2double(input_val(stg_y_idx));
                prot_info.coord = [median(xx,'omitnan'),median(yy,'omitnan')];
                
                outputval = txtscout{5};
                scanspeed_idx = find(strcmp(op_names,'SetScanspeed'),1,'last');
                if isempty(scanspeed_idx)
                    prot_info.scanspeed = nan;
                else
                    prot_info.scanspeed = str2double(input_val(scanspeed_idx));
                end
                gettiles_idx = find(strcmp(op_names,'GetTiles'),1);
                if isempty(gettiles_idx)
                    prot_info.tile_setup = '';
                else
                    prot_info.tile_setup = outputval{gettiles_idx};
                end
                
                time_cost = txtscout{6};
                stg_mv_idx = strcmp(op_names,'StageMovement');
                prot_info.stgmv_time = nansum(time_cost(stg_mv_idx));
                acq_idx = strcmp(op_names,'TriggerAcquisition');
                prot_info.acq_time = nansum(time_cost(acq_idx));
                foc_idx = strcmp(op_names,'AutoFocus');
                prot_info.focus_time = nansum(time_cost(foc_idx));
                stig_idx = strcmp(op_names,'AutoStig');
                prot_info.stig_time = nansum(time_cost(stig_idx));
                b2f_idx = strcmp(op_names,'BeamsToFibers');
                prot_info.b2f_time = nansum(time_cost(b2f_idx));
                b2f_success = sum(contains(outputval(b2f_idx),'True'));
                prot_info.b2f_num = [b2f_success,sum(b2f_idx(:))];
            end
            op_ids_incre = diff(sort(op_ids));
            if any(op_ids_incre ~= 1)
                status = 1;
                if verbose
                    fprintf(1,'\t\tprotocol.txt corrupted: ') 
                    fprintf(2, 'missing or duplicated operation entries.\n')
                end
            elseif sum(strcmp(op_names, stage_delay_str)) < mfov_num
                status = 1;
                if verbose
                    fprintf(1,'\t\tprotocol.txt corrupted: ') 
                    fprintf(2, 'missing information for some mFoVs.\n')
                end
            end
        end
        if verbose && (status == 0)
            fprintf(1,['\t\tprotocol.txt verified ',char(8718),'\n']);
        end
    catch ME
        status = 99;    % unknown error
        if verbose
            fprintf(2, '\t\tUnexpected error happened: protocol.txt NOT validated.\n')
            fprintf(2,['\t\t\tMATLAB err msg: ', ME.message,'\n'])
        end
        try
            fclose(fid);    % try to recycle file id resource
        catch
        end
    end