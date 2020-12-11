function [hMfovID, hIMQA, IMQA_val] = utils_initialize_quality_map(res_sec_dir)
    fontsz = 7;
    hfig = figure(985);
    clf(hfig,'reset');
    hfig.NumberTitle = 'off';
    hfig.Name = 'mFoV quality';
    hfig.ToolBar = 'none';
    hfig.Units = 'normalized';
    hfig.OuterPosition = [0.03 0.24 0.92 0.75];
    hfig.Color = 'white';
    haxe = axes(hfig,'XColor','w','YColor','w');
    
    % set(hfig,'Position',[0.6258    0.5764    0.3211    0.3743])
    
    hfig2 = figure(211);
    clf(hfig2,'reset');
    hfig2.NumberTitle = 'off';
    hfig2.Name = 'beam quality';
    hfig2.ToolBar = 'none';
    hfig2.MenuBar = 'none';

    hfig2.Units = 'normalized';
    hfig2.OuterPosition = [0.35 0.07 0.6 0.17];
    haxe2 = axes(hfig2,'XColor','w','YColor','w');
    hold(haxe2,'off');
    
    try
        load([res_sec_dir,filesep,'summary.mat'],'report_info');
        title(haxe, strrep(strrep(report_info.sectionDir,'\','\\'),'_','\_')); 
        hold(haxe,'on');
        wrnmsg = {};
        if report_info.regionMetadataStatus == 1
            wrnmsg = [wrnmsg;{'region_metadata.csv corrupted.'}];
        elseif report_info.regionMetadataStatus == 2
            wrnmsg = [wrnmsg;{'region_metadata.csv missing.'}];
        elseif report_info.regionMetadataStatus == 99
            wrnmsg = [wrnmsg;{'unexpected error happened when parsing region_metadata.csv.'}];
        end
        
        if report_info.focusMapStatus == 1
            wrnmsg = [wrnmsg;{'FocusMap.txt corrupted.'}];
        elseif report_info.focusMapStatus == 2
            wrnmsg = [wrnmsg;{'FocusMap.txt missing.'}];
        elseif report_info.focusMapStatus == 99
            wrnmsg = [wrnmsg;{'unexpected error happened when parsing FocusMap.txt.'}];
        end
        if ~isempty(wrnmsg)
            warndlg(wrnmsg,'Warning')
        end
        mfov_id = report_info.mfovId;
        IMQA_val = nanmean(report_info.IMQA,2);
        hMfovID = [];
        hIMQA = [];
        if report_info.doIMQAPlot
            fcx = report_info.focusMapData.xyCoordinates(:,1);
            fcy = report_info.focusMapData.xyCoordinates(:,2);
            fcs = (~report_info.focusMapData.AF)&(~report_info.focusMapData.AS);
            h1 = plot(haxe,fcx,fcy,'b+','Markersize',4*fontsz);
            h2 = plot(haxe,fcx(fcs),fcy(fcs),'bo','Markersize',4*fontsz);
            h3 = text(haxe,double(fcx),double(fcy),strtrim(cellstr(num2str((0:(length(fcy)-1))'))),'FontSize',fontsz,'Color','k');
            
            xx = report_info.xyCoordinates(:,1);
            yy = report_info.xyCoordinates(:,2);
            mfovid_str = strcat('#', strtrim(cellstr(num2str(mfov_id,'%.0f'))),':');
            IMQA_str = strtrim(cellstr(num2str(IMQA_val,'%.0f')));
            hIMQA = text(haxe,xx,yy,IMQA_str,'HorizontalAlignment','left','FontSize',fontsz);
            hMfovID = text(haxe,xx,yy,mfovid_str,'HorizontalAlignment','right','FontSize',fontsz);
            
            set(hMfovID,'HitTest','off');
            set(hIMQA,'HitTest','off');
            set(h1,'HitTest','off');
            set(h2,'HitTest','off');
            set(h3,'HitTest','off');
            set(haxe,'HitTest','on');
            
            xxmin = min(min(xx),min(fcx))-50;
            xxmax = max(max(xx),max(fcx))+50;
            yymin = min(min(yy),min(fcy))-50;
            yymax = max(max(yy),max(fcy))+50;
            % axis(haxe,'off');
            set(haxe,'XColor','w');set(haxe,'YColor','w');
            axis(haxe,'equal');
            try xlim(haxe,[xxmin,xxmax]); ylim(haxe,[yymin,yymax]);catch;end
            set(haxe,'Position',[0.05, 0.05, 0.9, 0.87]);
            
            set(haxe,'xdir','reverse');
            set(haxe,'ydir','reverse');
            % set(haxe,'ButtonDownFcn',{@IMQA_open_mfov_folder,report_info.xyCoordinates, report_info.mfovId, report_info.sectionDir});
            set(haxe,'ButtonDownFcn',{@IMQA_open_mfov_images,report_info.xyCoordinates, report_info.mfovId, report_info.sectionDir, report_info.IMQA});
            
            set(haxe2,'LooseInset',[0.1,0.1,0.1,0.1]);
            IMQAt = report_info.IMQA;
            IMQAoutlier = isoutlier(IMQAt);
            IMQAt(IMQAoutlier) = nan;
            boxplot(haxe2,IMQAt,'symbol','r.')
            set(haxe2,'xTick',1:61);
            set(haxe2,'Position',[0.05, 0.11, 0.9, 0.8150]);
            set(haxe2,'FontSize',7);
        end
    catch ME
        errordlg(ME.message, 'Unexpected error')
        IMQA_val = nan;
        hMfovID = [];
        hIMQA = [];
    end
end