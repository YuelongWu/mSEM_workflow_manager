function [thumbnail_coord, img_coord] = complete_coordinates_from_subfolders(thumbnail_coord, img_coord,section_dir,beam_coord, verbose)
    % searching mfov folders for thumbnail_coordinates.txt and
    % image_coordinates.txt if the full_*_coordinates.txt in the section
    % folder are not complete.
    %% thumbnails
    if nargin < 5
        verbose = true;
        if nargin < 4
            beam_coord = config_beam_coord_vectors;
        end
    end
    if verbose
        fprintf('\t\tTrying to find the missing coordinates from mFoV folders...\n') 
    end
    beam_num = 61;
    try
    nonvalidated_mfovs = find(any(isnan(thumbnail_coord.x) | isnan(thumbnail_coord.y)));
    dup_info = thumbnail_coord.dup_info;
    dup_updated = false;
    for m = 1:length(nonvalidated_mfovs)
        mfov_id = nonvalidated_mfovs(m);
        mfov_folder_name = pad(num2str(mfov_id), 6, 'left', '0');
        subfolder_thumbcoord_file = [section_dir, filesep, mfov_folder_name, filesep, 'thumbnail_coordinates.txt'];
        fid1 = fopen(subfolder_thumbcoord_file,'r');
        if fid1 == -1
            continue
        end
        coord_data = fread(fid1, '*char');
        fclose(fid1);
        outcell = utils_textscan(coord_data, '%s%f%f%*f', '\t');
        thumb_path = outcell{1};
        thumb_x = outcell{2};
        thumb_y = outcell{3};
        thumb_path = thumb_path(~isnan(thumb_y));
        thumb_x = thumb_x(~isnan(thumb_y));
        thumb_y = thumb_y(~isnan(thumb_y));
        if isempty(thumb_x)
            continue;
        end
        [m_id, b_id] = utils_parse_thumbnail_image_name(thumb_path);
        valid_idx = (m_id>0) & (b_id>0) & (b_id <= beam_num);
        thumbnail_coord.img_count(mfov_id) = sum(valid_idx);
        thumb_path = thumb_path(valid_idx);
        thumb_path = strcat(mfov_folder_name,'\',thumb_path);
        thumb_x = thumb_x(valid_idx);
        thumb_y = thumb_y(valid_idx);
        m_id = m_id(valid_idx); b_id = b_id(valid_idx);
        beam_count_61 = histcounts(b_id, 0.5:1:(beam_num+0.5));
        beam_count = beam_count_61(b_id);
        dup_beam_idx = beam_count > 1;
        if any(dup_beam_idx)
            dup_info.img_path = [dup_info.img_path;thumb_path(dup_beam_idx)];
            dup_info.x = [dup_info.x;thumb_x(dup_beam_idx)];
            dup_info.y = [dup_info.y;thumb_y(dup_beam_idx)];
            dup_info.mfov_id = [dup_info.mfov_id;m_id(dup_beam_idx)];
            dup_info.beam_id = [dup_info.beam_id;b_id(dup_beam_idx)];
            dup_info.act_mfov_id = [dup_info.beam_id;nan(size(thumb_x(dup_beam_idx)))];
            dup_updated = true;
        end
        legit_beam_bool = (beam_count == 1);
        if any(legit_beam_bool)
            indx = b_id(legit_beam_bool) + (m_id(legit_beam_bool) - 1) * beam_num;
            thumbnail_coord.imgpath(indx) = thumb_path(legit_beam_bool);
            thumbnail_coord.x(indx) = thumb_x(legit_beam_bool);
            thumbnail_coord.y(indx) = thumb_y(legit_beam_bool);
        end
    end
    if dup_updated
        [~, unidx, ~] = unique(dup_info.img_path, 'occurrence', 'first');
        thumbnail_coord.dup_info.img_path = dup_info.img_path(unidx);
        thumbnail_coord.dup_info.x = dup_info.x(unidx);
        thumbnail_coord.dup_info.y = dup_info.y(unidx);
        thumbnail_coord.dup_info.mfov_id = dup_info.mfov_id(unidx);
        thumbnail_coord.dup_info.beam_id = dup_info.beam_id(unidx);
        thumbnail_coord.dup_info.act_mfov_id = dup_info.act_mfov_id(unidx);
    end
    thumbnail_coord = utils_resolve_coordinate_duplicates(thumbnail_coord, beam_coord, verbose);
    %% full-res images
    nonvalidated_mfovs = find(any(isnan(img_coord.x) | isnan(img_coord.y)));
    dup_info = img_coord.dup_info;
    dup_updated = false;
    for m = 1:length(nonvalidated_mfovs)
        mfov_id = nonvalidated_mfovs(m);
        mfov_folder_name = pad(num2str(mfov_id), 6, 'left', '0');
        subfolder_imgcoord_file = [section_dir, filesep, mfov_folder_name, filesep, 'image_coordinates.txt'];
        fid2 = fopen(subfolder_imgcoord_file,'r');
        if fid2 == -1
            continue
        end
        coord_data = fread(fid2, '*char');
        fclose(fid2);
        outcell = utils_textscan(coord_data, '%s%f%f%*f', '\t');
        img_path = outcell{1};
        img_x = outcell{2};
        img_y = outcell{3};
        img_path = img_path(~isnan(img_y));
        img_x = img_x(~isnan(img_y));
        img_y = img_y(~isnan(img_y));
        if isempty(img_x)
            continue;
        end
        [m_id, b_id] = utils_parse_fullres_image_name(img_path);
        valid_idx = (m_id>0) & (b_id>0) & (b_id <= beam_num);
        img_coord.img_count(mfov_id) = sum(valid_idx);
        img_path = img_path(valid_idx);
        img_path = strcat(mfov_folder_name,'\',img_path);
        img_x = img_x(valid_idx);
        img_y = img_y(valid_idx);
        m_id = m_id(valid_idx); b_id = b_id(valid_idx);
        beam_count_61 = histcounts(b_id, 0.5:1:(beam_num+0.5));
        beam_count = beam_count_61(b_id);
        dup_beam_idx = beam_count > 1;
        if any(dup_beam_idx)
            dup_info.img_path = [dup_info.img_path;img_path(dup_beam_idx)];
            dup_info.x = [dup_info.x;img_x(dup_beam_idx)];
            dup_info.y = [dup_info.y;img_y(dup_beam_idx)];
            dup_info.mfov_id = [dup_info.mfov_id;m_id(dup_beam_idx)];
            dup_info.beam_id = [dup_info.beam_id;b_id(dup_beam_idx)];
            dup_info.act_mfov_id = [dup_info.beam_id;nan(size(img_x(dup_beam_idx)))];
            dup_updated = true;
        end
        legit_beam_bool = (beam_count == 1);
        if any(legit_beam_bool)
            indx = b_id(legit_beam_bool) + (m_id(legit_beam_bool) - 1) * beam_num;
            img_coord.imgpath(indx) = img_path(legit_beam_bool);
            img_coord.x(indx) = img_x(legit_beam_bool);
            img_coord.y(indx) = img_y(legit_beam_bool);
        end
    end
    if dup_updated
        [~, unidx, ~] = unique(dup_info.img_path); % default first occurrence
        img_coord.dup_info.img_path = dup_info.img_path(unidx);
        img_coord.dup_info.x = dup_info.x(unidx);
        img_coord.dup_info.y = dup_info.y(unidx);
        img_coord.dup_info.mfov_id = dup_info.mfov_id(unidx);
        img_coord.dup_info.beam_id = dup_info.beam_id(unidx);
        img_coord.dup_info.act_mfov_id = dup_info.act_mfov_id(unidx);
    end
    img_coord = utils_resolve_coordinate_duplicates(img_coord,beam_coord,verbose);
    catch
        try
            fclose(fid1);
            fclose(fid2);
        catch
        end
    end
end