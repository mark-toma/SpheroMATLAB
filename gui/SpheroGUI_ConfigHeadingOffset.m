function varargout = SpheroGUI_ConfigHeadingOffset(varargin)
% SPHEROGUI_CONFIGHEADINGOFFSET MATLAB code for SpheroGUI_ConfigHeadingOffset.fig
%      SPHEROGUI_CONFIGHEADINGOFFSET, by itself, creates a new SPHEROGUI_CONFIGHEADINGOFFSET or raises the existing
%      singleton*.
%
%      H = SPHEROGUI_CONFIGHEADINGOFFSET returns the handle to a new SPHEROGUI_CONFIGHEADINGOFFSET or the handle to
%      the existing singleton*.
%
%      SPHEROGUI_CONFIGHEADINGOFFSET('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPHEROGUI_CONFIGHEADINGOFFSET.M with the given input arguments.
%
%      SPHEROGUI_CONFIGHEADINGOFFSET('Property','Value',...) creates a new SPHEROGUI_CONFIGHEADINGOFFSET or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SpheroGUI_ConfigHeadingOffset_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SpheroGUI_ConfigHeadingOffset_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SpheroGUI_ConfigHeadingOffset

% Last Modified by GUIDE v2.5 24-Aug-2015 19:01:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SpheroGUI_ConfigHeadingOffset_OpeningFcn, ...
                   'gui_OutputFcn',  @SpheroGUI_ConfigHeadingOffset_OutputFcn, ...
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


% --- Executes just before SpheroGUI_ConfigHeadingOffset is made visible.
function SpheroGUI_ConfigHeadingOffset_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SpheroGUI_ConfigHeadingOffset (see VARARGIN)

s = [];
if nargin > 3
  s = varargin{1};
  if ~isa(s,'Sphero')
    s = [];
  else
    set(hObject,'windowstyle','modal');
  end
end
handles.s = s;

set(handles.sl_heading_offset,...
  'min',0,'max',360,'sliderstep',[5,20]/360);

if ~isempty(handles.s)
  handles.s.SetBackLEDOutput(1); % turn on back led
  set(handles.sl_heading_offset,'value',s.heading_offset);
  handles.s.RollWithOffset(0,0,'fast');
end

% Choose default command line output for SpheroGUI_ConfigHeadingOffset
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SpheroGUI_ConfigHeadingOffset wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SpheroGUI_ConfigHeadingOffset_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function sl_heading_offset_Callback(hObject, eventdata, handles)
% hObject    handle to sl_heading_offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = get(hObject,'value');
val = round(val/5)*5; % round to 5 deg increments
set(handles.st_heading_offset,'string',...
  sprintf('heading_offset = [ % 3d ]',val));
if ~isempty(handles.s)
  handles.s.heading_offset = val;
  handles.s.RollWithOffset(0,0,'fast');
end


% --- Executes during object creation, after setting all properties.
function sl_heading_offset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sl_heading_offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(handles.s)
  handles.s.heading_offset = get(handles.sl_heading_offset,'value');
  handles.s.SetBackLEDOutput(0);
end
