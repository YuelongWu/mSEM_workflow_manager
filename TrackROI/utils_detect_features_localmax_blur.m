function [XY, metrics] = utils_detect_features_localmax_blur(imgf,sigma, r)
    if nargin < 3
        r = 4.5;
        if nargin < 2
            sigma = 3.5;
        end
    end
    % imglp = imgaussfilt(imgf,2.5) + 0.25*imgaussfilt(imgf,10);
    imglp = max(0,-imfilter(max(imgf,0),fspecial('log',1+2*round(sigma*2.5),sigma)));
    pkimg = (imglp == imdilate(imglp,strel('disk',7))) & bwareaopen(imglp>(max(imglp(:))/r),10);
    [feature_y, feature_x] = find(pkimg);
    metrics = imglp(pkimg);
    XY = [feature_x(:),feature_y(:)];
    % if min(imgf(:)) < 0
    %     imglp = max(0,-imfilter(max(-imgf,0),fspecial('log',1+2*round(sigma*2.5),sigma)));
    %     pkimg = (imglp == imdilate(imglp,strel('disk',7))) & bwareaopen(imglp>(max(imglp(:))/r.^0.75),10);
    %     [feature_y, feature_x] = find(pkimg);
    %     metrics1 = imglp(pkimg);
    %     XY1 = [feature_x(:),feature_y(:)];
    %     metrics = [metrics(:);metrics1(:)];
    %     XY = [XY;XY1];
    % end
end