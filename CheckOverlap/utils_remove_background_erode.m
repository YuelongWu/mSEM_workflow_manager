function img = utils_remove_background_erode(img, window_size)
    % remove the background grayscale level estimated by image erosion
    if nargin < 2
        window_size = 3;
    end
    bckgrnd = imerode(img, ones(window_size,window_size));
    img = img - bckgrnd;
end