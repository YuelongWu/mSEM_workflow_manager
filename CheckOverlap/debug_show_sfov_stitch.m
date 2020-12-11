function outputimg = debug_show_sfov_stitch(section_dir,imgpath,sfov_coord,imgsz)
    sfov_x = sfov_coord(:,1);
    sfov_x = round(sfov_x-min(sfov_x));
    sfov_y = sfov_coord(:,2);
    sfov_y = round(sfov_y-min(sfov_y));
    imght = imgsz(1);
    imgwd = imgsz(2);
    mfov_img1 = zeros(max(sfov_y)+imght,max(sfov_x)+imgwd,'uint8');
    mfov_img2 = mfov_img1;
    for k = 1:61
        img1 = imread([section_dir,filesep,imgpath{k}]);
        if k~=31
            img2 = imread([section_dir,filesep,imgpath{62-k}]);
        else
            img2 = img1;
        end
        mfov_img1(sfov_y(k)+(1:imght),sfov_x(k)+(1:imgwd)) = img1(:,:,1);
        mfov_img2(sfov_y(62-k)+(1:imght),sfov_x(62-k)+(1:imgwd)) = img2(:,:,1);
    end
    outputimg = cat(3,mfov_img1,mfov_img2,mfov_img1);