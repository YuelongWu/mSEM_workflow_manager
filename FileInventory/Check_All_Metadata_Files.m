function [general_info, IMQA_info, coord_info, prot_info] = Check_All_Metadata_Files(section_dir, sys_result_dir, exp_log_info, verbose)
% validate the metadata information include:
%   number of mFoV folders
%   region_metadata.csv
%   FocusMap.txt
%   protocol.txt
%   coordinate information

% general_info.*_status - save the results of the integrity check.
% general_info.do* - plan whether to do a certain check in the next steps.
% IMQA_info - information about image quality.
% coord_info - information about the image/thumbnail coordinates.

% Yuelong Wu, May 2018

if nargin < 4
    verbose = true;
    if nargin < 3
        exp_log_info = struct;
        exp_log_info.mfov_num = 0;
        exp_log_info.fsp_num = 0;
        exp_log_info.duration = 0;
    end
end


try
    general_info = struct;
    IMQA_info = struct;
    coord_info = struct;
    prot_info = struct;
    
    general_info.section_dir = section_dir;
    general_info.section_dirn = utils_add_disk_label_to_sectiondir(section_dir);
    general_info.duration = exp_log_info.duration;
    general_info.fsp_num = exp_log_info.fsp_num;
    general_info.doImgCheck = true;
    general_info.doMfovOverlapCheck = true;
    general_info.doSfovOverlapCheck = true;
    general_info.doIMQAPlot = true;
    general_info.doJittering = true;
    general_info.doROITracking = true;
    general_info.AFAS = false;
    general_info.metaErrRaised = false;
    general_info.metaBytes = 0;
    
    sys_output_dir = [sys_result_dir, filesep, 'metadata_file_info.mat'];
    
    if nargin < 4
        verbose = true;
    end
    
    if verbose
        fprintf(1,'\tValidating the metadata files...\n');
    end
    [exist_AFAS_folder, mFoV_ids, meta_bytes] = dir_section_folders(section_dir);
    general_info.metaBytes = meta_bytes;
    general_info.folder_mFoV_ids = mFoV_ids;
    general_info.exist_AFAS_folder = exist_AFAS_folder;
    if isempty(mFoV_ids)
        mfov_num = 0;
    else
        mfov_num = max(mFoV_ids);
    end
    mfov_num = max(mfov_num,exp_log_info.mfov_num);
    general_info.mfov_num = mfov_num; % total mFoV numbers
    if mfov_num == 0
        if verbose
            if exist_AFAS_folder
                fprintf(2,'\t\tAFAS Failure: '); fprintf(1, 'No mFoV acquired.\n');
                general_info.AFAS = true;
            else
                fprintf(2,'\t\tNo mFoV or AFAS folder detected.\n');
            end
        end
        general_info.doImgCheck = false;
        general_info.doMfovOverlapCheck = false;
        general_info.doSfovOverlapCheck = false;
        general_info.doIMQAPlot = false;
        general_info.doJittering = false;
        general_info.doROITracking = false;
        save(sys_output_dir,'general_info','IMQA_info','coord_info','prot_info');
        
    end
    
    % region_metadata.csv
    [status, corrupt_type, region_meta_data] = check_region_metadata_file_integrity([section_dir, filesep, 'region_metadata.csv'], mfov_num, verbose);
    if (status == 2) || (corrupt_type.mfovId == 2) || (corrupt_type.IMQA == 2) || (corrupt_type.xyCoordinates == 2)|| (status == 99)
        general_info.doIMQAPlot = false;
    end
    if status == 99
        general_info.metaErrRaised = true;
    end
    general_info.regionMetadata_status = status;
    general_info.regionMetadata_corruptType = corrupt_type;
    IMQA_info.regionMetadata = region_meta_data;
    mfov_num = max(mfov_num, max(region_meta_data.mfovId(:)));
    general_info.mfov_num = mfov_num;
    
    % FocusMap.txt
    [status, focus_map_data] = check_focusmap_file_integrity([section_dir, filesep, 'FocusMap.txt'], exp_log_info.fsp_num, verbose);
    general_info.focusMap_status = status;
    IMQA_info.focusMapData = focus_map_data;
    
    % protocol.txt
    [status, prot_info] = check_protocol_file_integrity([section_dir, filesep, 'protocol.txt'], mfov_num, verbose);
    general_info.protocol_status = status;
    if status == 99
        general_info.metaErrRaised = true;
    end
    
    % workflow
    if exist([section_dir, filesep, 'workflow.xaml'],'file')
        general_info.workflow_status = 0;
    else
        general_info.workflow_status = 1;
    end
    
    
    % coordinates
    [status, thumbnail_coord, img_coord]  = check_coordinates_completeness(section_dir, mfov_num, verbose);
    general_info.coord_status = status;
    coord_info.thumbnail_coord = thumbnail_coord;
    coord_info.img_coord = img_coord;
    [vec_alpha, vec_beta] = utils_estimate_alpha_beta_vectors(thumbnail_coord.x, thumbnail_coord.y);
    coord_info.thumb_alpha = vec_alpha;
    coord_info.thumb_beta = vec_beta;
    if any(isnan(vec_alpha)) || any(isnan(vec_beta)) || status.errRaised
        general_info.doMfovOverlapCheck = false;
        general_info.doSfovOverlapCheck = false;
        general_info.doJittering = false;
        general_info.doROITracking = false;
        if verbose
            fprintf(2,'\t\tNot enough coordinate information to continue the following validation steps.\n')
        end
    end
    if status.errRaised
        general_info.metaErrRaised = true;
    end
    try
        [coord_info_t, coord_info] = utils_copy_between_fullres_and_thumbnail(coord_info);
    catch
    end
    save(sys_output_dir,'general_info','IMQA_info','coord_info','prot_info');
    coord_info = coord_info_t;
catch metaME
     general_info.metaErrRaised = true;
     
     general_info.doImgCheck = false;
     general_info.doMfovOverlapCheck = false;
     general_info.doSfovOverlapCheck = false;
     general_info.doJittering = false;
     general_info.doROITracking = false;
     general_info.doIMQAPlot = false;
     save(sys_output_dir,'general_info','IMQA_info','coord_info','prot_info','metaME');
     if verbose
           fprintf(2,'\t\tUnexpected error happened when verifying metadata files.\n')
           fprintf(2,['\t\t\tMATLAB err msg: ', metaME.message,'\n'])
     end
end
end