function varargout = plot_imqa_ui(varargin)
% PLOT_IMQA_UI MATLAB code for plot_imqa_ui.fig
%      PLOT_IMQA_UI, by itself, creates a new PLOT_IMQA_UI or raises the existing
%      singleton*.
%
%      H = PLOT_IMQA_UI returns the handle to a new PLOT_IMQA_UI or the handle to
%      the existing singleton*.
%
%      PLOT_IMQA_UI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLOT_IMQA_UI.M with the given input arguments.
%
%      PLOT_IMQA_UI('Property','Value',...) creates a new PLOT_IMQA_UI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plot_imqa_ui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plot_imqa_ui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help plot_imqa_ui

% Last Modified by GUIDE v2.5 27-Feb-2019 15:36:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plot_imqa_ui_OpeningFcn, ...
                   'gui_OutputFcn',  @plot_imqa_ui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before plot_imqa_ui is made visible.
function plot_imqa_ui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plot_imqa_ui (see VARARGIN)
result_dir = varargin{1}{1};
[section_names, ifvalidated, ifready, result_section_dirs] = prepare_section_lists_for_IMQA(result_dir);
[batch_names, batch_ids] = prepare_parse_batch_name(result_section_dirs);
handles.result_dir = result_dir;
handles.result_section_dirs_all = result_section_dirs;
handles.ifvalidated_all = ifvalidated;
handles.section_names_all = section_names;
handles.ifready_all = ifready;
handles.batch_names_all = batch_names;
set(handles.popup_batch,'String',[{'**************** All ****************'};batch_names(:)]);
handles.batch_ids = batch_ids;
crnt_batch_id = get(handles.popup_batch,'Value');
if crnt_batch_id == 1 % All
    sec_idx = true(size(handles.ifready_all));
else
    sec_idx = batch_ids == crnt_batch_id;
end
handles.sec_idx = find(sec_idx);
handles.result_section_dirs = result_section_dirs(sec_idx);
handles.section_names = section_names(sec_idx);
handles.ifvalidated = ifvalidated(sec_idx);
handles.ifready = ifready(sec_idx);
sectionstrs = prepare_html_section_names(handles.section_names, handles.ifvalidated, handles.ifready);

handles.IMQAthresh = str2double(get(handles.edit_thresh,'String'));  % larger one
handles.IMQAthresh2 = str2double(get(handles.edit_thresh2,'String'));  % smaller one
handles.IMQAcm = [[linspace(1,0.5,255).^2; linspace(0,0.3,255); linspace(0,1,255)]';[0,1,0]];  % colormap of the IMQA_map: red->blue green
% handles.IMQAcm = [[1,0,0];repmat([0.5,0.3,1],254,1);[0,1,0]];  % colormap of the IMQA_map: red blue green
handles.mapAlpha = 0.35;


overide_path = {};
overide_mute = false;
save(['ConfigFiles',filesep,'path_overide_settings.mat'],'overide_path','overide_mute');

if isempty(handles.section_names)
    handles.empty_queue = true;
    utils_enable_disable_uicontrols(handles, 'off')
else
    sec_num = get(handles.popup_sections,'Value');
    sec_num = max(1,min(sec_num, length(handles.result_section_dirs)));
    set(handles.popup_sections,'Value',sec_num);
    set(handles.popup_sections,'String',sectionstrs);
    handles.empty_queue = false;
    utils_enable_disable_uicontrols(handles, 'on')
    res_sec_dir = handles.result_section_dirs{sec_num};
    [ovv_info, IMQA_options] = utils_constrain_IMQA_options(res_sec_dir, handles);
    hIMQA = cell(6,1);
    if ~isempty(ovv_info) && any(IMQA_options)
        hIMQA = utils_init_quality_map(ovv_info, IMQA_options,res_sec_dir,handles);
    else
        try close(985);close(211);catch;end
    end
    handles.hIMQA = hIMQA;
    % [hMfovID, hIMQA, IMQA_val] = utils_initialize_quality_map(res_sec_dir);
    % handles.hMfovID = hMfovID;
    % handles.hIMQA = hIMQA;
    % handles.IMQA_val = IMQA_val;
    % utils_update_text_color(hMfovID, hIMQA, IMQA_val, handles.IMQAthresh);
    try close(3101);catch; end
    ifvalidated = handles.ifvalidated;
    ifdiscard = abs(ifvalidated - round(ifvalidated))>0.05;
    ifvalidated = round(ifvalidated);
    if ifvalidated(sec_num) == 1
        set(handles.radio_good,'Value',1);
    elseif ifvalidated(sec_num) == -1
        set(handles.radio_bad,'Value',1);
    else
        set(handles.radio_notverified,'Value',1);
    end
    if ~isempty(ovv_info) && any(IMQA_options) && ~ifdiscard(sec_num)
        mutewindows = get(handles.mutefullres,'Value');
        utils_pop_up_issue_window(res_sec_dir, ovv_info, mutewindows);
    end
    if ifdiscard(sec_num)
        set(handles.pushbutton_overide,'String','retrieve');
        set(handles.pushbutton_overide,'ForegroundColor','black');
    else
        set(handles.pushbutton_overide,'String','discard');
        set(handles.pushbutton_overide,'ForegroundColor','red');
    end
end
% Choose default command line output for plot_imqa_ui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes plot_imqa_ui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = plot_imqa_ui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in button_refresh.
function button_refresh_Callback(hObject, eventdata, handles)
% hObject    handle to button_refresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[section_names, ifvalidated, ifready, result_section_dirs] = prepare_section_lists_for_IMQA(handles.result_dir);
[batch_names, batch_ids] = prepare_parse_batch_name(result_section_dirs);
handles.result_section_dirs_all = result_section_dirs;
handles.ifvalidated_all = ifvalidated;
handles.section_names_all = section_names;
handles.ifready_all = ifready;
handles.batch_names_all = batch_names;
set(handles.popup_batch,'String',[{'**************** All ****************'};batch_names(:)]);
handles.batch_ids = batch_ids;
crnt_batch_id = get(handles.popup_batch,'Value');
if crnt_batch_id == 1 % All
    sec_idx = true(size(handles.ifready_all));
else
    sec_idx = handles.batch_ids == crnt_batch_id;
end
handles.sec_idx = find(sec_idx);
handles.result_section_dirs = result_section_dirs(sec_idx);
handles.section_names = section_names(sec_idx);
handles.ifvalidated = ifvalidated(sec_idx);
handles.ifready = ifready(sec_idx);
sectionstrs = prepare_html_section_names(handles.section_names, handles.ifvalidated, handles.ifready);
handles.IMQAthresh = str2double(get(handles.edit_thresh,'String'));
handles.IMQAthresh2 = str2double(get(handles.edit_thresh2,'String'));

if isempty(handles.section_names)
    handles.empty_queue = true;
    if crnt_batch_id == 1
        set(handles.popup_sections,'String','No section processed yet');
    else
        set(handles.popup_sections,'String','No section in this batch');
    end
    utils_enable_disable_uicontrols(handles, 'off')
else
    sec_num = get(handles.popup_sections,'Value');
    sec_num = max(1,min(sec_num, length(handles.result_section_dirs)));
    set(handles.popup_sections,'Value',sec_num);
    set(handles.popup_sections,'String',sectionstrs);
    handles.empty_queue = false;
    utils_enable_disable_uicontrols(handles, 'on');
    set(handles.popup_selcomment,'Value',1);
    res_sec_dir = handles.result_section_dirs{sec_num};
    [ovv_info, IMQA_options] = utils_constrain_IMQA_options(res_sec_dir, handles);
    hIMQA = cell(6,1);
    if ~isempty(ovv_info) && any(IMQA_options)
        hIMQA = utils_init_quality_map(ovv_info, IMQA_options,res_sec_dir,handles);
    else
        try close(985);close(211);catch;end
    end
    handles.hIMQA = hIMQA;
    % [hMfovID, hIMQA, IMQA_val] = utils_initialize_quality_map(res_sec_dir);
    % handles.hMfovID = hMfovID;
    % handles.hIMQA = hIMQA;
    % handles.IMQA_val = IMQA_val;
    % utils_update_text_color(hMfovID, hIMQA, IMQA_val, handles.IMQAthresh);
    try close(3101);catch; end
    ifvalidated = handles.ifvalidated;
    ifdiscard = abs(ifvalidated - round(ifvalidated))>0.05;
    ifvalidated = round(ifvalidated);
    if ifvalidated(sec_num) == 1
        set(handles.radio_good,'Value',1);
    elseif ifvalidated(sec_num) == -1
        set(handles.radio_bad,'Value',1);
    else
        set(handles.radio_notverified,'Value',1);
    end
    if ~isempty(ovv_info) && any(IMQA_options) && ~ifdiscard(sec_num)
        mutewindows = get(handles.mutefullres,'Value');
        utils_pop_up_issue_window(res_sec_dir, ovv_info, mutewindows);
    end
    if ifdiscard(sec_num)
        set(handles.pushbutton_overide,'String','retrieve');
        set(handles.pushbutton_overide,'ForegroundColor','black');
    else
        set(handles.pushbutton_overide,'String','discard');
        set(handles.pushbutton_overide,'ForegroundColor','red');
    end
end

% Update handles structure
guidata(hObject, handles);

% --- Executes on selection change in popup_sections.
function popup_sections_Callback(hObject, eventdata, handles)
% hObject    handle to popup_sections (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_sections contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_sections
sec_num = get(hObject,'Value');
res_sec_dir = handles.result_section_dirs{sec_num};
set(handles.popup_selcomment,'Value',1);
[ovv_info, IMQA_options] = utils_constrain_IMQA_options(res_sec_dir, handles);
hIMQA = cell(6,1);
if ~isempty(ovv_info) && any(IMQA_options)
    hIMQA = utils_init_quality_map(ovv_info, IMQA_options,res_sec_dir,handles);
else
    try close(985);close(211);catch;end
end
handles.hIMQA = hIMQA;
% [hMfovID, hIMQA, IMQA_val] = utils_initialize_quality_map(res_sec_dir);
% utils_update_text_color(hMfovID, hIMQA, IMQA_val, handles.IMQAthresh);
% handles.hMfovID = hMfovID;
% handles.hIMQA = hIMQA;
% handles.IMQA_val = IMQA_val;
% handles.IMQAthresh = str2double(get(handles.edit_thresh,'String'));
try close(3101);catch; end
ifvalidated = handles.ifvalidated;
ifdiscard = abs(ifvalidated - round(ifvalidated))>0.05;
ifvalidated = round(ifvalidated);
if ifvalidated(sec_num) == 1
    set(handles.radio_good,'Value',1);
elseif ifvalidated(sec_num) == -1
    set(handles.radio_bad,'Value',1);
else
    set(handles.radio_notverified,'Value',1);
end
if ~isempty(ovv_info) && any(IMQA_options) && ~ifdiscard(sec_num)
    mutewindows = get(handles.mutefullres,'Value');
    utils_pop_up_issue_window(res_sec_dir, ovv_info, mutewindows);
end
if ifdiscard(sec_num)
    set(handles.pushbutton_overide,'String','retrieve');
    set(handles.pushbutton_overide,'ForegroundColor','black');
else
    set(handles.pushbutton_overide,'String','discard');
    set(handles.pushbutton_overide,'ForegroundColor','red');
end
    % Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function popup_sections_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_sections (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_savesingle.
function button_savesingle_Callback(hObject, eventdata, handles)
% hObject    handle to button_savesingle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
sec_num = get(handles.popup_sections,'Value');
res_sec_dir = handles.result_section_dirs{sec_num};
params = struct;
params.IMQAcm = handles.IMQAcm;
params.IMQAthresh = handles.IMQAthresh;
params.IMQAthresh2 = handles.IMQAthresh2;
showmfov = get(handles.checkbox_mfov,'Value');
showfsp = get(handles.checkbox_fsp,'Value');
showovv = get(handles.checkbox_overview,'Value');
showIMQA = get(handles.checkbox_sfov,'Value');
IMQA_options0 = [showmfov, showfsp, showovv, showIMQA];
utils_init_quality_map_print(IMQA_options0, res_sec_dir, params)
guidata(hObject, handles);

% --- Executes on button press in button_saveall.
function button_saveall_Callback(hObject, eventdata, handles)
% hObject    handle to button_saveall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
params = struct;
params.IMQAcm = handles.IMQAcm;
params.IMQAthresh = handles.IMQAthresh;
params.IMQAthresh2 = handles.IMQAthresh2;
showmfov = get(handles.checkbox_mfov,'Value');
showfsp = get(handles.checkbox_fsp,'Value');
showovv = get(handles.checkbox_overview,'Value');
showIMQA = get(handles.checkbox_sfov,'Value');
IMQA_options0 = [showmfov, showfsp, showovv, showIMQA];
utils_init_quality_map_print(IMQA_options0, handles.result_section_dirs, params)
guidata(hObject, handles);


function edit_thresh_Callback(hObject, eventdata, handles)
% hObject    handle to edit_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_thresh as text
%        str2double(get(hObject,'String')) returns contents of edit_thresh as a double


% --- Executes during object creation, after setting all properties.
function edit_thresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_thresh.
function button_thresh_Callback(hObject, eventdata, handles)
% hObject    handle to button_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
thresh_str = get(handles.edit_thresh, 'String');
thresh_num = str2double(thresh_str);
thresh_str2 = get(handles.edit_thresh2, 'String');
thresh_num2 = str2double(thresh_str2);
if isnan(thresh_num) || isnan(thresh_num2) || (thresh_num < thresh_num2)
    set(handles.edit_thresh, 'String', num2str(handles.IMQAthresh));
    set(handles.edit_thresh2, 'String', num2str(handles.IMQAthresh2));
else
    handles.IMQAthresh = thresh_num;
    handles.IMQAthresh2 = thresh_num2;
    if ~isempty(handles.hIMQA{5})
        try
            caxis(handles.hIMQA{5},[thresh_num2, thresh_num]);
            set(handles.hIMQA{6},'String',['Thresholds: ',num2str(thresh_num2),' ~ ',num2str(thresh_num),'  ']);
        catch % ME
            % disp(ME.message)
        end
    end
    % utils_update_text_color(handles.hMfovID, handles.hIMQA, handles.IMQA_val, handles.IMQAthresh);
end

guidata(hObject, handles);

% --- Executes on button press in radio_notverified.
function radio_notverified_Callback(hObject, eventdata, handles)
% hObject    handle to radio_notverified (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') == 1
    if ~isempty(handles.section_names)
        sec_num = get(handles.popup_sections,'Value');
        res_sec_dir = handles.result_section_dirs{sec_num};
        if exist([res_sec_dir,filesep,'noretake'], 'file')
            delete([res_sec_dir,filesep,'noretake'])
        end
        if exist([res_sec_dir,filesep,'yesretake'], 'file')
            delete([res_sec_dir,filesep,'yesretake'])
        end
        handles.ifvalidated(sec_num) = 0 + handles.ifvalidated(sec_num) - round(handles.ifvalidated(sec_num));
        handles.ifvalidated_all(handles.sec_idx(sec_num)) = 0 + handles.ifvalidated_all(handles.sec_idx(sec_num))...
            - round(handles.ifvalidated_all(handles.sec_idx(sec_num)));
        sectionstrs = prepare_html_section_names(handles.section_names, handles.ifvalidated, handles.ifready);
        set(handles.popup_sections,'String',sectionstrs);
    end
    % set(handles.pushbutton_overide,'Enable','on');
end
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radio_notverified

% --- Executes on button press in radio_notverified.
function radio_bad_Callback(hObject, eventdata, handles)
% hObject    handle to radio_notverified (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radio_bad
if get(hObject,'Value') == 1
    if ~isempty(handles.section_names)
        sec_num = get(handles.popup_sections,'Value');
        res_sec_dir = handles.result_section_dirs{sec_num};
        if exist([res_sec_dir,filesep,'noretake'], 'file')
            delete([res_sec_dir,filesep,'noretake'])
        end
        if ~exist([res_sec_dir,filesep,'yesretake'], 'file')
            fidflag = fopen([res_sec_dir,filesep,'yesretake'],'w');
            fclose(fidflag);
        end
        handles.ifvalidated(sec_num) = -1 + handles.ifvalidated(sec_num) - round(handles.ifvalidated(sec_num));
        handles.ifvalidated_all(handles.sec_idx(sec_num)) = -1 + handles.ifvalidated_all(handles.sec_idx(sec_num))...
            - round(handles.ifvalidated_all(handles.sec_idx(sec_num)));
        sectionstrs = prepare_html_section_names(handles.section_names, handles.ifvalidated, handles.ifready);
        set(handles.popup_sections,'String',sectionstrs);
    end
    % set(handles.pushbutton_overide,'Enable','off');
end
guidata(hObject, handles);


% --- Executes on button press in radio_notverified.
function radio_good_Callback(hObject, eventdata, handles)
% hObject    handle to radio_notverified (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radio_good
if get(hObject,'Value') == 1
    if ~isempty(handles.section_names)
        sec_num = get(handles.popup_sections,'Value');
        res_sec_dir = handles.result_section_dirs{sec_num};
        if exist([res_sec_dir,filesep,'yesretake'], 'file')
            delete([res_sec_dir,filesep,'yesretake'])
        end
        if ~exist([res_sec_dir,filesep,'noretake'], 'file')
            fidflag = fopen([res_sec_dir,filesep,'noretake'],'w');
            fclose(fidflag);
        end
        handles.ifvalidated(sec_num) = 1 + handles.ifvalidated(sec_num) - round(handles.ifvalidated(sec_num));
        handles.ifvalidated_all(handles.sec_idx(sec_num)) = 1 + handles.ifvalidated_all(handles.sec_idx(sec_num))...
            - round(handles.ifvalidated_all(handles.sec_idx(sec_num)));
        sectionstrs = prepare_html_section_names(handles.section_names, handles.ifvalidated, handles.ifready);
        set(handles.popup_sections,'String',sectionstrs);
    end
    % set(handles.pushbutton_overide,'Enable','on');
end
guidata(hObject, handles);


% --- Executes on button press in add_comment_button.
function add_comment_button_Callback(hObject, eventdata, handles)
% hObject    handle to add_comment_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(handles.section_names)
    sec_num = get(handles.popup_sections,'Value');
    res_sec_dir = handles.result_section_dirs{sec_num};
    if ~exist([res_sec_dir,filesep,'user_comment.txt'], 'file')
        fidcm = fopen([res_sec_dir,filesep,'user_comment.txt'],'w');
        fclose(fidcm);
    end
    winopen([res_sec_dir,filesep,'user_comment.txt'])
end
guidata(hObject, handles);


% --- Executes on button press in checkbox_mfov.
function checkbox_mfov_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_mfov (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_mfov
status = get(hObject,'Value');
if status
    utils_modify_image_handles(handles.hIMQA{1}, 'on');
else
    utils_modify_image_handles(handles.hIMQA{1}, 'off');
end
guidata(hObject, handles);

% --- Executes on button press in checkbox_sfov.
function checkbox_sfov_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_sfov (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
status = get(hObject,'Value');
if status
    utils_modify_image_handles(handles.hIMQA{4}, 'on');
    utils_modify_image_handles(handles.hIMQA{6}, 'on');
else
    utils_modify_image_handles(handles.hIMQA{4}, 'off');
    utils_modify_image_handles(handles.hIMQA{6}, 'off');
end
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of checkbox_sfov


% --- Executes on button press in checkbox_fsp.
function checkbox_fsp_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_fsp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
status = get(hObject,'Value');
if status
    utils_modify_image_handles(handles.hIMQA{2}, 'on');
else
    utils_modify_image_handles(handles.hIMQA{2}, 'off');
end
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of checkbox_fsp


% --- Executes on button press in checkbox_overview.
function checkbox_overview_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_overview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
status = get(hObject,'Value');
if status
    utils_modify_image_handles(handles.hIMQA{3}, 'on');
    try
        AlphaData = get(handles.hIMQA{4},'AlphaData');
        AlphaData = handles.mapAlpha*(AlphaData > 0);
        set(handles.hIMQA{4},'AlphaData',AlphaData);
    catch
    end
    try
        set(handles.hIMQA{1},'Color','y')
    catch
    end
else
    utils_modify_image_handles(handles.hIMQA{3}, 'off');
    try
        AlphaData = get(handles.hIMQA{4},'AlphaData');
        AlphaData = 0.75*(AlphaData > 0);
        set(handles.hIMQA{4},'AlphaData',AlphaData);
    catch
    end
    try
        set(handles.hIMQA{1},'Color','k')
    catch
    end
end
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of checkbox_overview


% --- Executes on selection change in popup_batch.
function popup_batch_Callback(hObject, eventdata, handles)
% hObject    handle to popup_batch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
crnt_batch_id = get(handles.popup_batch,'Value');
if crnt_batch_id == 1 % All
    sec_idx = true(size(handles.ifready_all));
else
    sec_idx = handles.batch_ids == crnt_batch_id;
end
handles.sec_idx = find(sec_idx);
handles.result_section_dirs = handles.result_section_dirs_all(sec_idx);
handles.section_names = handles.section_names_all(sec_idx);
handles.ifvalidated = handles.ifvalidated_all(sec_idx);
handles.ifready = handles.ifready_all(sec_idx);
sectionstrs = prepare_html_section_names(handles.section_names, handles.ifvalidated, handles.ifready);
handles.IMQAthresh = str2double(get(handles.edit_thresh,'String'));

if isempty(handles.section_names)
    handles.empty_queue = true;
    if crnt_batch_id == 1
        set(handles.popup_sections,'String','No section processed yet');
    else
        set(handles.popup_sections,'String','No section in this batch');
    end
    utils_enable_disable_uicontrols(handles, 'off');
else
    sec_num = get(handles.popup_sections,'Value');
    sec_num = max(1,min(sec_num, length(handles.result_section_dirs)));
    set(handles.popup_sections,'Value',sec_num);
    set(handles.popup_sections,'String',sectionstrs);
    handles.empty_queue = false;
    utils_enable_disable_uicontrols(handles, 'on')
    set(handles.popup_selcomment,'Value',1);
    res_sec_dir = handles.result_section_dirs{sec_num};
    [ovv_info, IMQA_options] = utils_constrain_IMQA_options(res_sec_dir, handles);
    hIMQA = cell(6,1);
    if ~isempty(ovv_info) && any(IMQA_options)
        hIMQA = utils_init_quality_map(ovv_info, IMQA_options,res_sec_dir,handles);
    else
        try close(985);close(211);catch;end
    end
    handles.hIMQA = hIMQA;
    % [hMfovID, hIMQA, IMQA_val] = utils_initialize_quality_map(res_sec_dir);
    % handles.hMfovID = hMfovID;
    % handles.hIMQA = hIMQA;
    % handles.IMQA_val = IMQA_val;
    % utils_update_text_color(hMfovID, hIMQA, IMQA_val, handles.IMQAthresh);
    try close(3101);catch; end
    ifvalidated = handles.ifvalidated;
    ifdiscard = abs(ifvalidated - round(ifvalidated))>0.05;
    ifvalidated = round(ifvalidated);
    if ifvalidated(sec_num) == 1
        set(handles.radio_good,'Value',1);
    elseif ifvalidated(sec_num) == -1
        set(handles.radio_bad,'Value',1);
    else
        set(handles.radio_notverified,'Value',1);
    end
    if ~isempty(ovv_info) && any(IMQA_options) && ~ifdiscard(sec_num)
        mutewindows = get(handles.mutefullres,'Value');
        utils_pop_up_issue_window(res_sec_dir, ovv_info,mutewindows);
    end
    if ifdiscard(sec_num)
        set(handles.pushbutton_overide,'String','retrieve');
        set(handles.pushbutton_overide,'ForegroundColor','black');
    else
        set(handles.pushbutton_overide,'String','discard');
        set(handles.pushbutton_overide,'ForegroundColor','red');
    end
end
guidata(hObject, handles);
% Hints: contents = cellstr(get(hObject,'String')) returns popup_batch contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_batch


% --- Executes during object creation, after setting all properties.
function popup_batch_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_batch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_thresh2_Callback(hObject, eventdata, handles)
% hObject    handle to edit_thresh2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_thresh2 as text
%        str2double(get(hObject,'String')) returns contents of edit_thresh2 as a double


% --- Executes during object creation, after setting all properties.
function edit_thresh2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_thresh2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popup_selcomment.
function popup_selcomment_Callback(hObject, eventdata, handles)
% hObject    handle to popup_selcomment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_selcomment contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_selcomment
comment_list = cellstr(get(hObject,'String'));
idx = get(hObject,'Value');
if idx > 1
    comment = ['[',strrep(upper(comment_list{idx}),' ','-'),']'];
    if ~isempty(handles.section_names)
        sec_num = get(handles.popup_sections,'Value');
        res_sec_dir = handles.result_section_dirs{sec_num};
        try
            if ~exist([res_sec_dir,filesep,'user_comment.txt'], 'file')
                fidcm = fopen([res_sec_dir,filesep,'user_comment.txt'],'w');
                fwrite(fidcm, comment, 'char');
                fclose(fidcm);
            else
                fidcm = fopen([res_sec_dir,filesep,'user_comment.txt'],'r+');
                tmp = fread(fidcm,inf,'*char')';
                if ~contains(tmp, comment)
                    fwrite(fidcm, comment, 'char');
                end
                fclose(fidcm);
            end
        catch
            try fclose(fidcm);catch;end
        end
    end
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function popup_selcomment_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_selcomment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_overide.
function pushbutton_overide_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_overide (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if ~isempty(handles.section_names)
        sec_num = get(handles.popup_sections,'Value');
        res_sec_dir = handles.result_section_dirs{sec_num};
        crntstr = get(hObject,'String');
        if strcmpi(crntstr,'discard')
            answer = questdlg('Are you sure you want to discard the current section?',...
                'Warning','Yes','No','No');
            if strcmp(answer, 'Yes')
                if ~exist([res_sec_dir,filesep,'discard'], 'file')
                    fidflag = fopen([res_sec_dir,filesep,'discard'],'w');
                    fclose(fidflag);
                end
                % test to see if flag successefully written
                if exist([res_sec_dir,filesep,'discard'], 'file')
                    set(hObject,'String','retrieve');
                    set(hObject,'ForegroundColor','black');
                    handles.ifvalidated(sec_num) = round(handles.ifvalidated(sec_num)) + 0.1;
                    handles.ifvalidated_all(handles.sec_idx(sec_num)) = round(handles.ifvalidated_all(handles.sec_idx(sec_num))) + 0.1;
                    sectionstrs = prepare_html_section_names(handles.section_names, handles.ifvalidated, handles.ifready);
                    set(handles.popup_sections,'String',sectionstrs);
                    try
                        if ~exist([res_sec_dir,filesep,'user_comment.txt'], 'file')
                            fidcm = fopen([res_sec_dir,filesep,'user_comment.txt'],'w');
                            fwrite(fidcm, ['[','DISCARDED',']'], 'char');
                            fclose(fidcm);
                        else
                            fidcm = fopen([res_sec_dir,filesep,'user_comment.txt'],'r+');
                            tmp = fread(fidcm,inf,'*char')';
                            if ~contains(tmp, ['[','DISCARDED',']'])
                                fwrite(fidcm, ['[','DISCARDED',']'], 'char');
                            end
                            fclose(fidcm);
                        end
                    catch
                        try fclose(fidcm);catch;end
                    end
                end
            end     
        else
            answer = questdlg('Are you sure you want to retrieve the current deleted section?',...
                'Warning','Yes','No','No');
            if strcmp(answer, 'Yes')
                if exist([res_sec_dir,filesep,'discard'], 'file')
                    delete([res_sec_dir,filesep,'discard'])
                end
                % test to see if flag successefully written
                if ~exist([res_sec_dir,filesep,'discard'], 'file')
                    set(hObject,'String','discard');
                    set(hObject,'ForegroundColor','red');
                    handles.ifvalidated(sec_num) = round(handles.ifvalidated(sec_num));
                    handles.ifvalidated_all(handles.sec_idx(sec_num)) = round(handles.ifvalidated_all(handles.sec_idx(sec_num)));
                    sectionstrs = prepare_html_section_names(handles.section_names, handles.ifvalidated, handles.ifready);
                    set(handles.popup_sections,'String',sectionstrs);
                    try
                        if exist([res_sec_dir,filesep,'user_comment.txt'], 'file')
                            fidcm = fopen([res_sec_dir,filesep,'user_comment.txt'],'r');
                            tmp = fread(fidcm,inf,'*char')';
                            fclose(fidcm);
                            if contains(tmp, ['[','DISCARDED',']'])
                                tmp = strrep(tmp,['[','DISCARDED',']'],'');
                                fidcm = fopen([res_sec_dir,filesep,'user_comment.txt'],'w');
                                fwrite(fidcm, tmp, 'char');
                                fclose(fidcm);
                            end  
                        end
                    catch
                        try fclose(fidcm);catch;end
                    end
                end
            end     
        end
    end
guidata(hObject, handles);


% --- Executes on button press in mutefullres.
function mutefullres_Callback(hObject, eventdata, handles)
% hObject    handle to mutefullres (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of mutefullres
