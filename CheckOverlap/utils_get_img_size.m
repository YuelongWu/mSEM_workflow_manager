function imgsz = utils_get_img_size(section_dir,imgpaths)
    idx = find(~cellfun(@isempty,imgpaths));
    imgsz = [nan,nan];
    if ~isempty(idx)
        for k = 1:length(idx)
            try
                imgpath = imgpaths{idx(k)};
                if strcmpi(imgpath(end-2:end),'bmp')
                    [~,imgsz] =  utils_read_partial_bmp([section_dir,filesep,imgpath], [1,1]);
                    if isempty(imgsz) % file not exist
                        imgsz = [nan,nan];
                        continue;
                    end
                    imgsz = single(imgsz);
                else
                    A = imread([section_dir,filesep,imgpath]);
                    imgsz = [size(A,1),size(A,2)];
                end
                return;
            catch ME
                if strcmp(ME.identifier,'MATLAB:imagesci:imread:fileDoesNotExist')
                    continue;
                else
                    return;
                end
            end
        end
    end