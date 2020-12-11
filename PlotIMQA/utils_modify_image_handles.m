function utils_modify_image_handles(h, opt)
    if isempty(h)
        return
    end
    if iscell(h)
        N = length(h);
        for k = 1:1:N
            utils_modify_image_handles(h{k}, opt);
        end
    else
        try
            switch opt
            case 'delete'
                delete(h)
            case 'on'
                set(h,'Visible','on')
            case 'off'
                set(h,'Visible','off')
            otherwise
                % place holder
            end
        catch
            % probably deleted
        end
    end
end