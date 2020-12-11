function utils_init_quality_map_print(IMQA_options0, res_sec_dirs, params)
    scl = 0.3;  % scale factor for the entire figure. scl = 1: same size as the overview
    fontsz = 8;
    override = false;  % if override already printed quality map
    
    if isempty(res_sec_dirs) || all(~IMQA_options0)
        return
    end
    hprntovv = figure('IntegerHandle','off','Visible','off','Units','pixels','Color','white');
    hprntovv.PaperUnits = 'points';
    hprntovv.PaperPositionMode = 'manual';
    hprntovv.InvertHardcopy = 'off';
    
    hprntbeam = figure('IntegerHandle','off','Visible','off','Units','normalized','Color','white');
    hprntbeam.OuterPosition = [0.35 0.07 0.6 0.17];
    haxeBeam = axes(hprntbeam,'Units', 'normalized');
    set(haxeBeam,'LooseInset',[0.1,0.1,0.1,0.1]);
    set(haxeBeam,'xTick',1:61);
    set(haxeBeam,'Position',[0.05, 0.11, 0.9, 0.8150]);
    set(haxeBeam,'FontSize',7);
    set(haxeBeam,'TickLength',[0.0025,0.025]);
    hold(haxeBeam,'on');
    hprntbeam.Units ='points';
    hprntbeam.PaperUnits = 'points';
    Pos = get(hprntbeam,'Position');
    hprntbeam.PaperSize = [Pos(3),Pos(4)];
    hprntbeam.PaperPosition = [0, 0, Pos(3),Pos(4)];
    
    if ~iscell(res_sec_dirs)
        res_sec_dirs = {res_sec_dirs};
    end
    N = length(res_sec_dirs);

    hw = waitbar(0,'printing quality maps');
    for k = 1:N
        try
            res_sec_dir = res_sec_dirs{k};
            if isempty(res_sec_dir)
                continue
            end
            
            [ovv_info, IMQA_options] = utils_constrain_IMQA_options(res_sec_dir);
            if isempty(ovv_info) || all(~IMQA_options)
                % disp(['Maps not printed: ', res_sec_dir])
                continue
            end
            ovv_info.overview_scl = ovv_info.overview_scl*scl;
            ovv_info.ovv_coord_x = ovv_info.ovv_coord_x*scl;
            ovv_info.ovv_coord_y = ovv_info.ovv_coord_y*scl;
            IMQA_options = IMQA_options & IMQA_options0;
            [res_batch_dir, secname] = fileparts(res_sec_dir);
            try
               tmpcell = split(secname, '_');
               secname = tmpcell{end};
            catch
            end
            outputmbatch = [res_batch_dir,filesep,'image_qualities'];
            outputbbatch = [res_batch_dir,filesep,'beam_qualities'];
            outputm = [outputmbatch, filesep, secname,'_imageQuality'];
            outputb = [outputbbatch, filesep, secname,'_beamQuality'];

            if override || ~exist([outputb, '.pdf'],'file')
                try
                    cla(haxeBeam)
                    IMQAt = ovv_info.IMQA;
                    IMQAtm = repmat(median(IMQAt,1,'omitnan'),size(IMQAt,1),1);
                    IMQAoutlier = isoutlier(IMQAt)|(IMQAt<IMQAtm);
                    % IMQAoutlier = IMQAt<IMQAtm;
                    IMQAt(IMQAoutlier) = nan;
                    boxplot(haxeBeam,IMQAt,'symbol','r.');
                    if ~exist(outputbbatch,'dir')
                        mkdir(outputbbatch);
                    end
                        
                    print(hprntbeam, outputb,'-painters','-dpdf');
                catch ME
                    disp(['Beam quality not printed: ', res_sec_dir]);
                    disp(ME.message)
                end
            end


            if override || ~exist([outputm,'.jpg'],'file')
                clf(hprntovv);
                % decide figure size
                xrange = nan(3,2);
                yrange = nan(3,2);
                
%                 ovv_info.ovv_coord_x = ovv_info.ovv_coord_x*scl;
%                 ovv_info.ovv_coord_y = ovv_info.ovv_coord_y*scl;
%                 ovv_info.thumbsize = ovv_info.thumbsize*scl;
                
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
                            IMQA_options(4) = false;
                        end
                    catch
                        IMQA_options(1) = false;
                        IMQA_options(4) = false;
                    end
                end
                if IMQA_options(2) % plot FSP
                    stage_coord = ovv_info.stageCoord;
                    ICS_coord = [ovv_mfov_x(:), ovv_mfov_y(:)];
                    FSP_stgcoord = ovv_info.focusMapData.xyCoordinates;
                    [FSP_coord, sflag] =  local_stage2ICS_transform(stage_coord, ICS_coord, FSP_stgcoord, ovv_info.overview_scl);
                    if ~sflag
                        IMQA_options(2) = false;
                    end
                    xrange(2,:) = [min(FSP_coord(:,1))-50,max(FSP_coord(:,1))+50];
                    yrange(2,:) = [min(FSP_coord(:,2))-50,max(FSP_coord(:,2))+50];
                end
                if IMQA_options(3) % show overview image
                    try
                        [res_batch_dir, sec_name] = fileparts(res_sec_dir);
                      
                        OVVIMG = imread([res_batch_dir, filesep, 'overview_imgs', filesep, sec_name,'.png']);
                        if scl ~= 1
                            OVVIMG = imresize(OVVIMG,scl,'nearest');
                        end
                        if size(OVVIMG,3) > 1  % RGB -> grayscale
                            OVVIMG = mean(OVVIMG,3);
                        end
                        xrange(3,:) = [0, size(OVVIMG,2)];
                        yrange(3,:) = [0, size(OVVIMG,1)];
                    catch
                        IMQA_options(3) = false;
                    end
                end
                axis_lim = [min(xrange(:,1)),max(xrange(:,2)),min(yrange(:,1)),max(yrange(:,2))];
                x_limrg = axis_lim(2) - axis_lim(1);
                y_limrg = axis_lim(4) - axis_lim(3);
                if any(isnan(axis_lim)) || all(~IMQA_options) || x_limrg<=0 || y_limrg<=0
                    disp(['Maps not printed: ', res_sec_dir]);
                    continue
                end
                set(hprntovv,'Units','pixels');
                % Leave room for title, user comment, threshold values
                set(hprntovv,'Position',[0,0,x_limrg, y_limrg + 9*fontsz]);
                
                % haxe1: title and overview images
                if IMQA_options(3)
                    haxe1 = axes(hprntovv,'Units','pixels','YDir','reverse','Visible','on','XColor','w','YColor','w');
                    hold(haxe1,'on');
                    set(haxe1,'Position',[0, fontsz*3, x_limrg, y_limrg]);
                    colormap(haxe1,'gray');
                    axis(haxe1,axis_lim);
                    title(haxe1,{strrep(strrep(ovv_info.sectionDirN,'\','\\'),'_','\_'),''},'FontUnits','pixels','FontSize',fontsz*1.1);
                    imagesc(haxe1,OVVIMG);
                end

                % haxe2: IMQA map, threshold used
                if IMQA_options(4)
                    haxe2 = axes(hprntovv,'Units','pixels','YDir','reverse','Visible','off','XColor','w','YColor','w');
                    set(haxe2,'Position',[0, fontsz*3, x_limrg, y_limrg]);
                    hold(haxe2,'on');
                    colormap(haxe2,params.IMQAcm);
                    axis(haxe2,axis_lim);
                    thre2 = params.IMQAthresh2;  % smaller threshold
                    thre1 = params.IMQAthresh;
                    caxis(haxe2,[thre2, thre1])
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
                        mapAlpha = 0.35;
                    else
                        mask = imdilate(mask0,ones(dssz));
                        mapAlpha = 1;
                        set(haxe2,'Visible','on');
                        title(haxe2,{strrep(strrep(ovv_info.sectionDirN,'\','\\'),'_','\_'),''},'FontUnits','pixels','FontSize',fontsz*1.1);
                    end
                    D(~mask) = nan;
                    imagesc(haxe2, D,'AlphaData',mapAlpha*mask);
                    str = ['Thresholds: ',num2str(thre2),' ~ ',num2str(thre1)];
                    text(haxe2,axis_lim(2),axis_lim(4),[str, '  '],'FontUnits','pixels','HorizontalAlignment','right',...
                        'VerticalAlignment', 'cap', 'FontSize',fontsz*1.1);
                end

                % haxe3: comment, FSP, mFoV#
                haxe3 = axes(hprntovv,'Units','pixels','YDir','reverse','Visible','off','XColor','w','YColor','w'); 
                set(haxe3,'Position',[0, fontsz*3, x_limrg, y_limrg]);
                hold(haxe3,'on');
                axis(haxe3,axis_lim);
                try
                    txtname = [res_sec_dir, filesep, 'user_comment.txt'];
                    if exist(txtname, 'file')
                        fid = fopen(txtname,'r');
                        str =  fgetl(fid);
                        fclose(fid);
                        if ~isempty(str)
                            text(haxe3,0,0, ['  ', str],'FontUnits','pixels', 'FontSize',fontsz*1.1,'Color','k',...
                                'HorizontalAlignment','left','VerticalAlignment','baseline');
                        end    
                    end
                catch
                    try fclose(fid); catch; end
                end
                
                if ~IMQA_options(3) && ~IMQA_options(4)
                    set(haxe3,'Visible','on');
                    title(haxe3,{strrep(strrep(ovv_info.sectionDirN,'\','\\'),'_','\_'),''},'FontUnits','pixels','FontSize',fontsz*1.1);
                end
                
                if IMQA_options(2)
                    fcs = (~ovv_info.focusMapData.AS) & (~ovv_info.focusMapData.AF);
%                     text(haxe3,double(FSP_coord(~fcs,1)),double(FSP_coord(~fcs,2)),'+','FontUnits','pixels','Fontsize',4*fontsz*scl,...
%                         'Color',[0.2,0.2,1],'HorizontalAlignment','center','VerticalAlignment','middle','FontName','Verdana');
%                     text(haxe3,double(FSP_coord(fcs,1)),double(FSP_coord(fcs,2)),char(10753),'FontUnits','pixels','Fontsize',4*fontsz*scl,...
%                         'Color',[0.2,0.2,1],'HorizontalAlignment','center','VerticalAlignment','middle','FontName','Verdana');
                    plot(haxe3,FSP_coord(:,1),FSP_coord(:,2),'+','Markersize',2.5*fontsz,...
                        'Color',[0.2,0.2,1],'LineWidth',1);
                    plot(haxe3,FSP_coord(fcs,1),FSP_coord(fcs,2),'o','Markersize',2.5*fontsz,...
                        'Color',[0.2,0.2,1],'LineWidth',1);
                    text(haxe3, double(FSP_coord(:,1)),double(FSP_coord(:,2)),strcat({' '},strtrim(cellstr(num2str((0:(length(fcs)-1))')))),...
                        'FontUnits','pixels','FontSize',fontsz*0.9,'Color',[0,0,0.5],'HorizontalAlignment','left','VerticalAlignment','top');
                end

                if IMQA_options(1)
                    if IMQA_options(3)
                        mfovclr = 'y';
                    else
                        mfovclr = 'k';
                    end
                    mfovid_str = strtrim(cellstr(num2str((1:size(ovv_mfov_x,1))','%.0f')));
                    text(haxe3,double(ovv_mfov_x),double(ovv_mfov_y),mfovid_str,...
                        'Color',mfovclr,'BackgroundColor','none','HorizontalAlignment','center',...
                        'FontUnits','pixels','FontSize',fontsz,'Margin',1,'FontName','Arial','FontWeight','bold');
                end
                set(hprntovv,'Units','points');
                Pos = get(hprntovv,'Position');
                hprntovv.PaperSize = [Pos(3),Pos(4)];
                hprntovv.PaperPosition = [0, 0, Pos(3),Pos(4)];
                if ~exist(outputmbatch,'dir')
                    mkdir(outputmbatch);
                end
                % print(hprntovv, outputm,'-painters','-dpdf');
                print(hprntovv, outputm,'-opengl','-djpeg');
            end
        catch ME
            disp(['Maps not printed:', res_sec_dir])
            disp(ME.message)
        end

        try
            waitbar(k/N, hw);
        catch
            hw = waitbar(k/N,'printing quality maps');
        end
    end
    try
        msgbox('Finished printing quality maps','Success','help');
        close(hprntbeam);
        close(hprntovv);
        close(hw);
    catch
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