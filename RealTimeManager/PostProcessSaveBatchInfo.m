src_dir = 'Z:\Yuelong\tmp\zebrafish\U19_zebrafish\w029h04';
tgt_dir = 'D:\multiSEM_pipeline\RetakeManager\tmp_result\zebrafish\w029h04';

% src_dir = 'Z:\Yuelong\tmp\Nag\P14\reel1_wafer23_holder02';
% tgt_dir = 'D:\multiSEM_pipeline\RetakeManager\tmp_result\Nag\W23';


poor_quals = dir([src_dir,filesep,'**',filesep,'poor_quality']);
for k = 1:length(poor_quals)
    try
    flagfile = [poor_quals(k).folder,filesep,poor_quals(k).name];
    copyfile(flagfile,strrep(strrep(flagfile,src_dir,tgt_dir),'poor_quality','yesretake'));
    catch
    end
end

good_quals = dir([src_dir,filesep,'**',filesep,'good_quality']);
for k = 1:length(good_quals)
    try
    flagfile = [good_quals(k).folder,filesep,good_quals(k).name];
    copyfile(flagfile,strrep(strrep(flagfile,src_dir,tgt_dir),'good_quality','noretake'));
    catch
    end
end

oldp = {'AFAS Failure';'Workflow interruption';'Soft Focus';...
    'Bad Stig';'Beam to Fiber Error';'mFoV rotation';...
    'Off Target (stage)';'Off Target (ROI error)';'Jitter at the top';...
    'Distortion at the top';'Overlap gaps';'Scan Fault';...
    'Dirt/Scratch';'Partial Sections';'Broken Sections';...
    'Coming in Sections';'Missing Files';'thick patch';'|';','};

newp = strrep(upper({'[AFAS failure]';'[workflow interruption]';'[soft focus]';...
    '[bad stig]';'[beam to fiber error]';'[mFoV rotation]';...
    '[off target(stage)]';'[off target(ROI error)]';'[jitter]';...
    '[skew]';'[mFoV overlap gaps]';'[scan fault]';...
    '[dirt or scratch]';'[partial section]';'[broken section]';...
    '[coming in section]';'[missing files]';'[uneven thickness]';'';''}),' ','-'); % missing files

ucs = dir([src_dir,filesep,'**',filesep,'user_comment.txt']);
for k = 1:length(ucs)
    try
     txtfile = [ucs(k).folder,filesep,ucs(k).name];
     fid = fopen(txtfile,'r');
     tmp = fread(fid,inf,'*char');
     fclose(fid);
     if isempty(tmp)
         continue
     end
     fidr = fopen(strrep(txtfile,src_dir,tgt_dir),'w');
     fwrite(fidr,strrep(replace(tmp(:)',oldp,newp),'thick','[THICK-SECTION]'),'char*1');
     fclose(fidr);
    catch
    end
end

%%
batch_infos = dir([src_dir,filesep,'**',filesep,'batch_info.txt']);
for k = 1:length(batch_infos)
    batchfile = [batch_infos(k).folder,filesep,batch_infos(k).name];
    copyfile(batchfile,strrep(batchfile,src_dir,tgt_dir));
end