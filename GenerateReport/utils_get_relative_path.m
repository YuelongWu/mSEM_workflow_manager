function relpath = utils_get_relative_path(absolute_path, parent_path)
    relpath = '';
    subfoldername = filesep;
    while (~strcmpi(absolute_path,parent_path)) && (~isempty(absolute_path)) && (~isempty(subfoldername))
        [absolute_path, subfoldername] = fileparts(absolute_path);
        relpath = [filesep,subfoldername,relpath];
    end
    if ~isempty(relpath)
        if relpath(1) == filesep
        relpath(1) = '';
        end
    else
        relpath = ['.', filesep];
    end
end