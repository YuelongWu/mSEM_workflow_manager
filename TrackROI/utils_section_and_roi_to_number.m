function section_id = utils_section_and_roi_to_number(section_names)
    id_cell = utils_textscan_trackroi(section_names,'%*s%f%f%*s',{'S','R','.'});
    section_id = id_cell{1};
    roi_id = id_cell{2};
    roi_id(isnan(roi_id)) = 0;
    section_id(isnan(section_id)) = max(section_id(:)+10000);
    if all(isnan(section_id))
        section_id = (1:length(section_names(:)))';
    else
        section_id = section_id(:) + roi_id(:)/1000;
    end
end