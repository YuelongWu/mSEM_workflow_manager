function [status, focus_map_data] = check_focusmap_file_integrity(focusmap_dir, fsp_num, verbose)
    % check the integrity of the FocusMap file.
    % status = 0: file intact; status = 1: file corrupted; 
    % status = 2: file missing;
    % status = 99: unknown reason
    
    % Yuelong Wu, April 2018
    status = 0;
    focus_map_data = struct('xyCoordinates',nan(1,2),'AF',true,'AS', true);
    if nargin < 3
        verbose = true;
    end
    if nargin < 2
        fsp_num = 0;  % number of focus support point. can be obtained from experiment_log.txt
    end
    
    if verbose
        fprintf('\tChecking the integrity of FocusMap.txt...\n')
    end
    
    try
        fid = fopen(focusmap_dir, 'r');
        if fid == -1
            status = 2; % file missing
            if verbose
                fprintf(2,'\t\tNo FocusMap.txt found!\n') 
            end
            return;
        end
        focusmap_data = fread(fid,'*char');
        fclose(fid);
        focusmap_cell = textscan([focusmap_data; char(13);newline],'%s%s%s%s%s%s%s%s%s%s','Delimiter',',');
        if isempty(focusmap_cell{1})
            status = 2; % file empty
            if verbose
                fprintf(2,'\t\tFocusMap.txt is empty\n') 
            end
            return;
        end
        focusmap_data =  str2double([focusmap_cell{:,2:end}]);
        fsp_id = focusmap_data(:,1);
        fsp_coord = focusmap_data(:,2:3);
        fsp_fail = sum(isnan(focusmap_data(:,4:end)),2);
        fsp_fail_count = sum(fsp_fail>0);
        focus_map_data.xyCoordinates = fsp_coord;
        focus_map_data.AF = (fsp_fail == 1) | (fsp_fail > 2);
        focus_map_data.AS = (fsp_fail == 2) | (fsp_fail > 2);
        % fsp_num_act = max(fsp_id)-min(fsp_id)+1;
        fsp_num_act = length(fsp_id);
        if sum(isnan(fsp_coord(:))) > 0
            status = 1;
            if verbose
                fprintf(1,'\t\tFocusMap.txt corrupted:')
                fprintf(2,' missing focus support points coordinates\n')
            end
        end
        if fsp_num_act < fsp_num
            status = 1;
            if verbose
                fprintf(2,'\t\tMissing focus support points: ')
                fprintf(1,[num2str(fsp_num_act),'/',num2str(fsp_num),'(found/expected)\n'])
            end
        end
        if verbose && (status == 0)
            fprintf(1,['\t\tFocusMap.txt verified ',char(8718),'\n']);
        end
        if verbose && (fsp_fail_count > 0)
            fprintf(1,['\t\t', num2str(fsp_fail_count), ' focus points failed.\n'])
        end
    catch ME
        status = 99;
        if verbose
            fprintf(2, '\t\tUnexpected error happened: FocusMap.txt NOT validated.\n')
            fprintf(2,['\t\t\tMATLAB err msg: ', ME.message,'\n'])
        end
        try
            fclose(fid);    % try to recycle file id resource
        catch
            % Tracing is the best job in the world!
        end
    end