function [outimg,imgsz] = utils_read_bmp_in_normal_way(img_dir, row_range)
    if nargin < 2
        row_range = [];
    end
    try
        outimg = imread(img_dir);
        imgsz = size(outimg);
    catch
        outimg = imread([img_dir(1:end-3),'jp2']);
        imgsz = size(outimg);
    end
    if ~isempty(row_range)
        row_start = max(1,row_range(1));
        row_end = min(size(outimg,1),row_range(2));
        outimg = outimg(row_start:row_end,:,1);
    end
end
