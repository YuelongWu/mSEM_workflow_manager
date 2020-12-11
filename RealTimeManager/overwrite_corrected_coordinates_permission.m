clc;
targetFolder = uigetdir('W:\Instrument_drop\Alex','select wafer folder');
batchlist = dir(targetFolder);
batchlist = batchlist([batchlist.isdir]);
batchlist = batchlist(3:end);
t=0;
for b = 1:length(batchlist)
    sectionlist = dir([batchlist(b).folder,filesep,batchlist(b).name]);
    sectionlist = sectionlist([sectionlist.isdir]);
    sectionlist = sectionlist(3:end);
    for s = 1:length(sectionlist)
        filelist = dir([sectionlist(s).folder,filesep,sectionlist(s).name,filesep,'*_corrected.txt']);
        for k = 1:length(filelist)
            [status,cmdout] = dos(['icacls ','"',filelist(k).folder,filesep,filelist(k).name,'" /grant Everyone:F']);
            t=t+1;
            if status
                fprintf(2,strrep(cmdout,'\','\\'))
            else
                % disp(cmdout)
            end
        end
    end
end