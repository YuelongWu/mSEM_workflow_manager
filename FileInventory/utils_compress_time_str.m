function [compressed_time_struct, exception_idx, exception_timestr] = utils_compress_time_str(timestr)
    % compress cell of time strings (e.g. '2018-01-12T1028176861848') to a
    % smaller size to save space. Use together with:
    % utils_decompress_time_str.m
    N = length(timestr);
    yyyy = zeros(N,1,'uint16');
    mmmm = zeros(N,1,'uint8');
    dddd = zeros(N,1,'uint8');
    tttt = zeros(N,1,'uint64');
    exception_bool = false(N,1);
    for k = 1:N
        outcell = textscan(timestr{k},'%u16%u8%u8%u64','Delimiter', {'-', 'T'});
        if ~isempty(outcell{1})
            yyyy(k) = outcell{1};
        else
            exception_bool(k) = true;
            continue;
        end
        if ~isempty(outcell{2})
            mmmm(k) = outcell{2};
        else
            exception_bool(k) = true;
            continue;
        end
        if ~isempty(outcell{3})
            dddd(k) = outcell{3};
        else
            exception_bool(k) = true;
            continue;
        end
        if ~isempty(outcell{4})
            tttt(k) = outcell{4};
        else
            exception_bool(k) = true;
            continue;
        end
    end
    exception_idx = find(exception_bool);
    exception_timestr = timestr(exception_idx);
    [yy, ~, yy_idx] = unique(yyyy);
    yy_idx = uint8(yy_idx);
    [mm, ~, mm_idx] = unique(mmmm);
    mm_idx = uint8(mm_idx);
    [dd, ~, dd_idx] = unique(dddd);
    dd_idx = uint8(dd_idx);
    [tt, ~, tt_idx] = unique(tttt);
    if max(tt_idx) < 2^16
        tt_idx = uint16(tt_idx);
    else
        tt_idx = uint32(tt_idx);
    end
    compressed_time_struct.yearlist =  yy;
    compressed_time_struct.yearidx =  yy_idx;
    compressed_time_struct.monthlist =  mm;
    compressed_time_struct.monthidx =  mm_idx;
    compressed_time_struct.daylist =  dd;
    compressed_time_struct.dayidx =  dd_idx;
    compressed_time_struct.timelist =  tt;
    compressed_time_struct.timeidx =  tt_idx;
    
end
        