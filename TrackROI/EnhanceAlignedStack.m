[VideoFile, VideoPath] = uigetfile('*.avi');
if isnumeric(VideoFile)
    return
end
v = VideoReader([VideoPath,VideoFile]);
OutputPath = [VideoPath, 'Enhanced_aligned_overviews_subsampled'];
if ~exist(OutputPath,'dir')
    mkdir(OutputPath)
end
Nstack = 10;
imgstack = zeros(512,512,Nstack);
k = 1;
k1 = 1;
while hasFrame(v)
    img = readFrame(v);
    imgf = single(utils_enhance_nucleus_and_blood_vessels(img(44+(1:512),1+(1:512))));
    imgstack(:,:,mod(k,Nstack)+1) = single(imgf > (mean(imgf(imgf>0))+10));
    if mod(k,Nstack) == 0
        imgf = imopen(mean(imgstack,3)>0.5,ones(3,3));
        imwrite(uint8(imgf*255),[OutputPath,filesep, pad(num2str(k1),7,'left','0'),'.tif']);
        k1 = k1+1;
    end
    k = k+1;
end
delete(v);