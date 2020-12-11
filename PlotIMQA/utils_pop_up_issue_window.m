function utils_pop_up_issue_window(result_dir, ovv_info, mutewindow)
    if nargin < 3
        mutewindow = false;
    end
    if mutewindow
        return
    end
    message_cell = {'check sFoV overlap';'check mFoV overlap';...
        'check jitter';'check skew';'check scan-fault'};
    link_cell = {[result_dir, filesep,'sFoV_overlap.png'];...
        [result_dir, filesep,'overlap_errors'];...
        [result_dir, filesep,'distortion_jitter'];...
        [result_dir, filesep,'distortion_jitter'];...
        [result_dir, filesep,'scanfault']};
    TF = false(size(message_cell));
    override = struct;
    override.sfov_overlap = int8(0);
    override.mfov_overlap = int8(0);
    override.scanfault = int8(0);
    override.jitter = int8(0);
    override.skew = int8(0);
    notdefault = int8(0);
    if exist([result_dir,filesep,'user_override.mat'],'file')
        load([result_dir,filesep,'user_override.mat'],'override');
        notdefault = true;
    end
    TF_user = zeros(size(TF),'int8');
    if ovv_info.sfov_status == 1 || ovv_info.sfov_status == 2
        TF(1) = true;
        TF_user(1) = override.sfov_overlap;
    end
    if ovv_info.mfov_status == 1
        TF(2) = true;
        TF_user(2) = override.mfov_overlap;
    end
    if ovv_info.jitter_status == 1
        TF(3) = true;
        TF_user(3) = override.jitter;
    end
    if ovv_info.distort_status == 1
        TF(4) = true;
        TF_user(4) = override.skew;
    end
    if ovv_info.scanfault_status == 1
        TF(5) = true;
        TF_user(5) = override.scanfault;
    end
    if all(~TF) || all(TF_user(TF)~=0)
        return
    end
    [~,sec_name] = fileparts(result_dir);
    try
        strcell = split(sec_name,'_');
        sec_name = strcell{2};
    catch
    end
    hfig = figure(4111);
    clf(hfig);
    Fig_PropNames = {'Name','Visible','MenuBar','ToolBar','Units','Position','NumberTitle'};
    Fig_PropVals = {sec_name,'off','none','none','normalized',[0.4,0.4,0.2,0.3],'off'};
    set(hfig,Fig_PropNames,Fig_PropVals)
    N = length(TF);
    for k = 1:N
        uipanel('Title','','Units','normalized',...
            'Position',[0.025,(k-0.5)/N-0.4/N,0.95,0.8/N]);
        b = uicontrol('Style','pushbutton','Units','normalized',...
            'Position',[0.05,(k-0.5)/N-0.3/N,0.4,0.6/N],...
            'String',message_cell{k},'FontSize',11);
        b1 = uicontrol('Style','radiobutton','Units','normalized',...
            'Position',[0.5,(k-0.5)/N-0.2/N,0.15,0.4/N],...
            'String','confirm','FontSize',9);
        b2 = uicontrol('Style','radiobutton','Units','normalized',...
            'Position',[0.7,(k-0.5)/N-0.2/N,0.25,0.4/N],...
            'String','false positive','FontSize',9);
        if notdefault
            if TF_user(k) == -1
                set(b1, 'Value', 1);
                set(b2, 'Value', 0);
            elseif TF_user(k) == 1
                set(b1, 'Value', 0);
                set(b2, 'Value', 1);
            end
        end
        if TF(k)
            set(b,'Enable','on');
            set(b1,'Enable','on');
            set(b2,'Enable','on');
            set(b,'Callback',{@local_open_folder,link_cell{k}})
            set(b1,'Callback',{@local_set_overide,result_dir,message_cell{k},b2});
            set(b2,'Callback',{@local_set_overide,result_dir,message_cell{k},b1});
        else
            set(b,'Enable','off');
            set(b1,'Enable','off');
            set(b2,'Enable','off');
        end
    end
    
    set(hfig,'Visible','on');
end

function local_open_folder(~,~,target_path)
    winopen(target_path)
end

function local_set_overide(hObject,~,result_dir,message_str,hb)
    override = struct;
    override.sfov_overlap = int8(0);
    override.mfov_overlap = int8(0);
    override.scanfault = int8(0);
    override.jitter = int8(0);
    override.skew = int8(0);
    if exist([result_dir,filesep,'user_override.mat'],'file')
        load([result_dir,filesep,'user_override.mat'],'override');
    end
    switch message_str
    case 'check sFoV overlap'
        field_name = 'sfov_overlap';
        cmmt_str = '[SFOV-OVERLAP-GAPS]';
    case 'check mFoV overlap'
        field_name = 'mfov_overlap';
        cmmt_str = '[MFOV-OVERLAP-GAPS]';
    case 'check jitter'
        field_name = 'jitter';
        cmmt_str = '[JITTER]';
    case 'check skew'
        field_name = 'skew';
        cmmt_str = '[SKEW]';
    case 'check scan-fault'
        field_name = 'scanfault';
        cmmt_str = '[SCAN-FAULT]';
    otherwise
        return
    end
    TF = getfield(override,field_name);
    butstr = get(hObject,'String');
    if strcmp(butstr,'confirm') % User says it's real. Mute override flag and write comment
        try
            if ~exist([result_dir,filesep,'user_comment.txt'], 'file')
                fidcm = fopen([result_dir,filesep,'user_comment.txt'],'w');
                fwrite(fidcm, cmmt_str, 'char');
                fclose(fidcm);
            else
                fidcm = fopen([result_dir,filesep,'user_comment.txt'],'r+');
                tmp = fread(fidcm,inf,'*char')';
                if ~contains(tmp, cmmt_str)
                    fwrite(fidcm, cmmt_str, 'char');
                end
                fclose(fidcm);
            end
        catch
            try fclose(fidcm);catch;end
        end
        if TF ~= -1
            override = setfield(override,field_name,int8(-1));
            save([result_dir,filesep,'user_override.mat'],'override');
        end
    else % User says it's a false positve. Raise override flag and clear comment
        try
            if exist([result_dir,filesep,'user_comment.txt'], 'file')
                fidcm = fopen([result_dir,filesep,'user_comment.txt'],'r');
                tmp = fread(fidcm,inf,'*char')';
                fclose(fidcm);
                if contains(tmp,cmmt_str)
                    tmp = strrep(tmp,cmmt_str,'');
                    fidcm = fopen([result_dir,filesep,'user_comment.txt'],'w');
                    fwrite(fidcm, tmp, 'char');
                    fclose(fidcm);
                end  
            end
        catch
            try fclose(fidcm);catch;end
        end
        if TF ~= 1
            override = setfield(override,field_name,int8(1));
            save([result_dir,filesep,'user_override.mat'],'override');
        end
    end
    set(hObject, 'Value', 1);
    set(hb, 'Value', 0);
end
