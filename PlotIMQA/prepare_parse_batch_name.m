function [batch_name, batch_id] = prepare_parse_batch_name(section_dirs)
    N = length(section_dirs);
    batchnames = cell(N,1);
    for k = 1:1:N
        [foldername,~] = fileparts(section_dirs{k});
        [~, batchname] = fileparts(foldername);
        batchnames{k} = batchname;
    end
    [batch_name, ~, batch_id] = unique(batchnames,'sorted');
    batch_id = batch_id + 1;
end