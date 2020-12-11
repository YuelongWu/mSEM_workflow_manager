function headstr = utils_html_head(page_title)
    if nargin < 1
        page_title = 'Report';
    end
    nl = [char(13),newline];
    try
        fid = fopen('msem_report_style.css','r');
        css_str = fread(fid,inf,'*char');
        fclose(fid);
    catch
        try flose(fid); catch; end
    end
    try
        fid = fopen('msem_report_table.js','r');
        js_str = fread(fid,inf,'*char');
        fclose(fid);
    catch
        try flose(fid); catch; end
    end
    headstr = ['<head>',nl,...
        '<meta charset="UTF-8">',...
        '<title>',page_title,'</title>',nl,...
        '<base target="_blank">',nl,...
        '<style>',nl,css_str(:)','</style>',nl,...
        '<script>',nl,js_str(:)','</script>',nl,...
        '</head>',nl];
end