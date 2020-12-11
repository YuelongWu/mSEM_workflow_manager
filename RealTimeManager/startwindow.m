function varargout = startwindow(varargin)
% STARTWINDOW MATLAB code for startwindow.fig
%      STARTWINDOW, by itself, creates a new STARTWINDOW or raises the existing
%      singleton*.
%
%      H = STARTWINDOW returns the handle to a new STARTWINDOW or the handle to
%      the existing singleton*.
%
%      STARTWINDOW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STARTWINDOW.M with the given input arguments.
%
%      STARTWINDOW('Property','Value',...) creates a new STARTWINDOW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before startwindow_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to startwindow_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help startwindow

% Last Modified by GUIDE v2.5 22-Jan-2019 14:22:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @startwindow_OpeningFcn, ...
                   'gui_OutputFcn',  @startwindow_OutputFcn, ...
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


% --- Executes just before startwindow is made visible.
function startwindow_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to startwindow (see VARARGIN)

% Choose default command line output for startwindow
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
uiwait(handles.figure1);

% UIWAIT makes startwindow wait for user response (see UIRESUME)



% --- Outputs from this function are returned to the command line.
function varargout = startwindow_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
output = struct;
output.PlasmaStatus = get(handles.YesPlasma,'Value');
output.PlasmaMinute = get(handles.PlasmaMinute,'String');
output.BeamCrntStatus = get(handles.YesBeam,'Value');
output.BeamCrnt = get(handles.BeamCrnt,'String');
output.Email = get(handles.YesEmail,'Value');
% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2} = output;


% --- Executes on button press in ok_button.
function ok_button_Callback(hObject, eventdata, handles)
% hObject    handle to ok_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume;
% close(handles.figure1);
guidata(hObject, handles);

% --- Executes on button press in NoPlasma.
function NoPlasma_Callback(hObject, eventdata, handles)
% hObject    handle to NoPlasma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
crntstate = get(hObject,'Value');
if crntstate
    set(handles.PlasmaMinute,'Enable','off');
else
    set(handles.PlasmaMinute,'Enable','on');
end
% Hint: get(hObject,'Value') returns toggle state of NoPlasma
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function PlasmaMinute_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function BeamCrnt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in YesPlasma.
function YesPlasma_Callback(hObject, eventdata, handles)
% hObject    handle to YesPlasma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
crntstate = get(hObject,'Value');
if crntstate
    set(handles.PlasmaMinute,'Enable','on');
else
    set(handles.PlasmaMinute,'Enable','off');
end
% Hint: get(hObject,'Value') returns toggle state of NoPlasma
guidata(hObject, handles);


% --- Executes on button press in NoBeam.
function NoBeam_Callback(hObject, eventdata, handles)
crntstate = get(hObject,'Value');
if crntstate
    set(handles.BeamCrnt,'Enable','off');
else
    set(handles.BeamCrnt,'Enable','on');
end
% Hint: get(hObject,'Value') returns toggle state of NoPlasma
guidata(hObject, handles);


% --- Executes on button press in YesBeam.
function YesBeam_Callback(hObject, eventdata, handles)
crntstate = get(hObject,'Value');
if crntstate
    set(handles.BeamCrnt,'Enable','on');
else
    set(handles.BeamCrnt,'Enable','off');
end
% Hint: get(hObject,'Value') returns toggle state of NoPlasma
guidata(hObject, handles);

function PlasmaMinute_Callback(hObject, eventdata, handles)

function BeamCrnt_Callback(hObject, eventdata, handles)


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(hObject);
% Hint: delete(hObject) closes the figure