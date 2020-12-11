function utils_generate_html_reports(result_dir, html_path)
    section_list = utils_report_prepare_section_list(result_dir);
    if isempty(section_list)
        disp('No section found in the selected folder');
        return
    end
    [~, wafer_name] = fileparts(result_dir);
    if nargin < 2
        html_path = [result_dir,filesep, wafer_name,'_report.htm'];
    end
    [~,~,batch_id] = unique({section_list(:).batch_timestamp});
    wafer_names = unique({section_list(:).section_dirn});
    fid = fopen(html_path,'w');
    try
        nl = [char(13),newline];
        fwrite(fid,['<!DOCTYPE html>',nl,'<html>',nl],'char*1');
        % header information includig style and javascripts
        headstr = utils_html_head([wafer_name,' Report']);
        fwrite(fid,headstr,'char*1');
        fwrite(fid,['<body>',nl],'char*1');

        % wafer name as title
        fwrite(fid,['<h3>',strjoin(wafer_names,'<br>'),'</h3>',nl,...
            '<p>Report generated on <b>',datestr(now,'mmm dd, yyyy HH:MM:SS'),...
            '</b></p>',nl,'<hr>',nl],'char*1');

        % user metadata
        if exist([result_dir,filesep,'metadata.txt'],'file')
            fidmeta = fopen([result_dir,filesep,'metadata.txt'],'r');
            metastr = fread(fidmeta,inf,'*char');
            fclose(fidmeta);
        else
            fidmeta = fopen([result_dir,filesep,'metadata.txt'],'w');
            metastr = '';
            fclose(fidmeta);
        end
        if ~isempty(metastr)
            fwrite(fid,['<pre>',metastr(:)','</pre>',nl],'char*1');
        end

        % section status summarize
        sec_sum_str = utils_section_summarize(section_list);
        fwrite(fid,sec_sum_str,'char*1');

        % buttons
        buttonstr = ['<p>',nl,...
            '<button onclick="hide_show_retake_sections(this)">Show sections to keep</button>',nl,...
            '<span>&nbsp;&nbsp;&nbsp;&nbsp;</span>',nl,...
            '<button onclick="sort_sections_by_batch_id(this)">Sort table by batch timestamp</button>',nl,...
            '<span>&nbsp;&nbsp;&nbsp;&nbsp;</span>',nl,...
            '<button onclick="window.location.href=''#latestSection''">Go to the latest section</button>',nl,...
            '<span>&nbsp;&nbsp;&nbsp;&nbsp;</span>',nl,...
            '<button onclick="window.location.href=''#waferStats''">Go to wafer-level stats</button>',nl,...
            '</p>',nl];
        fwrite(fid,buttonstr,'char*1');

        % section table
        tablestr = utils_section_table(section_list,batch_id);
        fwrite(fid,tablestr,'char*1');

        % wafer stats
        [batch_list, wafer_info] = utils_report_prepare_batch_list(section_list,result_dir,batch_id);
        fwrite(fid,['<hr>',nl,'<h4 id="waferStats">Wafer-Level Information</h4>',nl],'char*1');
        waferstr = utils_wafer_stats_table(wafer_info);
        fwrite(fid,waferstr,'char*1');

        % batch table
        tablestr2 = utils_batch_table(batch_list);
        fwrite(fid,tablestr2,'char*1');
    
        % finishing write html
        fwrite(fid,['<p style="color:gray;float:right;">&copy; ',datestr(now,'yyyy'),' Lichtman Lab at Harvard University</p>',nl,'</body>',nl],'char*1');
        fwrite(fid,['</html>',nl],'char*1');
        fclose(fid);

        % save results
        save([result_dir,filesep,'report.mat'],'section_list','batch_list','wafer_info');
    catch ME
        try
            disp(ME.message)
            disp(ME.stack(1))
            fclose(fid);
        catch
        end
    end

end