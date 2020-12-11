function utils_print_all_IMQA_maps(result_section_dirs, IMQA_thresh)
    ovwt = false;
    fontsz = 7;
    filelen = length(result_section_dirs);
    hmfov = figure(985);
    hbeam = figure(211);
    hprtmfov = copyobj(hmfov,hmfov.Parent);
    hprtbeam = copyobj(hbeam,hbeam.Parent);
    clf(hprtmfov,'reset')
    clf(hprtbeam,'reset')
    % clf(hprtmfov)
    % clf(hprbeam)
    hprtmfov.Visible = 'off';
    hprtbeam.Visible = 'off';
    hprtmfov.Units = 'points';
    Pos = hprtmfov.Position;
    hprtmfov.Units = 'normalized';
    hprtmfov.PaperUnits = 'points';
    hprtmfov.PaperSize = [Pos(3),Pos(4)];
    hprtmfov.PaperPosition = [0, 0, Pos(3),Pos(4)];
    hprtbeam.Units = 'points';
    Pos = hprtbeam.Position;
    hprtbeam.Units = 'normalized';
    hprtbeam.PaperUnits = 'points';
    hprtbeam.PaperSize = [Pos(3),Pos(4)];
    hprtbeam.PaperPosition = [0, 0, Pos(3),Pos(4)];
    
    haxem = axes(hprtmfov,'XColor','w','YColor','w');
    haxeb = axes(hprtbeam,'XColor','w','YColor','w');
    
    hw = waitbar(0,'printing quality maps');
    for k = 1:filelen
        cla(haxem,'reset')
        cla(haxeb,'reset')
        hprtbeam.ToolBar = 'none';
        hprtbeam.MenuBar = 'none';
        hprtmfov.Visible = 'off'; hprtbeam.Visible = 'off';
        
        try
            res_sec_dir = result_section_dirs{k};
            load([res_sec_dir,filesep,'summary.mat'],'report_info');
            title(haxem, strrep(strrep(report_info.sectionDir,'\','\\'),'_','\_')); 
            hold(haxem,'on');
            mfov_id = report_info.mfovId;
            IMQA_val = nanmean(report_info.IMQA,2);
            if report_info.doIMQAPlot
%                 [~, secname] = fileparts(res_sec_dir);
                outputm = [res_sec_dir, filesep, 'mFovQuality'];
                outputb = [res_sec_dir, filesep, 'beamQuality'];
                if (~exist([outputm,'.pdf'],'file')) || ovwt
                    fcx = report_info.focusMapData.xyCoordinates(:,1);
                    fcy = report_info.focusMapData.xyCoordinates(:,2);
                    fcs = (~report_info.focusMapData.AF)&(~report_info.focusMapData.AS);
                    plot(haxem,fcx,fcy,'b+','Markersize',4*fontsz);
                    plot(haxem,fcx(fcs),fcy(fcs),'bo','Markersize',4*fontsz);


                    xx = report_info.xyCoordinates(:,1);
                    yy = report_info.xyCoordinates(:,2);
                    mfovid_str = strcat('#', strtrim(cellstr(num2str(mfov_id,'%.0f'))),':');
                    IMQA_str = strtrim(cellstr(num2str(IMQA_val,'%.0f')));
                    hIMQA = text(haxem,xx,yy,IMQA_str,'HorizontalAlignment','left','FontSize',fontsz);
                    hMfovID = text(haxem,xx,yy,mfovid_str,'HorizontalAlignment','right','FontSize',fontsz);
                    hprtmfov.Visible = 'off';
                    utils_update_text_color(hMfovID, hIMQA, IMQA_val, IMQA_thresh)
                    hprtmfov.Visible = 'off';

                    xxmin = min(min(xx),min(fcx))-50;
                    xxmax = max(max(xx),max(fcx))+50;
                    yymin = min(min(yy),min(fcy))-50;
                    yymax = max(max(yy),max(fcy))+50;

                    axis(haxem,'equal');
                    axis(haxem,'off');
                    try xlim(haxem,[xxmin,xxmax]); ylim(haxem,[yymin,yymax]);catch;end
                    set(haxem,'Position',[0.05, 0.05, 0.9, 0.87]);
                    set(haxem,'xdir','reverse');
                    set(haxem,'ydir','reverse');
                    print(hprtmfov, outputm,'-painters','-dpdf');
                end

                if (~exist([outputb,'.pdf'],'file')) || ovwt
                    hold(haxeb,'off')
                    set(haxeb,'LooseInset',[0.1,0.1,0.1,0.1]);
                    IMQAt = report_info.IMQA;
                    IMQAoutlier = isoutlier(IMQAt);
                    IMQAt(IMQAoutlier) = nan;
                    boxplot(haxeb,IMQAt,'symbol','r.')
                    set(haxeb,'xTick',1:61);
                    set(haxeb,'Position',[0.05, 0.11, 0.9, 0.8150]);
                    set(haxeb,'FontSize',7);
                    hprtbeam.Visible = 'off';
                    print(hprtbeam, outputb,'-painters','-dpdf');
                end
            end
        catch ME
            %if ~strcmpi(ME.identifier,'MATLAB:InsetDataType:InvalidInsetException')
                disp('Error happened when printing quality maps:');
                disp(ME.message);
            %end
        end
        try
            waitbar(k/filelen, hw);
        catch
            hw = waitbar(k/filelen,'printing quality maps');
        end
    end
    try
        close(hw);
        close(hprtbeam);
        close(hprtmfov);
    catch
    end
end