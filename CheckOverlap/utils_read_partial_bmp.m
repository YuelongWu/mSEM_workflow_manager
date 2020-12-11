function [outimg, imgsz] = utils_read_partial_bmp(img_dir, row_range)
    outimg = [];
    imgsz = [nan,nan];
    try
        fid = fopen(img_dir,'r');
        if fid == -1
            imgsz = [];
            return
        end
        fseek(fid,10,-1);
        pxl_offset = fread(fid,1,'*uint32');
        tmp_buff = fread(fid,5,'*int32');
        if tmp_buff(1)~= 40
            fclose(fid);
            outimg = utils_read_bmp_in_normal_way(img_dir, row_range);
            return
        end
        imgwd = abs(tmp_buff(2));
        imght = abs(tmp_buff(3));
        imgsz = [imght, imgwd];
        tmp_buff2 = typecast(tmp_buff(4),'uint16');
        if (tmp_buff2(1)~=1) || (tmp_buff2(2)~=8) || tmp_buff(5)~=0
            fclose(fid);
            outimg = utils_read_bmp_in_normal_way(img_dir, row_range);
            return
        end
        
        row_start = max(1,row_range(1));
        row_end = min(imght,row_range(2));
        rowoffset = (row_start-1)*imgwd;
        Nrow = (row_end-row_start+1);
        fseek(fid,pxl_offset+uint32(rowoffset),-1);
        imgstr = fread(fid,Nrow*imgwd,'*uint8');
        outimg = reshape(imgstr,imgwd,Nrow)';
        fclose(fid);
    catch
        try
            fclose(fid); % recycle file object resources
        catch
        end
        try
            [outimg, imgsz] = utils_read_bmp_in_normal_way(img_dir, row_range);
        catch ME
            if strcmp(ME.identifier,'MATLAB:imagesci:imread:fileDoesNotExist')
                imgsz = [];
            end
        end
    end
end
