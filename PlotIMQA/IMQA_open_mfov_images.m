function IMQA_open_mfov_images(src, ~, xyCoordinates, mfovId, section_dir, IMQA)
   if ispc
       try opengl hardware;catch;end
        x = xyCoordinates(:,1);
        y = xyCoordinates(:,2);
        mouse_pos = src.CurrentPoint;
        x_click = mouse_pos(1,1);
        y_click = mouse_pos(1,2);

        Dis = (x-x_click).^2+(y-y_click).^2;
        minidx = find(Dis == min(Dis(:)),1);
        mfovid_str = pad(num2str(mfovId(minidx)),6,'left','0');
        mfov_path = [section_dir, filesep, mfovid_str];
        if strcmpi(src.Parent.SelectionType,'normal')
            mfov_img_path = dir([mfov_path,filesep,'*.bmp']);
            [~,mnidx] = min(IMQA(minidx,:));
            [~,mxidx] = max(IMQA(minidx,:));
            [~,mdidx] = min(abs(IMQA(minidx,:)-median(IMQA(minidx,:),'omitnan')));
            mnidx = max(mnidx,1);
            mxidx = min(mxidx,length(mfov_img_path));
            mdidx = min(max(mdidx,1),length(mfov_img_path));
            % hfig = figure(531);
            hfig = figure;
            set(hfig,'visible','off')
            hfig.NumberTitle = 'off';
            hfig.Name = 'Sample images';
            hfig.Units = 'normalized';
            hfig.OuterPosition = [0.03 0.25 0.95 0.6];
            A = imread([mfov_img_path(mnidx).folder,filesep,mfov_img_path(mnidx).name]);
            subplot(1,3,1);
            imagesc(255-A);
            set(gca,'Position',[0.01,0.02,0.32,0.95])
            zoom(4);
            colormap(gray)
            axis equal
            axis off
            title(strrep(strrep([mfovid_str,filesep,mfov_img_path(mnidx).name, ' (min IMQA ',num2str(squeeze(min(min(IMQA(minidx,:,:))))),')'],'\','\\'),'_','\_'));
            A = imread([mfov_img_path(mdidx).folder,filesep,mfov_img_path(mdidx).name]);
            subplot(1,3,2);
            imagesc(255-A);
            set(gca,'Position',[0.34,0.02,0.32,0.95])
            zoom(4);
            colormap(gray)
            axis equal
            axis off
            title(strrep(strrep([mfovid_str,filesep,mfov_img_path(mdidx).name, ' (median IMQA ',num2str(median(IMQA(minidx,:),'omitnan')),')'],'\','\\'),'_','\_'));
            A = imread([mfov_img_path(mxidx).folder,filesep,mfov_img_path(mxidx).name]);
            subplot(1,3,3);
            imagesc(255-A);
            set(gca,'Position',[0.67,0.02,0.32,0.95])
            zoom(4);
            colormap(gray)
            axis equal
            axis off
            title(strrep(strrep([mfovid_str,filesep,mfov_img_path(mxidx).name, ' (max IMQA ',num2str(squeeze(max(max(IMQA(minidx,:,:))))),')'],'\','\\'),'_','\_'));
            set(hfig,'visible','on')
            pan on
        else
            winopen(mfov_path);
        end
    end
end
    