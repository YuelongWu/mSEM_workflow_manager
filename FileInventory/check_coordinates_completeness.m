function [status, thumbnail_coord, img_coord] = check_coordinates_completeness(section_dir, mfov_num, verbose)
    % check if the dataset has complete coordinates informations.
    % return the number of missing images and the coordinate struct for both the
    % thumbnails and full-res images.
try
    beam_coord = config_beam_coord_vectors;
    status = struct;
    status.mFoVwMissingImgs = [];
    status.mFoVwMissingThumbs = [];
    status.errRaised = false;
    
    thumbcoord_dir = [section_dir, filesep,'full_thumbnail_coordinates.txt'];
    imgcoord_dir = [section_dir, filesep,'full_image_coordinates.txt'];
    if nargin < 3
        verbose = true;
    end
    beam_num = 61;
    [statust, thumbnail_coord, img_coord] = check_full_coordinates_file_integrity(thumbcoord_dir, imgcoord_dir, mfov_num, beam_coord, verbose);
    if (statust.image_coord == 99) || (statust.thumbnail_coord == 99)
        status.errRaised = true;
        return
    elseif (statust.image_coord ~= 0) || (statust.thumbnail_coord ~= 0)
        [thumbnail_coord, img_coord] = complete_coordinates_from_subfolders(thumbnail_coord, img_coord,section_dir, beam_coord, verbose);
    end
    thumb_validated = (~isnan(thumbnail_coord.x)) & (~isnan(thumbnail_coord.y)); 
    img_validated = (~isnan(img_coord.x)) & (~isnan(img_coord.y));
    
    missing_num = [sum(thumb_validated(:) == 0), sum(img_validated(:) == 0)]; % [thumbnail, full_res]
    
    thumbnail_coord.validated_mfov = all(thumb_validated);
    img_coord.validated_mfov = all(img_validated);
    
    thumbnail_coord.expected_img_count = beam_num * ones(size(thumbnail_coord.validated_mfov));
    thumbnail_coord.expected_img_count(thumbnail_coord.validated_mfov) = ...
        thumbnail_coord.img_count(thumbnail_coord.validated_mfov);
    
    img_coord.expected_img_count = beam_num * ones(size(img_coord.validated_mfov));
    img_coord.expected_img_count(img_coord.validated_mfov) = ...
        img_coord.img_count(img_coord.validated_mfov);
    
     status.mFoVwMissingImgs = find(~img_coord.validated_mfov);
     status.mFoVwMissingThumbs = find(~thumbnail_coord.validated_mfov);
    if verbose
        if missing_num(1) > 0
            fprintf(2,['\t\tMISSING COORDINATES: mFoVs with missing thumbnail coordinates: ',...
                utils_convert_id_vector_into_str(status.mFoVwMissingThumbs),'.\n']);
        else
            fprintf(1,['\t\tThumbnail coordinate infomation is complete ',char(8718),'\n']);
        end
        if missing_num(2) > 0
            fprintf(2,['\t\tMISSING COORDINATES: mFoVs with missing full-res image coordinates: ',...
                utils_convert_id_vector_into_str(status.mFoVwMissingImgs),'.\n']);
        else
            fprintf(1,['\t\tFull-res image coordinate infomation is complete ',char(8718),'\n']);
        end
    end
catch ME
    status.errRaised = true;
    if verbose 
         fprintf(2,'\t\tUnexpected error happened when trying to verify coordinates information\n')
         fprintf(2,['\t\t\tMATLAB err msg: ', ME.message,'\n'])
    end
end
end