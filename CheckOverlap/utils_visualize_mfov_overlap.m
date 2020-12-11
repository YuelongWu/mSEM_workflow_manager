function utils_visualize_mfov_overlap(h, stitched_x, stitched_y, corner_pts,gap_pairs, lowconf_pairs,section_dir,img_noncomplete)
    if nargin < 8
        img_noncomplete = ones(size(stitched_x));
    end
    Nmfov = length(stitched_x);
    stitched_x = stitched_x(:)';
    stitched_y = stitched_y(:)';
%     fig_x = ceil((range(stitched_x)+1)/45);
%     fig_y = ceil((range(stitched_y)+1)/45);
    set(h.Parent,'Units','normalized');
    set(h.Parent,'OuterPosition',[0.03 0.24 0.8 0.75]);
    set(h.Parent,'Units','points');
    Pos = get(h.Parent,'Position');
    set(h.Parent,'PaperUnits','points');
    set(h.Parent,'PaperSize',[Pos(3),Pos(4)]);
    set(h.Parent,'PaperPosition',[0, 0, Pos(3),Pos(4)]);
    hold(h,'on')
    h_ms = [];
    h_jitter = [];
    h_gap = plot(h,mean(stitched_x(gap_pairs),2),mean(stitched_y(gap_pairs),2),'r*','markersize',7);
    h_lowconf = plot(h,mean(stitched_x(lowconf_pairs),2),mean(stitched_y(lowconf_pairs),2),'mo','markersize',4);
    for k = 1:Nmfov
        if img_noncomplete(k) == 0
            fill(h, corner_pts(:,1)+ stitched_x(k),corner_pts(:,2)+stitched_y(k),'g','FaceAlpha',0.4,'EdgeAlpha',0);
            text(h,double(stitched_x(k)),double(stitched_y(k)),num2str(k),'HorizontalAlignment','center','FontSize',8, 'color',[0,0.6,0]);
        elseif img_noncomplete(k) == 1
            h_ms = fill(h, corner_pts(:,1)+ stitched_x(k),corner_pts(:,2)+stitched_y(k),'r','FaceAlpha',0.4,'EdgeAlpha',0);
            text(h,double(stitched_x(k)),double(stitched_y(k)),num2str(k),'HorizontalAlignment','center','FontSize',8, 'color',[0.6,0,0]);
        elseif img_noncomplete(k) == 2
            h_jitter =fill(h, corner_pts(:,1)+ stitched_x(k),corner_pts(:,2)+stitched_y(k),'b','FaceAlpha',0.4,'EdgeAlpha',0);
            text(h,double(stitched_x(k)),double(stitched_y(k)),num2str(k),'HorizontalAlignment','center','FontSize',8, 'color',[0,0,0.6]);
        elseif img_noncomplete(k) == 3
            Ncn = size(corner_pts,1);
            Ncidx1 = 1:round((Ncn+1)/2);
            Ncidx2 = [round((Ncn+1)/2):Ncn,1];
            h_ms = fill(h, corner_pts(Ncidx1,1)+ stitched_x(k),corner_pts(Ncidx1,2)+stitched_y(k),'r','FaceAlpha',0.4,'EdgeAlpha',0);
            h_jitter =fill(h, corner_pts(Ncidx2,1)+ stitched_x(k),corner_pts(Ncidx2,2)+stitched_y(k),'b','FaceAlpha',0.4,'EdgeAlpha',0);
            text(h,double(stitched_x(k)),double(stitched_y(k)),num2str(k),'HorizontalAlignment','center','FontSize',7, 'color',[0.6,0,0]);
        end
        
    end
    
    h_lg = {h_ms,h_jitter, h_gap,h_lowconf};
    h_lg_idx = ~ (cellfun(@isempty,h_lg));
    h_lbel = {'missing images','settling error','mFoV gaps','low-confident overlap'};
    if sum(h_lg_idx(:))
        legend(h,[h_lg{:}],h_lbel(h_lg_idx),'Location','northeastoutside','FontSize',7);
    end
%     [~,section_name] = fileparts(section_dir);
    title(h,strrep(strrep(section_dir,'\','\\'),'_','\_'),'FontSize',8);
    set(h,'ydir','reverse')
    axis equal
    axis off
end