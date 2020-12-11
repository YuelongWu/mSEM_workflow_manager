function IMQA_open_mfov_folder(src, ~, xyCoordinates, mfovId, section_dir)
   if ispc
        x = xyCoordinates(:,1);
        y = xyCoordinates(:,2);
        mouse_pos = src.CurrentPoint;
        x_click = mouse_pos(1,1);
        y_click = mouse_pos(1,2);

        Dis = (x-x_click).^2+(y-y_click).^2;
        minidx = find(Dis == min(Dis(:)),1);
        mfovid_str = pad(num2str(mfovId(minidx)),6,'left','0');
        mfov_path = [section_dir, filesep, mfovid_str];
        try
            winopen(mfov_path);
        catch
            errordlg(['Fail to open: ', mfov_path])
        end
    end
end
    