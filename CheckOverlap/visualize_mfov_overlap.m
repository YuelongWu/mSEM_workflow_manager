function visualize_mfov_overlap(add_info,section_dir,missing_img,hfig)
    h = axes(hfig);
    hold(h,'on');
    corner_pts = add_info.cornerpts_info.corner_pts;
    gap_pairs = add_info.gapsMfovPairs;
    lowconf_pairs = add_info.lowConfMfovPairs;
    corner_x = corner_pts(:,1);
    corner_y = corner_pts(:,2);
    mfov_x = add_info.mfov_stitched_x(:);
    mfov_y = add_info.mfov_stitched_y(:);
    mfov_num = length(mfov_x(:));
    mfovid_str = strtrim(cellstr(num2str((1:mfov_num)')));
    lgdtxt = {};
    if ~isempty(gap_pairs)
        plot(h,mean(reshape(mfov_x(gap_pairs),size(gap_pairs)),2),mean(reshape(mfov_y(gap_pairs),size(gap_pairs)),2),'r*','markersize',7,'LineWidth',1);
        lgdtxt = [lgdtxt;{['\color{red}',char(8277),' \color{black}overlap gaps']}];
    end
    if ~isempty(lowconf_pairs)
        plot(h,mean(reshape(mfov_x(lowconf_pairs),size(lowconf_pairs)),2),mean(reshape(mfov_y(lowconf_pairs),size(lowconf_pairs)),2),'mo','markersize',4,'LineWidth',1);
        lgdtxt = [lgdtxt;{'\color{magenta}o \color{black}overlap low-conf'}];
    end
    if any(missing_img)
        lgdtxt = [lgdtxt;{['\color{blue}\bf','#',' \color{black}\rmmissing images']}];
    end
%     px = corner_x + mfov_x';
%     py = corner_y + mfov_y';
%     patch(h, 'Faces', reshape((1:length(px(:)))',size(px))',...
%         'Vertices',[px(:),py(:)],'FaceAlpha',0.25,'EdgeColor','none','FaceColor','flat',...
%         'FaceVertexCData',0.1*rand(mfov_num,3)+0.5*ones(mfov_num,3));
    for k = 1:mfov_num
        fill(h, corner_x + mfov_x(k),corner_y+mfov_y(k),'k','FaceAlpha',0.25,'EdgeAlpha',0);
        if missing_img(k)
            text(h,double(mfov_x(k)),double(mfov_y(k)),...
            mfovid_str{k},'HorizontalAlignment','center',...
            'FontSize',9, 'color','b','FontWeight','bold');
        else
            text(h,double(mfov_x(k)),double(mfov_y(k)),...
                mfovid_str{k},'HorizontalAlignment','center',...
                'FontSize',8, 'color',[0.5,0.5,0.5]);
        end
    end
%     if sum(missing_img(:))
%         text(h,double(mfov_x(~missing_img)),double(mfov_y(~missing_img)),...
%             mfovid_str(~missing_img),'HorizontalAlignment','center',...
%             'FontSize',8, 'color',[0.3,0.3,0.3]);
%         text(h,double(mfov_x(missing_img)),double(mfov_y(missing_img)),...
%             mfovid_str(missing_img),'HorizontalAlignment','center',...
%             'FontSize',8, 'color','b','FontWeight','bold');
%     else
%         text(h,double(mfov_x),double(mfov_y),mfovid_str,...
%             'HorizontalAlignment','center','FontSize',8, 'color',[0.5,0.5,0.5]);
%     end
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


