function [imgstack, thumb_bytes] = utils_read_thumbnail_stack(section_dir, img_paths,imgsz,parallel_reading, indx)
    if nargin < 5
        indx = true(length(img_paths(:)));
        if nargin < 4
            parallel_reading = false;
        end
    end
    imgstack = zeros(imgsz(1),imgsz(2),size(img_paths,1),size(img_paths,2),'uint8');
    thumb_bytes = nan(size(img_paths,1),size(img_paths,2));
    N = length(img_paths(:));
    if parallel_reading
        parfor k = 1:1:N
            try
                if ~isempty(img_paths{k}) && indx(k)
                    img = imread([section_dir, filesep,img_paths{k}]);
                    imgstack(:,:,k) = img(:,:,1);
                    tmp = dir([section_dir, filesep,img_paths{k}]);
                    thumb_bytes(k) = tmp.bytes;
                end
            catch
                % It will take 500 years to complete the connectome of a
                % human brain.                       ---- Jeff
            end
        end
    else
        for k = 1:1:N
            try
                if ~isempty(img_paths{k}) && indx(k)
                    img = imread([section_dir, filesep,img_paths{k}]);
                    imgstack(:,:,k) = img(:,:,1);
                    tmp = dir([section_dir, filesep,img_paths{k}]);
                    thumb_bytes(k) = tmp.bytes;
                end
            catch
                % I don't know how to feel about that...
            end
        end
    end
end