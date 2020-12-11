function hIMQA = utils_init_quality_map(ovv_info, IMQA_options,res_sec_dir, handles)
    scl = 0.5;
    ovv_info.overview_scl = ovv_info.overview_scl*scl;
    ovv_info.ovv_coord_x = ovv_info.ovv_coord_x*scl;
    ovv_info.ovv_coord_y = ovv_info.ovv_coord_y*scl;
    fontsz = 8;
    mapAlpha = handles.mapAlpha;  % transparency of the IMQA map
    hIMQA = cell(6,1);
    % hIMQA cell {1:mFoV#; 2:FSP; 3:overview image; 4:IMQA map; 5:axes of IMQA map; 
    % 6 :threshold numbers}

    showOVV = false;
    % Decide the figure size & reverify the options
    figcntr = [0.49, 0.58];
    target_fig_size = [0.92 0.68];
    screenSize = get(0,'Screensize');
    xrange = nan(3,2);
    yrange = nan(3,2);

    ovv_mfov_x = median(ovv_info.ovv_coord_x,2,'omitnan');
    ovv_mfov_y = median(ovv_info.ovv_coord_y,2,'omitnan');
    dssz = ceil(ovv_info.thumbsize*ovv_info.overview_scl);
    if IMQA_options(1) || IMQA_options(4)
        try
            txrange = [min(ovv_info.ovv_coord_x(:))-dssz(2)/2,max(ovv_info.ovv_coord_x(:))+dssz(2)/2];
            tyrange = [min(ovv_info.ovv_coord_y(:))-dssz(1)/2,max(ovv_info.ovv_coord_y(:))+dssz(1)/2];
            xrange(1,:) = txrange;
            yrange(1,:) = tyrange;
            if any(isnan(txrange)) || any(isnan(tyrange))
                IMQA_options(1) = false;
                set(handles.checkbox_mfov,'Enable','off');
                IMQA_options(4) = false;
                set(handles.checkbox_sfov,'Enable','off');
            end
        catch
            IMQA_options(1) = false;
            set(handles.checkbox_mfov,'Enable','off');
            IMQA_options(4) = false;
            set(handles.checkbox_sfov,'Enable','off');
        end
    end
    if IMQA_options(2) % plot FSP
        stage_coord = ovv_info.stageCoord;
        ICS_coord = [ovv_mfov_x(:), ovv_mfov_y(:)];
        FSP_stgcoord = ovv_info.focusMapData.xyCoordinates;
        [FSP_coord, sflag] =  local_stage2ICS_transform(stage_coord, ICS_coord, FSP_stgcoord, ovv_info.overview_scl);
        if ~sflag
            IMQA_options(2) = false;
            set(handles.checkbox_fsp,'Enable','off');
        end
        xrange(2,:) = [min(FSP_coord(:,1))-50,max(FSP_coord(:,1))+50];
        yrange(2,:) = [min(FSP_coord(:,2))-50,max(FSP_coord(:,2))+50];
    end
    if IMQA_options(3) % show overview image
        try
            [res_batch_dir, sec_name] = fileparts(res_sec_dir);
            if scl == 1
                OVVIMG = imread([res_batch_dir, filesep, 'overview_imgs', filesep, sec_name,'.png']);
            else
                OVVIMG = imresize(imread([res_batch_dir, filesep, 'overview_imgs', filesep, sec_name,'.png']),scl,'nearest');
            end
            if size(OVVIMG,3) > 1  % RGB -> grayscale
                OVVIMG = mean(OVVIMG,3);
            end
            xrange(3,:) = [0, size(OVVIMG,2)];
            yrange(3,:) = [0, size(OVVIMG,1)];
        catch
            IMQA_options(3) = false;
            set(handles.checkbox_fsp,'Enable','off');
            warndlg('Fail to load the overview image','Warning');
        end
    end
    
    axis_lim = [min(xrange(:,1)),max(xrange(:,2)),min(yrange(:,1)),max(yrange(:,2))];
    fig_sznorm = [range(xrange(:))/screenSize(3), 1.15*range(yrange(:))/screenSize(4)];
    if any(isnan(axis_lim)) || (axis_lim(2)-axis_lim(1)<=0) || (axis_lim(4)-axis_lim(3)<=0)
        fig_size = target_fig_size;
        axis_lim = [0,1,0,1];
    else
        fig_ratio = target_fig_size./fig_sznorm;
        fig_sznorm = fig_sznorm*min(fig_ratio);
        fig_size = max(fig_sznorm,0.5*target_fig_size);
    end
    fig_pos = [figcntr(1)-0.5*fig_size(1), figcntr(2)-0.5*fig_size(2),fig_size(1),fig_size(2)];

    % initializing figure
    hfig = figure(985);
    % clf(hfig,'reset');
    clf(hfig);
    hfig.NumberTitle = 'off';
    hfig.Name = 'image quality';
    hfig.ToolBar = 'none';
    hfig.Units = 'normalized';
    hfig.Position = fig_pos;
    hfig.Color = 'white';
    hfig.Pointer = 'hand';

    % haxe1: title and overview images
    haxe1 = axes(hfig,'Units','normalized','Position',[0,0.05,1,0.87],'YDir','reverse','Visible','on',...
        'DataAspectRatio',[1,1,1],'PickableParts','none','XColor','w','YColor','w'); % 'ActivePositionProperty','Position'
    hold(haxe1,'on');
    colormap(haxe1,'gray');
    axis(haxe1,axis_lim);
    title(haxe1,{strrep(strrep(ovv_info.sectionDirN,'\','\\'),'_','\_'),''},'FontSize',9);
    if IMQA_options(3)
        crnt_selected = get(handles.checkbox_overview,'Value');
        if crnt_selected
            optstr = 'on';
            showOVV = true;
        else
            optstr = 'off';
            mapAlpha = 0.75;
        end
        hIMQA{3} = imagesc(haxe1,OVVIMG,'PickableParts','none','Visible',optstr);
    end

    % haxe2: IMQA map, threshold used
    haxe2 = axes(hfig,'Units','normalized','Position',[0,0.05,1,0.87],'YDir','reverse','Visible','off',...
        'DataAspectRatio',[1,1,1],'PickableParts','all','HitTest','on','BusyAction','cancel'); % 'ActivePositionProperty','Position'
    hold(haxe2,'on');
    colormap(haxe2,handles.IMQAcm);
    axis(haxe2,axis_lim);
    thre2 = handles.IMQAthresh2;  % smaller threshold
    thre1 = handles.IMQAthresh;
    caxis(haxe2,[thre2, thre1])
    hIMQA{5} = haxe2;
    if IMQA_options(4)
        if IMQA_options(3)
            D = nan(size(OVVIMG),'single');
        else
            D = nan(ceil(range(tyrange)),ceil(range(txrange)),'single');
        end
        indx1 = sub2ind(size(D),floor(ovv_info.ovv_coord_y(:)),floor(ovv_info.ovv_coord_x(:)));
        indx2 = sub2ind(size(D),ceil(ovv_info.ovv_coord_y(:)),ceil(ovv_info.ovv_coord_x(:)));
        D(indx1) = ovv_info.IMQA(:);
        D(indx2) = ovv_info.IMQA(:);
        mask0 = ~isnan(D);
        [~,idx] = bwdist(mask0);
        D = D(idx);
        if IMQA_options(3)
            mask = OVVIMG<255;
        else
            mask = imdilate(mask0,ones(dssz));
        end
        D(~mask) = nan;
        crnt_selected = get(handles.checkbox_sfov,'Value');
        if crnt_selected
            optstr = 'on';
        else
            optstr = 'off';
        end
        hIMQA{4} = imagesc(haxe2, D,'AlphaData',mapAlpha*mask,'PickableParts','none','Visible',optstr);
        str = ['Thresholds: ',num2str(thre2),' ~ ',num2str(thre1)];
        hIMQA{6} = text(haxe2,axis_lim(2),axis_lim(4),[str, '  '],'PickableParts','none','HorizontalAlignment','right',...
            'VerticalAlignment', 'top', 'FontSize',fontsz*1.1,'Visible',optstr);
        
        impixelinfoval(hfig,hIMQA{4});
    end

    %%%%% clickable call back
    if ovv_info.ovv_coord_ready
        set(haxe2,'ButtonDownFcn',{@IMQA_open_original_images,ovv_info});
    end

    % haxe3: comment, FSP, mFoV#,
    haxe3 = axes(hfig,'Units','normalized','Position',[0,0.05,1,0.87],'YDir','reverse','Visible','off',...
        'DataAspectRatio',[1,1,1],'PickableParts','none'); % 'ActivePositionProperty','Position'
    hold(haxe3,'on');
    axis(haxe3,axis_lim);
    try
        txtname = [res_sec_dir, filesep, 'user_comment.txt'];
        if exist(txtname, 'file')
            fid = fopen(txtname,'r');
            str =  fgetl(fid);
            fclose(fid);
            if ~isempty(str)
                text(haxe3,0,0, ['  ', str], 'FontSize',fontsz*1.1,'Color','k','HorizontalAlignment','left','VerticalAlignment','bottom');
            end    
        end
    catch
        try fclose(fid); catch; end
    end
    
    if IMQA_options(2)
        crnt_selected = get(handles.checkbox_fsp,'Value');
        if crnt_selected
            optstr = 'on';
        else
            optstr = 'off';
        end
        hfsp = cell(3,1);
        fcs = (~ovv_info.focusMapData.AS) & (~ovv_info.focusMapData.AF);
        hfsp{1} = plot(haxe3,FSP_coord(:,1),FSP_coord(:,2),'+','Markersize',3*fontsz,...
            'PickableParts','none','Visible',optstr,'Color',[0,0,1],'LineWidth',1);
        hfsp{2} = plot(haxe3,FSP_coord(fcs,1),FSP_coord(fcs,2),'o','Markersize',3*fontsz,...
            'PickableParts','none','Visible',optstr,'Color',[0,0,1],'LineWidth',1);
        hfsp{3} = text(haxe3, double(FSP_coord(:,1)),double(FSP_coord(:,2)),strcat({' '},strtrim(cellstr(num2str((0:(length(fcs)-1))')))),...
            'FontSize',fontsz*0.9,'Color',[0,0,1],'HorizontalAlignment','left','VerticalAlignment','top',...
            'PickableParts','none','Visible',optstr);
        hIMQA{2} = hfsp;
    end

    if IMQA_options(1)
        crnt_selected = get(handles.checkbox_mfov,'Value');
        if crnt_selected
            optstr = 'on';
        else
            optstr = 'off';
        end
        if showOVV
            mfovclr = 'y';
        else
            mfovclr = 'k';
        end
        mfovid_str = strtrim(cellstr(num2str((1:size(ovv_mfov_x,1))','%.0f')));
        hIMQA{1} = text(haxe3,double(ovv_mfov_x),double(ovv_mfov_y),mfovid_str,...
            'Color',mfovclr,'BackgroundColor','none','HorizontalAlignment','center',...
            'FontSize',fontsz,'Margin',1,'FontName','Arial','FontWeight','bold',...
            'PickableParts','none','Visible',optstr);
    end

    %% Beam quality
    if ovv_info.IMQA_coord_ready
        hfig2 = figure(211);
        clf(hfig2,'reset');
        hfig2.NumberTitle = 'off';
        hfig2.Name = 'beam quality';
        hfig2.ToolBar = 'none';
        hfig2.MenuBar = 'none';
        hfig2.Color = 'white';

        hfig2.Units = 'normalized';
        hfig2.OuterPosition = [0.35 0.07 0.6 0.17];
        try
        haxeBeam = axes(hfig2);
        hold(haxeBeam,'off');
        set(haxeBeam,'LooseInset',[0.1,0.1,0.1,0.1]);
        IMQAt = ovv_info.IMQA;
        IMQAtm = repmat(median(IMQAt,1,'omitnan'),size(IMQAt,1),1);
        IMQAoutlier = isoutlier(IMQAt)|(IMQAt<IMQAtm);
        % IMQAoutlier = IMQAt<IMQAtm;
        IMQAt(IMQAoutlier) = nan;
        set(haxeBeam,'xTick',1:61);
        set(haxeBeam,'Position',[0.05, 0.11, 0.9, 0.8150]);
        set(haxeBeam,'FontSize',7);
        set(haxeBeam,'TickLength',[0.0025,0.025]);
        
        hold(haxeBeam,'on');
        boxplot(haxeBeam,IMQAt,'symbol','r.')
        catch
        end
    end
end

%% sub functions
function [output_coord, sflag] = local_stage2ICS_transform(stage_coord, ICS_coord, input_coord, scl)
    if nargin < 4
        scl = 1/16;
    end
    dis_thresh = 90*0.5; % By default the distance between mFoV ~ 90um (3% overlap)
    sflag = false;
    output_coord = nan(size(input_coord));
    try
        idx = all(~isnan(ICS_coord) & ~isnan(ICS_coord),2);
        stage_coord = stage_coord(idx,:);
        ICS_coord = ICS_coord(idx,:);
        if isempty(ICS_coord)
            return
        end
        ICSm = mean(ICS_coord,1);
        stagem = mean(stage_coord,1);
        ICS_coord = ICS_coord - repmat(ICSm,size(ICS_coord,1),1);
        stage_coord = stage_coord - repmat(stagem,size(stage_coord,1),1);
        input_coord = input_coord - repmat(stagem,size(input_coord,1),1);
        d_stgcoord = abs(diff(stage_coord,1,1));

        % prevent singularity
        if isempty(d_stgcoord)
            rk = 0;
        elseif max(d_stgcoord(:)) == 0
            rk = 0;
        elseif sum(range(d_stgcoord,1).^2)^0.5 < dis_thresh
            rk = 1;
        else
            rk = 2;
        end
        switch rk
        case 2
            A = [stage_coord, ones(size(stage_coord,1),1)]\[ICS_coord, ones(size(ICS_coord,1),1)];
            output_coord = input_coord*A(1:2,1:2) + repmat(A(3,1:2),size(input_coord,1),1);
        case 1     % if mfov along one line, assume similarity (no shear)
            S0 = svd(stage_coord);
            At = pinv(stage_coord, mean(S0))*ICS_coord;
            [U,S,V] = svd(At);
            if det(U)*det(V') > 0
                S(end) = -S(1); % usually the coordinates are mirrored
            else
                S(end) = S(1);
            end
            A = U*S*V';
            output_coord = input_coord*A;
        otherwise  % if only one mfov, use default scale
            output_coord = input_coord*1000*scl/64;
            output_coord(:,1) = -output_coord(:,1); % usually the coordinates are mirrored
        end
        output_coord = output_coord + repmat(ICSm,size(output_coord,1),1);
        sflag = true;
    catch
        disp('Failed to convert stage to ICS...');
        sflag = false;
        output_coord = nan(size(input_coord));
    end
end