function [status, thumbnail_coord, img_coord] = check_full_coordinates_file_integrity(thumbcoord_dir, imgcoord_dir, mfov_num, beam_coord,verbose)
    % check the integrity of the full_image_coordinates.txt and
    % full_thumbnail_coordinates.txt. There will be a second round to
    % search the subfolders if this step fails.
    % For thumbnail, return the full information for use in overlap check, 
    % for full-res coordinates, just return the validation results 
    
    % status = 0: file intact; status = 1: file corrupted; 
    % status = 2: file missing; status = 99: unknown reason
    
    % Yuelong Wu, April 2018
    beam_num = 61;
    if nargin < 5
        verbose = true;
        if nargin < 4
            beam_coord = config_beam_coord_vectors;
        end
    end
    
    
    status = struct('image_coord', 0, 'thumbnail_coord', 0);
    thumbnail_coord = struct;
    thumbnail_coord.imgpath = repmat({''},beam_num, mfov_num);
    thumbnail_coord.x = nan(beam_num, mfov_num);
    thumbnail_coord.y = nan(beam_num, mfov_num);
    dup_info = struct;
    dup_info.img_path = {};
    dup_info.x = [];
    dup_info.y = [];
    dup_info.mfov_id = [];
    dup_info.beam_id = [];
    dup_info.act_mfov_id = [];
    thumbnail_coord.dup_info = dup_info;
    thumbnail_coord.img_count = zeros(mfov_num,1);

    img_coord = struct;
    img_coord.imgpath = repmat({''},beam_num, mfov_num);
    img_coord.x = nan(beam_num, mfov_num);
    img_coord.y = nan(beam_num, mfov_num);
    img_coord.dup_info = {};
    img_coord.img_count = zeros(mfov_num,1);

    if verbose
        fprintf('\tChecking the integrity of full_thumbnail_coordinates.txt and full_image_coordinates.txt...\n') 
    end
    try
        %% thumbails
        fid1 = fopen(thumbcoord_dir,'r');
        if fid1 == -1
            status.thumbnail_coord = 2;
            if verbose
                fprintf(1, '\t\tNo full_thumbnail_coordinates.txt found. Checking subfolders in the next step.\n')
            end
        else
            thumbdata = fread(fid1, '*char');
            fclose(fid1);
            outcell = utils_textscan(thumbdata, '%s%f%f%*f', '\t');
            thumbimg_path = outcell{1};
            thumb_x = outcell{2};
            thumb_y = outcell{3};
            
            thumbimg_path = thumbimg_path(~isnan(thumb_y));
            thumb_x = thumb_x(~isnan(thumb_y));
            thumb_y = thumb_y(~isnan(thumb_y));
            if isempty(thumb_x) || (mfov_num == 0)
                status.thumbnail_coord = 2;
                if verbose
                    fprintf(1, '\t\tNo coordinates found in full_thumbnail_coordinates.txt. Checking subfolders in the next step.\n')
                end
            else
                [thumb_path_cell, txx, tyy, thumb_dup_info, thumb_img_count] = ...
                    utils_arrange_img_coord(thumbimg_path, mfov_num, thumb_x, thumb_y, 1, verbose);
                 thumbnail_coord.imgpath = thumb_path_cell;
                 thumbnail_coord.x = txx;
                 thumbnail_coord.y = tyy;
                 thumbnail_coord.dup_info = thumb_dup_info;
                 thumbnail_coord.img_count = thumb_img_count;
                 thumbnail_coord = utils_resolve_coordinate_duplicates(thumbnail_coord,beam_coord,verbose);
                 nonvalidated_mfovs = any(isnan(thumbnail_coord.x) | isnan(thumbnail_coord.y));
                 if any(nonvalidated_mfovs)
                     status.thumbnail_coord = 1;
                     if verbose
                         fprintf(1, '\t\tMissing coordinates in full_thumbnail_coordinates.txt. Checking subfolders in the next step.\n')
                         fprintf(1, ['\t\t\tmFoV with missing coordinate:',utils_convert_id_vector_into_str(find(nonvalidated_mfovs)),'.\n'])
                     end
                 else
                     status.thumbnail_coord = 0;
                 end
            end
        end
        %% full-res images
        fid2 = fopen(imgcoord_dir,'r');
        if fid2 == -1
            status.image_coord = 2;
            if verbose
                 fprintf(1, '\t\tNo full_image_coordinates.txt found. Checking subfolders in the next step.\n')
            end
        else
            fulldata = fread(fid2, '*char');
            fclose(fid2);
            outcell = utils_textscan(fulldata, '%s%f%f%*f', '\t');
            img_path = outcell{1};
            img_x = outcell{2};
            img_y = outcell{3};
            
            img_path = img_path(~isnan(img_y));
            img_x = img_x(~isnan(img_y));
            img_y = img_y(~isnan(img_y));
            if isempty(img_x) || (mfov_num == 0)
                status.image_coord = 2;
                if verbose
                    fprintf(1, '\t\tNo coordinates found in full_image_coordinates.txt. Checking subfolders in the next step.\n')
                end
            else
                [img_path_cell, ixx, iyy, img_dup_info, img_count] = utils_arrange_img_coord(img_path, mfov_num, img_x, img_y, 0, verbose);
                img_coord.imgpath = img_path_cell;
                img_coord.x = ixx;
                img_coord.y = iyy;
                img_coord.dup_info = img_dup_info;
                img_coord.img_count = img_count;
                img_coord = utils_resolve_coordinate_duplicates(img_coord,beam_coord,verbose);
                nonvalidated_mfovs = any(isnan(img_coord.x) | isnan(img_coord.y));
                if any(nonvalidated_mfovs)
                     status.image_coord = 1;
                     if verbose
                         fprintf(1, '\t\tMissing coordinates in full_image_coordinates.txt. Checking subfolders in the next step.\n')
                         fprintf(1, ['\t\t\tmFoV with missing coordinate:',utils_convert_id_vector_into_str(find(nonvalidated_mfovs)),'.\n'])
                     end
                 else
                     status.image_coord = 0;
                 end
            end
        end
    catch ME
        status.image_coord = 99;    % unknown error
        status.thumbnail_coord = 99;
        if verbose
           fprintf(2,'\t\tUnexpected error happened: full_image_coordinates.txt and full_thumbnail_coordinates.txt NOT validated\n')
           fprintf(2,['\t\t\tMATLAB err msg: ', ME.message,'\n'])
        end
        try
           fclose(fid1);    
           fclose(fid2);   % try to recycle file id resource
        catch
        end
    end
end