function visualize_stage_jitter(add_info,section_dir,hfig)
    h = axes(hfig);
    hold(h,'on');
    corner_pts = add_info.cornerpts_info.corner_pts;
    corner_x = corner_pts(:,1);
    corner_y = corner_pts(:,2);
    jitter_amp = max(0,add_info.stage_jitter_amp);
    [jitter_amp,idx] = sort(jitter_amp);
    mfov_x = add_info.mfov_stitched_x(idx);
    mfov_y = add_info.mfov_stitched_y(idx);
    % mfov_num = length(mfov_x(idx));
    lgdtxt = {};
    jitter_idx = jitter_amp(:) > 0;
    if any(jitter_idx)
        lgdtxt = [lgdtxt;{['\color{magenta}',char(9632),' \color{black}stage jitter']}];
    end
    % scanfault_idx = add_info.mfov_scanfault(:) > 0;
    % color range [0.1(thresh):0.25 ->0.2: 1]
    jitter_amp(jitter_idx) = min(1,jitter_amp(jitter_idx)/0.1)*0.75+0.25;
    jitter_amp(isnan(jitter_amp)) = 0;
    jitter_amp = jitter_amp(:);
    mfovid_str = strtrim(cellstr(num2str(idx(:))));
    px = corner_x + mfov_x(~jitter_idx)';
    py = corner_y + mfov_y(~jitter_idx)';
    patch(h, 'Faces', reshape((1:length(px(:)))',size(px))',...
         'Vertices',[px(:),py(:)],'FaceAlpha',1,'EdgeColor','none','FaceColor',[0.9,0.9,0.9]);
    text(h,double(mfov_x(~jitter_idx)),double(mfov_y(~jitter_idx)),mfovid_str(~jitter_idx),...
         'HorizontalAlignment','center','FontSize',8, 'color',[0.6,0.6,0.6]);
    px = corner_x + mfov_x(jitter_idx)';
    py = corner_y + mfov_y(jitter_idx)';
    patch(h, 'Faces', reshape((1:length(px(:)))',size(px))',...
         'Vertices',[px(:),py(:)],'FaceAlpha',1,'EdgeColor','none','FaceColor','flat',...
         'FaceVertexCData',[0.9*ones(sum(jitter_idx(:)),1),0.9-0.9*jitter_amp(jitter_idx(:)),0.9*ones(sum(jitter_idx(:)),1)]);
    text(h,double(mfov_x(jitter_idx)),double(mfov_y(jitter_idx)),mfovid_str(jitter_idx),...
         'HorizontalAlignment','center','FontSize',8, 'color',[0.6,0,0.6]);
    % if any(scanfault_idx)
    %   text(h,double(mfov_x(scanfault_idx)),double(mfov_y(scanfault_idx)),mfovid_str(scanfault_idx),...
    %       'HorizontalAlignment','center','FontSize',9, 'color','r','FontWeight','bold');
    %   lgdtxt = [lgdtxt;{['\color{red}\bf','#',' \color{black}\rmscan-fault']}];
    % end
    set(h,'YDir','reverse');
    axis(h,'equal');
    axis(h,'off');
    title(h,strrep(strrep(section_dir,'\','\\'),'_','\_'),'FontSize',10);
    if ~isempty(lgdtxt)
        xx = get(h,'XLim');
        yy = get(h,'YLim');
        xx = double(min(xx)); yy = double(min(yy));
        text(h,xx,yy,lgdtxt,'HorizontalAlignment','left','VerticalAlignment','cap','FontSize',9);
    end
end
