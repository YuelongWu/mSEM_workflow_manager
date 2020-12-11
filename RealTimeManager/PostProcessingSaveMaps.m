sourcePath = uigetdir('SwRslt','Select the software tmp folder');
targetPath = uigetdir('tmp_result','Select the result folder');

filelist = dir([sourcePath,filesep,'**',filesep,'processed']);
folderlist = {filelist.folder};
houtfig = figure(921);
clf(houtfig,'reset');
set(houtfig,'Visible','off')
set(houtfig,'Units','normalized');
set(houtfig,'OuterPosition',[0.03 0.24 0.8 0.75]);
set(houtfig,'Units','points');
Pos = get(houtfig,'Position');
set(houtfig,'PaperUnits','points');
set(houtfig,'PaperSize',[Pos(3),Pos(4)]);
set(houtfig,'PaperPosition',[0, 0, Pos(3),Pos(4)]);
for k = 1:length(folderlist)
    try
        foldername = folderlist{k};
        rel_direct = strrep(foldername,sourcePath,'');
        result_dir = [targetPath,rel_direct];
        [result_parent,section_name] = fileparts(result_dir);
        if exist(result_parent,'dir')
            load([foldername,filesep,'metadata_file_info.mat']);
            load([foldername,filesep,'overlap_info.mat']);
            section_dir = general_info.section_dirn;
            mfov_overlap_dir = [result_parent,filesep,'maps',filesep,'mfov_overlap'];
            if ~exist(mfov_overlap_dir,'dir')
                mkdir(mfov_overlap_dir);
            end
            scanfaultskew_dir = [result_parent,filesep,'maps',filesep,'charging_scanfault'];
            if ~exist(scanfaultskew_dir,'dir')
                mkdir(scanfaultskew_dir);
            end
            jitter_dir = [result_parent,filesep,'maps',filesep,'jitter'];
            if ~exist(jitter_dir,'dir')
                mkdir(jitter_dir);
            end
            % mFoV overlap & image count
            if overlap_status.mfovOverlapCheckFinished
                missing_img = ~((add_info.thumbCount >= coord_info.thumbnail_coord.expected_img_count) & ...
                    (add_info.imgCount >= coord_info.img_coord.expected_img_count));
                if ~isempty(add_info.gapsMfovPairs) || ~isempty(add_info.lowConfMfovPairs) || any(missing_img)
                    clf(houtfig);
                    visualize_mfov_overlap(add_info,section_dir,missing_img,houtfig);
                    print(houtfig,[mfov_overlap_dir, filesep, section_name,'.pdf'],'-painters','-dpdf');
                end
            end
            if overlap_status.imageChargingCheckFinished || overlap_status.scanfaultCheckFinished
                if any(add_info.top_distortion_amp>0) || any(add_info.mfov_scanfault>0)
                    clf(houtfig);
                    visualize_top_distortion(add_info,section_dir,houtfig)
                    print(houtfig,[scanfaultskew_dir, filesep, section_name,'.pdf'],'-painters','-dpdf');
                end
            end
            if overlap_status.stageJitteringCheckFinished
                if any(add_info.stage_jitter_amp>0)
                    clf(houtfig);
                    visualize_stage_jitter(add_info,section_dir,houtfig)
                    print(houtfig,[jitter_dir, filesep, section_name,'.pdf'],'-painters','-dpdf');
                end
            end
        else
            error('No taget place exist');
        end
    catch ME
        disp(folderlist{k});
        disp(ME.message);
    end
end
close(houtfig);