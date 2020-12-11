function utils_print_current_IMQA_maps(res_sec_dir, IMQA_thresh)
    ovwt = false;
    hmfov = figure(985);
    hbeam = figure(211);
    hprtmfov = copyobj(hmfov,hmfov.Parent);
    hprtbeam = copyobj(hbeam,hbeam.Parent);
    hprtmfov.Visible = 'off';
    hprtbeam.Visible = 'off';
    hprtmfov.Units = 'points';
    Pos = hprtmfov.Position;
    hprtmfov.Units = 'normalized';
    hprtmfov.PaperUnits = 'points';
    hprtmfov.PaperSize = [Pos(3),Pos(4)];
    hprtmfov.PaperPosition = [0, 0, Pos(3),Pos(4)];
    hprtbeam.Units = 'points';
    Pos = hprtbeam.Position;
    hprtbeam.Units = 'normalized';
    hprtbeam.PaperUnits = 'points';
    hprtbeam.PaperSize = [Pos(3),Pos(4)];
    hprtbeam.PaperPosition = [0, 0, Pos(3),Pos(4)];
%     [~, secname] = fileparts(res_sec_dir);
    outputm = [res_sec_dir, filesep, 'mFovQuality'];
    outputb = [res_sec_dir, filesep, 'beamQuality'];
    savedflag = false;
    if (~exist([outputm,'.pdf'],'file')) || ovwt
        print(hprtmfov, outputm,'-painters','-dpdf');
        savedflag = true;
    end
    if (~exist([outputb,'.pdf'],'file')) || ovwt
        print(hprtbeam, outputb,'-painters','-dpdf');
        savedflag = true;
    end
    close(hprtmfov);
    close(hprtbeam);
    if savedflag
        msgbox('Current image quality map saved!')
    else
        msgbox('Current image quality map already exists')
    end
end