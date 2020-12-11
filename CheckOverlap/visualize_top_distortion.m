function visualize_top_distortion(add_info,section_dir,hfig)
    h = axes(hfig);
    hold(h,'on');
    corner_pts = add_info.cornerpts_info.corner_pts;
    corner_x = corner_pts(:,1);
    corner_y = corner_pts(:,2);
    % mfov_ht = range(corner_y);
    top_distortion_amp = max(0,add_info.top_distortion_amp(:));
    [top_distortion_amp,idx] = sort(top_distortion_amp);
    mfov_x = add_info.mfov_stitched_x(idx);
    mfov_y = add_info.mfov_stitched_y(idx);
    % mfov_num = length(mfov_x(:));
    mfovid_str = strtrim(cellstr(num2str(idx(:))));
    distort_idx = top_distortion_amp(:) > 0;
    mfov_scanfault = add_info.mfov_scanfault(:);
    scanfault_idx = mfov_scanfault(idx)>0;
    lgdtxt = {};
    if any(distort_idx)
        lgdtxt = [lgdtxt;{['\color{blue}',char(9632),' \color{black}top distortion']}];
    end
    px = corner_x + mfov_x(~distort_idx)';
    py = corner_y + mfov_y(~distort_idx)';
    patch(h, 'Faces', reshape((1:length(px(:)))',size(px))',...
         'Vertices',[px(:),py(:)],'FaceAlpha',1,'EdgeColor','none','FaceColor',[0.9,0.9,0.9]);
    text(h,double(mfov_x((~distort_idx)&(~scanfault_idx))),double(mfov_y((~distort_idx)&(~scanfault_idx))),mfovid_str((~distort_idx)&(~scanfault_idx)),...
            'HorizontalAlignment','center','FontSize',8, 'color',[0.5,0.5,0.5]);
    
    px = corner_x + mfov_x(distort_idx)';
    py = corner_y + mfov_y(distort_idx)';
    
    % ---------- gradient within one mFoV (slow & large file) ------------------------------%
    % top_distortion_length = add_info.top_distortion_length(:);
    % mfov_ht = range(corner_y);
    % yratio = (min(corner_y) - corner_y)/mfov_ht;
    % cdata = exp(yratio(:)./max(0.01,(top_distortion_length(distort_idx))'));
    % cdata = cdata.*(top_distortion_amp(distort_idx))';
    % cdata = min(1,cdata/10);
    % patch(h, 'Faces', reshape((1:length(px(:)))',size(px))',...
    % 'Vertices',[px(:),py(:)],'FaceAlpha',0.7,'EdgeColor','none','FaceColor','interp',...
    %   'FaceVertexCData',[0.9*ones(size(cdata(:))),0.9-cdata(:).*0.9,0.9*ones(size(cdata(:)))]);

    cdata = top_distortion_amp(distort_idx);
    cdata = min(1,cdata/10)*0.9+0.1;
    patch(h, 'Faces', reshape((1:length(px(:)))',size(px))',...
         'Vertices',[px(:),py(:)],'FaceAlpha',1,'EdgeColor','none','FaceColor','flat',...
         'FaceVertexCData',[0.9-cdata(:).*0.9,0.9-cdata(:).*0.9,0.9*ones(size(cdata(:)))]);
    text(h,double(mfov_x(distort_idx &(~scanfault_idx))),double(mfov_y(distort_idx&(~scanfault_idx))),mfovid_str(distort_idx&(~scanfault_idx)),...
         'HorizontalAlignment','center','FontSize',8, 'color',[0,0,0]);
    if any(scanfault_idx)
        text(h,double(mfov_x(scanfault_idx)),double(mfov_y(scanfault_idx)),mfovid_str(scanfault_idx),...
            'HorizontalAlignment','center','FontSize',9, 'color','r','FontWeight','bold');
        lgdtxt = [lgdtxt;{['\color{red}\bf','#',' \color{black}\rmscan-fault']}];
    end
    set(h,'YDir','reverse');
    axis(h,'equal');
    axis(h,'off');
    title(h,strrep(strrep(section_dir,'\','\\'),'_','\_'),'FontSize',10);

    xx = get(h,'XLim');
    yy = get(h,'YLim');
    xx = double(min(xx)); yy = double(min(yy));
    text(h,xx,yy,lgdtxt,'HorizontalAlignment','left','VerticalAlignment','cap','FontSize',9);
end
