function IMQA_open_original_images(src, ~, ovv_info)
    % check if the section folder is still in place
    section_dir = ovv_info.sectionDir;
    thumbscl = 16;
    Alpha0 = 1;
    if ~exist(section_dir,'dir')
        flag_found = false;
        load(['ConfigFiles',filesep,'path_overide_settings.mat']);
        for k = 1:length(overide_path)
            pathstr = local_recover_overriden_path(section_dir, overide_path{k});
            if exist(pathstr,'dir')
                flag_found = true;
                section_dir = pathstr;
                break;
            end
        end

        if ~flag_found
            if overide_mute   % user decided not to show images
                return
            end
            answer = questdlg('Failed to find the section folder!',...
                'Select an action', 'Manually find the folder',...
                'Ignore','Mute this message',...
                'Manually find the folder');
            switch answer
            case 'Manually find the folder'
                selpath = uigetdir('.','Select the actual location of the section folder');
                if isnumeric(selpath)
                    return
                else
                    override_struct = local_reconstruct_overriden_path(selpath, section_dir);
                    section_dir = selpath;
                    overide_path = [overide_path;{override_struct}];
                    save(['ConfigFiles',filesep,'path_overide_settings.mat'],'overide_path','overide_mute');
                end
            case 'Ignore'
                return
            case 'Mute this message'
                overide_mute = true;
                save(['ConfigFiles',filesep,'path_overide_settings.mat'],'overide_path','overide_mute');
                return
            end

        end
    end

    try opengl hardware;catch;end
    mouse_pos = src.CurrentPoint;
    x_click = mouse_pos(1,1);
    y_click = mouse_pos(1,2);
    xx = ovv_info.ovv_coord_x(:);
    yy = ovv_info.ovv_coord_y(:);
    Dis = ((x_click - xx).^2 + (y_click - yy).^2).^0.5;
    [Dis, idx] = mink(Dis, 7);
    idx = idx(~isnan(Dis));
    Dis = Dis(~isnan(Dis));
    Nsample = length(Dis);
    if isempty(Dis)
        return
    end
    if strcmpi(src.Parent.SelectionType,'normal')
        hfig = figure;
        set(hfig,'visible','off')
        hfig.NumberTitle = 'off';
        hfig.Name = 'Sample images';
        hfig.Units = 'normalized';
        Nsample = min(3,Nsample);
        hfig.OuterPosition = [0.5-0.95*Nsample/6 0.25 0.95*Nsample/3 0.6];
        try
            imgpaths = ovv_info.imgPath(idx);
            IMQA = ovv_info.IMQA(idx);
            for k = 1:Nsample
                subplot(1,Nsample,k);
                imgpath = [section_dir, filesep,imgpaths{k}];
                A = imread(imgpath);
                set(gca,'Position',[0.005+(k-1)/Nsample,0.02,(1/Nsample -0.01),0.95])
                imagesc(255-A);
                zoom(4);
                colormap(gray)
                axis equal
                axis off
                t = ylim;
                ylim([0, range(t)]);
                title([strrep(strrep(imgpaths{k},'\','\\'),'_','\_'),...
                    ' (IMQA ',num2str(IMQA(k)),')']);
            end
            set(hfig,'visible','on')
            pan on
        catch
            try disp(['Failed to load image:',section_dir, filesep,imgpath{k}]);catch;end
            try close(hfig);catch;end
        end
    elseif strcmpi(src.Parent.SelectionType,'alt')
        [mfov_idx, ~] = ind2sub(size(ovv_info.ovv_coord_x), idx(1));
        winopen([section_dir,filesep,pad(num2str(mfov_idx),6,'left','0')]);
    elseif strcmpi(src.Parent.SelectionType,'extend')
        hfig = figure;
        set(hfig,'visible','off')
        hfig.NumberTitle = 'off';
        hfig.Name = 'Sample mosaic images';
        hfig.Units = 'normalized';
        hfig.OuterPosition = [0.03 0.25 0.95 0.6];
        set(gca,'Position',[0,0,1,1]);
        set(gca,'YDir','reverse')
        hold(gca,'on');
        try
            imgpaths = ovv_info.imgPath(idx);
            X = nan(Nsample,1);
            Y = nan(Nsample,1);
            for k = 1:Nsample
                [mfov_idx, beam_idx] = ind2sub(size(ovv_info.ovv_coord_x), idx(k));
                X(k) = thumbscl*(ovv_info.mfov_x(mfov_idx) + ovv_info.sfov_coord(beam_idx,1));
                Y(k) = thumbscl*(ovv_info.mfov_y(mfov_idx) + ovv_info.sfov_coord(beam_idx,2));
                imgpath = [section_dir, filesep,imgpaths{k}];
                A = imread(imgpath);
                imagesc(X(k),Y(k),255-A,'AlphaData',Alpha0);
                colormap(gray)
                axis equal
                axis off
            end
            set(hfig,'Visible','on')
            zoom(4);
            pan on
        catch
            try disp(['Failed to load image:',section_dir, filesep,imgpath{k}]);catch;end
            try 
                set(hfig,'Visible','on');
            catch
            end
        end
    end

end

function pathstr = local_recover_overriden_path(pathstr, override_struct)
    N = override_struct.level;
    tmpstr = [];
    for k = 1:N
        [pathstr, subfolder] = fileparts(pathstr);
        tmpstr = [filesep,subfolder,tmpstr];
    end
    pathstr = [override_struct.path, tmpstr];
end

function override_struct = local_reconstruct_overriden_path(section_dir_new, section_dir_old)
    override_struct = struct;
    N = 0;
    tmpstr = [];
    pathstr1 = section_dir_new;
    pathstr2 = section_dir_old;
    cont_flag = true;
    while cont_flag
        [pathstr1, subfolder1] = fileparts(pathstr1);
        [pathstr2, subfolder2] = fileparts(pathstr2);
        if strcmpi(subfolder1,subfolder2) && ~isempty(subfolder1) && ~isempty(subfolder2)
            N = N+1;
        else
            tmpstr = [pathstr1, filesep, subfolder1];
            cont_flag = false;
        end
    end
    override_struct.level = N;
    override_struct.path = tmpstr;
end