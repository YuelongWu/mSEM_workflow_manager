function varargout = plot_imqa_ui_old(varargin)
% PLOT_IMQA_UI_OLD MATLAB code for plot_imqa_ui_old.fig
%      PLOT_IMQA_UI_OLD, by itself, creates a new PLOT_IMQA_UI_OLD or raises the existing
%      singleton*.
%
%      H = PLOT_IMQA_UI_OLD returns the handle to a new PLOT_IMQA_UI_OLD or the handle to
%      the existing singleton*.
%
%      PLOT_IMQA_UI_OLD('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLOT_IMQA_UI_OLD.M with the given input arguments.
%
%      PLOT_IMQA_UI_OLD('Property','Value',...) creates a new PLOT_IMQA_UI_OLD or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plot_imqa_ui_old_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plot_imqa_ui_old_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help plot_imqa_ui_old

% Last Modified by GUIDE v2.5 14-Jan-2019 16:25:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plot_imqa_ui_old_OpeningFcn, ...
                   'gui_OutputFcn',  @plot_imqa_ui_old_OutputFcn, ...
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


% --- Executes just before plot_imqa_ui_old is made visible.
function plot_imqa_ui_old_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plot_imqa_ui_old (see VARARGIN)
result_dir = varargin{1}{1};
[section_names, ifvalidated, ifready, result_section_dirs] = prepare_section_lists_for_IMQA(result_dir);
handles.result_dir = result_dir;
handles.result_section_dirs = result_section_dirs;
handles.ifvalidated = ifvalidated;
handles.section_names = section_names;
handles.ifready = ifready;
sectionstrs = prepare_html_section_names(section_names, ifvalidated, ifready);
handles.IMQAthresh = str2double(get(handles.edit_thresh,'String'));

if isempty(section_names)
    handles.empty_queue = true;
    utils_enable_disable_uicontrols(handles, 'off')
else
    set(handles.popup_sections,'String',sectionstrs);
    handles.empty_queue = false;
    utils_enable_disable_uicontrols(handles, 'on')
    sec_num = get(handles.popup_sections,'Value');
    res_sec_dir = result_section_dirs{sec_num};
    [hMfovID, hIMQA, IMQA_val] = utils_initialize_quality_map(res_sec_dir);
    handles.hMfovID = hMfovID;
    handles.hIMQA = hIMQA;
    handles.IMQA_val = IMQA_val;
    utils_update_text_color(hMfovID, hIMQA, IMQA_val, handles.IMQAthresh);
    if ifvalidated(sec_num) == 1
        set(handles.radio_good,'Value',1);
    elseif ifvalidated(sec_num) == -1
        set(handles.radio_bad,'Value',1);
    else
        set(handles.radio_notverified,'Value',1);
    end
end
% Choose default command line output for plot_imqa_ui_old
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes plot_imqa_ui_old wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = plot_imqa_ui_old_OutputFcn(hObject, eventdata, handles) 
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
handles.result_section_dirs = result_section_dirs;
handles.ifvalidated = ifvalidated;
handles.section_names = section_names;
handles.ifready = ifready;
sectionstrs = prepare_html_section_names(section_names, ifvalidated, ifready);
if isempty(section_names)
    handles.empty_queue = true;
    utils_enable_disable_uicontrols(handles, 'off')
else
    set(handles.popup_sections,'String',sectionstrs);
    handles.empty_queue = false;
    utils_enable_disable_uicontrols(handles, 'on')
    sec_num = get(handles.popup_sections,'Value');
    res_sec_dir = result_section_dirs{sec_num};
    [hMfovID, hIMQA, IMQA_val] = utils_initialize_quality_map(res_sec_dir);
    handles.hMfovID = hMfovID;
    handles.hIMQA = hIMQA;
    handles.IMQA_val = IMQA_val;
    utils_update_text_color(hMfovID, hIMQA, IMQA_val, handles.IMQAthresh);
    if ifvalidated(sec_num) == 1
        set(handles.radio_good,'Value',1);
    elseif ifvalidated(sec_num) == -1
        set(handles.radio_bad,'Value',1);
    else
        set(handles.radio_notverified,'Value',1);
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
[hMfovID, hIMQA, IMQA_val] = utils_initialize_quality_map(res_sec_dir);
utils_update_text_color(hMfovID, hIMQA, IMQA_val, handles.IMQAthresh);
handles.hMfovID = hMfovID;
handles.hIMQA = hIMQA;
handles.IMQA_val = IMQA_val;
handles.IMQAthresh = str2double(get(handles.edit_thresh,'String'));
if handles.ifvalidated(sec_num) == 1
    set(handles.radio_good,'Value',1);
elseif handles.ifvalidated(sec_num) == -1
    set(handles.radio_bad,'Value',1);
else
    set(handles.radio_notverified,'Value',1);
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
utils_print_current_IMQA_maps(res_sec_dir, handles.IMQAthresh);
guidata(hObject, handles);

% --- Executes on button press in button_saveall.
function button_saveall_Callback(hObject, eventdata, handles)
% hObject    handle to button_saveall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
utils_print_all_IMQA_maps(handles.result_section_dirs, handles.IMQAthresh)
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
if isnan(thresh_num)
    set(handles.edit_thresh, 'String', num2str(handles.IMQAthresh));
else
    handles.IMQAthresh = thresh_num;
    utils_update_text_color(handles.hMfovID, handles.hIMQA, handles.IMQA_val, handles.IMQAthresh);
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
        if exist([res_sec_dir,filesep,'good_quality'], 'file')
            delete([res_sec_dir,filesep,'good_quality'])
        end
        if exist([res_sec_dir,filesep,'poor_quality'], 'file')
            delete([res_sec_dir,filesep,'poor_quality'])
        end
        handles.ifvalidated(sec_num) = 0;
        sectionstrs = prepare_html_section_names(handles.section_names, handles.ifvalidated, handles.ifready);
        set(handles.popup_sections,'String',sectionstrs);
    end
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
        if exist([res_sec_dir,filesep,'good_quality'], 'file')
            delete([res_sec_dir,filesep,'good_quality'])
        end
        if ~exist([res_sec_dir,filesep,'poor_quality'], 'file')
            fidflag = fopen([res_sec_dir,filesep,'poor_quality'],'w');
            fclose(fidflag);
        end
        handles.ifvalidated(sec_num) = -1;
        sectionstrs = prepare_html_section_names(handles.section_names, handles.ifvalidated, handles.ifready);
        set(handles.popup_sections,'String',sectionstrs);
    end
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
        if exist([res_sec_dir,filesep,'poor_quality'], 'file')
            delete([res_sec_dir,filesep,'poor_quality'])
        end
        if ~exist([res_sec_dir,filesep,'good_quality'], 'file')
            fidflag = fopen([res_sec_dir,filesep,'good_quality'],'w');
            fclose(fidflag);
        end
        handles.ifvalidated(sec_num) = 1;
        sectionstrs = prepare_html_section_names(handles.section_names, handles.ifvalidated, handles.ifready);
        set(handles.popup_sections,'String',sectionstrs);
    end
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
