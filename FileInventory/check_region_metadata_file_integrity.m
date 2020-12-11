function [status, corrupt_type, region_meta_data] = check_region_metadata_file_integrity(region_metadata_dir, mfov_num, verbose)
    % check the integrity of the region_metadata.csv and return the data
    % status = 0: file intact; status = 1: file corrupted; 
    % status = 2: file missing; status = 99: unknown reason
    % corrupt_type.field = 0: good; 1: incomplete; 2: missing
    
    % assume IMQA is always the last columns
    
    % Yuelong Wu, April 2018
    %% Initialization
    beam_num = 61;
    status = 0;
    corrupt_type = struct('mfovId',0,'storagePath',0,...
                          'xyCoordinates',0,'IMQA',0); 
    region_meta_data = struct('mfovId',nan,'storagePath','',...
                          'xyCoordinates',nan(1,2),'IMQA',nan(1,61));
    if nargin<3
        verbose = true;
        if nargin < 2
            mfov_num = 0;
        end
    end
    
    if verbose
        fprintf('\tChecking the integrity of region_metadata.csv...\n')
    end
    %%
    try
        %% check file existance
        fid = fopen(region_metadata_dir, 'r');
        if fid == -1
            status = 2; % file missing
            if verbose
                fprintf(2, '\t\tNo region_metadata.csv found!\n')
            end
            return;
        end
        %% Read CSV header
        metadata_header = fgetl(fid);
        if strcmp(metadata_header, 'sep=;')
            metadata_header = fgetl(fid);
        end
        column_names = strsplit(metadata_header,';');
        mFoV_idx = find(strcmpi(column_names, 'MFoV Number'),1);
        Path_idx = find(strcmpi(column_names, 'Storage Path'),1);
        StageX_idx = find(strcmpi(column_names, 'StagePositionXMonitor'),1);
        StageY_idx = find(strcmpi(column_names, 'StagePositionYMonitor'),1);
        IMQA_idx = find(strcmpi(column_names, 'IMQA'),1);
        
        if isempty(mFoV_idx)
            status = 1;
            corrupt_type.mfovId = 2;
            fclose(fid);
            if verbose
                fprintf(1,'\t\tregion_metadata.csv corrupted: ') 
                fprintf(2, 'missing "MFoV Number" in header.\n')
            end
            return;
        end
       
        %% Read CSV contents
        fmtstr = [repmat({'%s'}, 1, length(column_names) - 1), repmat({'%f'}, 1, beam_num)];
        fmtstr(mFoV_idx) = {'%f'};
        fmtstr(StageX_idx) = {'%f'};
        fmtstr(StageY_idx) = {'%f'};
        fmtstr = horzcat(fmtstr{:});
        
        csv_data = fread(fid,'*char');
        fclose(fid);
        metadata_cell = utils_textscan(csv_data,fmtstr,';');
        mFoV_id = metadata_cell{mFoV_idx};
        mFov_pos_bool = (mFoV_id > 0) & (abs(mFoV_id-round(mFoV_id))<0.00000001);
        if sum(mFov_pos_bool(:)) == 0
            status = 1;
            corrupt_type.mfovId = 2;
            if verbose
                fprintf(1,'\t\tregion_metadata.csv potentially corrupted: ') 
                fprintf(2, 'No mFoV presents in the file.\n')
            end
            return;
        end
        region_meta_data.mfovId = mFoV_id(mFov_pos_bool);
        miss_mfov_flag = (min(region_meta_data.mfovId(:)) > 1) || ...
            (max(region_meta_data.mfovId(:)) < mfov_num) || ...
            (length(region_meta_data.mfovId(:)) < max(region_meta_data.mfovId(:)));
        if corrupt_type.mfovId == 0 && miss_mfov_flag
           status = 1;
           corrupt_type.mfovId = 1;
            if verbose
               fprintf(1,'\t\tregion_metadata.csv corrupted: ') 
               fprintf(2, 'missing mFoVs.\n')
           end
       end
        
        if ~isempty(Path_idx)
            stored_path = metadata_cell{Path_idx};
        else
            stored_path = repmat({''}, size(mFoV_id));
            status = 1;
            corrupt_type.storagePath = 2;
            if verbose
                fprintf(1,'\t\tregion_metadata.csv corrupted: ') 
                fprintf(2, 'missing "Storage Path" in header.\n')
            end
        end
       region_meta_data.storagePath = stored_path(mFov_pos_bool);
       if corrupt_type.storagePath == 0 && sum(cellfun(@isempty,region_meta_data.storagePath))>0
           status = 1;
           corrupt_type.storagePath = 1;
            if verbose
               fprintf(1,'\t\tregion_metadata.csv corrupted: ') 
               fprintf(2, 'missing storage path for some mFoVs.\n')
           end
       end
       
       
       if ~isempty(StageX_idx)
            stagex = metadata_cell{StageX_idx};
        else
            stagex = nan(size(mFoV_id));
            status = 1;
            corrupt_type.xyCoordinates = 2;
            if verbose
                fprintf(1,'\t\tregion_metadata.csv corrupted: ') 
                fprintf(2, 'missing "StagePositionXMonitor" in header.\n')
            end
       end
       if ~isempty(StageY_idx)
           stagey = metadata_cell{StageY_idx};
       else
           stagey = nan(size(mFoV_id));
           status = 1;
           corrupt_type.xyCoordinates = 2;
           if verbose
               fprintf(1,'\t\tregion_metadata.csv corrupted: ') 
               fprintf(2, 'missing "StagePositionYMonitor" in header.\n')
           end
       end
       region_meta_data.xyCoordinates = [stagex(mFov_pos_bool),stagey(mFov_pos_bool)];
       if corrupt_type.xyCoordinates == 0 && sum(isnan(region_meta_data.xyCoordinates(:)))>0
           status = 1;
           corrupt_type.xyCoordinates = 1;
           if verbose
               fprintf(1,'\t\tregion_metadata.csv corrupted: ') 
               fprintf(2, 'missing coordinates for some mFoVs.\n')
           end
       end
       
       
       if ~isempty(IMQA_idx)
           IMQA = [metadata_cell{IMQA_idx:end}];
       else
           IMQA = nan(size(mFoV_id,1),beam_num);
           status = 1;
           corrupt_type.IMQA = 2;
           if verbose
               fprintf(1,'\t\tregion_metadata.csv corrupted: ') 
               fprintf(2, 'missing "IMQA" in header.\n')
           end
       end
       region_meta_data.IMQA = IMQA(mFov_pos_bool,:);
       if corrupt_type.IMQA == 0 && sum(isnan(region_meta_data.IMQA(:)))>0
           status = 1;
           corrupt_type.IMQA = 1;
            if verbose
               fprintf(1,'\t\tregion_metadata.csv corrupted: ') 
               fprintf(2, 'missing IMQA for some mFoVs or beams.\n')
           end
       end
       if verbose && (status == 0)
            fprintf(1,['\t\tregion_metadata.csv verified ',char(8718),'\n']);
       end
        
    catch ME
        status = 99;    % unknown error
        if verbose
           fprintf(2,'\t\tUnexpected error happened: region_metadata.csv NOT validated\n')
           fprintf(2,['\t\t\tMATLAB err msg: ', ME.message,'\n'])
        end
        try
            fclose(fid);    % try to recycle file id resource
        catch
        end
    end
end