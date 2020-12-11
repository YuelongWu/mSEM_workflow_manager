function timestr = utils_decompress_time_str(compressed_time_struct, exception_idx, exception_timestr, k)
    % decompress the compressed time str to e.g. '2018-01-12T1028176861848'
    % Use together with utils_compress_time_str.m
    exp_idx = find(exception_idx == k, 1);
    if ~isempty(exp_idx)
        timestr = exception_timestr{exp_idx};
    else
        yy = compressed_time_struct.yearlist(compressed_time_struct.yearidx(k));
        mm = compressed_time_struct.monthlist(compressed_time_struct.monthidx(k));
        dd = compressed_time_struct.daylist(compressed_time_struct.dayidx(k));
        tt = compressed_time_struct.timelist(compressed_time_struct.timeidx(k));
        timestr = [pad(num2str(yy),4,'left','0'), '-', ...
            pad(num2str(mm),2,'left','0'), '-', ...
            pad(num2str(dd),2,'left','0'),'T',...
            pad(num2str(tt),13,'left','0')];
    end
end
        