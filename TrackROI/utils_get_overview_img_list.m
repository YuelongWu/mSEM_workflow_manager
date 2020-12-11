function [imglist, ifrender] = utils_get_overview_img_list(parent_dir)
    imglist = dir([parent_dir,filesep,'**',filesep,'overview_imgs',filesep,'*.png']);
    if isempty(imglist)
        ifrender = [];
        return
    end
    imglist = rmfield(imglist,{'date','bytes','isdir','datenum'});
    Ns = length(imglist);
    ifrender = false(Ns,1);
    for k = 1:length(imglist)
        batch_name = fileparts(imglist(k).folder);
        imglist(k).batch_name = batch_name(max(1,end-16):end);
        section_name = strrep(imglist(k).name,'.png','');
        % remove acquisition order number
        try
            section_name_cell = split(section_name,'_');
            section_namet = section_name_cell{end};
        catch
            section_namet = section_name;
        end
        imglist(k).section_name = section_namet;
        imglist(k).UUID = [imglist(k).batch_name,char(0),section_namet];
        imglist(k).isreference = false;
        imglist(k).isaligned = false;
        imglist(k).isrendered = false;
        imglist(k).A2D = eye(3);
        imglist(k).missing_area = nan;
        imglist(k).rotation = nan;
        imglist(k).displacement = [nan,nan];
        if exist([batch_name,filesep,section_name,filesep, 'discard'],'file')
            imglist(k).discard = true;
        else
            imglist(k).discard = false;
        end
    end
    % sort by the batch date
    [~,idx] = sort({imglist(:).batch_name});
    imglist = imglist(idx);
    % put discarded ones to the very begining
    [~,idx] = sort([imglist(:).discard],'descend');
    imglist = imglist(idx);
    [section_id, region_id]= utils_get_section_and_region_id({imglist(:).section_name});
    section_id = section_id + region_id/1000;
    stupid_matlab_cell = num2cell(section_id);
    [imglist.section_id] = stupid_matlab_cell{:};
    [section_id,idx] = sort(section_id,'ascend','MissingPlacement','last');
    imglist = imglist(idx);
    [~, ia, ~] = unique(section_id,'last');
    ifrender(ia) = true;
    ifrender([imglist(:).discard]) = false;
end
