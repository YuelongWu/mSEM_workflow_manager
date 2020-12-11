function dtstr = utils_datestr_with_nat(dt)
    if isnat(dt)
        dtstr = 'nat';
    else
        dtstr = datestr(dt);
    end
end