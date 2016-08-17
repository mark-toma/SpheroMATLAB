function varargout = SpheroGUI_MainControlPanel(varargin)
% SPHEROGUI_MAINCONTROLPANEL MATLAB code for SpheroGUI_MainControlPanel.fig
%      SPHEROGUI_MAINCONTROLPANEL, by itself, creates a new SPHEROGUI_MAINCONTROLPANEL or raises the existing
%      singleton*.
%
%      H = SPHEROGUI_MAINCONTROLPANEL returns the handle to a new SPHEROGUI_MAINCONTROLPANEL or the handle to
%      the existing singleton*.
%
%      SPHEROGUI_MAINCONTROLPANEL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPHEROGUI_MAINCONTROLPANEL.M with the given input arguments.
%
%      SPHEROGUI_MAINCONTROLPANEL('Property','Value',...) creates a new SPHEROGUI_MAINCONTROLPANEL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SpheroGUI_MainControlPanel_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SpheroGUI_MainControlPanel_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SpheroGUI_MainControlPanel

% Last Modified by GUIDE v2.5 29-Aug-2015 16:02:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SpheroGUI_MainControlPanel_OpeningFcn, ...
                   'gui_OutputFcn',  @SpheroGUI_MainControlPanel_OutputFcn, ...
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


% --- Executes just before SpheroGUI_MainControlPanel is made visible.
function SpheroGUI_MainControlPanel_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SpheroGUI_MainControlPanel (see VARARGIN)

handles.s = [];
set(get(handles.pnl_apps,'children'),'enable','off');

% Choose default command line output for SpheroGUI_MainControlPanel
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SpheroGUI_MainControlPanel wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SpheroGUI_MainControlPanel_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function PowerNotificationCallback(src,evt,handles)
return; % bail out
handles.s.GetPowerState(); 
pwr_info = handles.s.power_state_info;

set(handles.st_power,'string',pwr_info.power);
set(handles.st_batt_voltage,'string',...
  sprintf('%5.2f[V]',pwr_info.batt_voltage));
set(handles.st_num_charges,'string',...
  sprintf('%d[N]',pwr_info.num_charges));
set(handles.st_time_since_charge,'string',...
  sprintf('%d[s]',pwr_info.time_since_charge));


% --- Executes on button press in pb_find_devices.
function pb_find_devices_Callback(hObject, eventdata, handles)
% hObject    handle to pb_find_devices (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject,'enable','off');
set(handles.lb_device_list,'string','Searching for devices...');
drawnow;
info = handles.s.FindSpheroDevice();
if info.NumDevices > 0
  dev_names = info.RemoteNames;
  set(handles.pb_connect_device,'enable','on');
else
  dev_names = 'No devices found!';
end
set(hObject,'enable','on');
set(handles.lb_device_list,'string',dev_names);



% --- Executes on button press in pb_connect_device.
function pb_connect_device_Callback(hObject, eventdata, handles)
% hObject    handle to pb_connect_device (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% grab listbox data
dev_names = get(handles.lb_device_list,'string');
dev_id = get(handles.lb_device_list,'value');
if iscellstr(dev_names)
  dev_name = dev_names{dev_id}; % listbox selection
else
  dev_name = dev_names;
end

% take remote name from edit text if modified
if ~isempty(get(handles.et_device_name,'string'))
  remote_name = get(handles.et_device_name,'string');
elseif ~strcmp(dev_name,'Find Devices to Begin')
  remote_name = dev_names{dev_id};
else
  % not gonna try, issue warning
  msg = '1) Click Find Devices';
  msg = char(msg,'2) Select Sphero''s name from the list');
  msg = char(msg,'');
  msg = char(msg,'OR');
  msg = char(msg,'');
  msg = char(msg,'1) Enter Sphero''s name manually');
  msg = char(msg,'');
  msg = char(msg,'Before clicking Connect!');
   
  title = 'Select a Sphero!';
  warndlg(msg,title,'modal');
  return;
end

set(handles.lb_device_list,'value',1);
set(handles.lb_device_list,'string','Connecting...');
drawnow;

try
  handles.s = Sphero(remote_name);
catch err
  warning('Failed to connect Sphero ''%s'' with message,\n\t%s\n',...
    remote_name,err.message)
  handles.s = [];
end

if isempty(handles.s)
  % failed to connect
  set(hObject,'enable','on');
  set(handles.lb_device_list,'string',dev_names);
  set(handles.lb_device_list,'value',dev_id);
else
  guidata(hObject,handles);
  % successful connection
  set(hObject,'enable','off');
  set(handles.lb_device_list,'string','Connected!');
  set(handles.pb_disconnect_device,'enable','on');
  set(get(handles.pnl_apps,'children'),'enable','on');
  
  % set versioning info
  ver_info=handles.s.version_info;
  set(handles.st_ver_msa,'string',...
    sprintf('%d.%d',ver_info.msa_ver,ver_info.msa_rev));
  set(handles.st_ver_hw,'string',sprintf('%d',ver_info.hw));
  set(handles.st_ver_bl,'string',sprintf('%3.1f',ver_info.bl));
  
  % get/set bluetooth info
  handles.s.GetBluetoothInfo();
  bt_info = handles.s.bluetooth_info;
  set(handles.st_bt_name,'string',bt_info.name);
  set(handles.st_bt_address,'string',bt_info.address);
  set(handles.st_bt_id_colors,'string',bt_info.rgb);
  
  % get/set power state info
  handles.s.NewPowerNotificationFcn = @(src,evt)PowerNotificationCallback(src,evt,handles);
  handles.s.SetPowerNotification(true);
  PowerNotificationCallback(handles.s,[],handles);
  
  
end


% --- Executes on selection change in lb_device_list.
function lb_device_list_Callback(hObject, eventdata, handles)
% hObject    handle to lb_device_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lb_device_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_device_list


% --- Executes during object creation, after setting all properties.
function lb_device_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_device_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_disconnect_device.
function pb_disconnect_device_Callback(hObject, eventdata, handles)
% hObject    handle to pb_disconnect_device (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% no method for this yet
set(handles.pb_connect_device,'enable','on');

% --- Executes on button press in pb_change_color.
function pb_change_color_Callback(hObject, eventdata, handles)
% hObject    handle to pb_change_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
SpheroGUI_ChangeColor(handles.s);


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(handles.s)
  delete(handles.s);
end


% --- Executes on button press in pb_config_heading_offset.
function pb_config_heading_offset_Callback(hObject, eventdata, handles)
% hObject    handle to pb_config_heading_offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
SpheroGUI_ConfigHeadingOffset(handles.s);


% --- Executes on button press in pb_drive.
function pb_drive_Callback(hObject, eventdata, handles)
% hObject    handle to pb_drive (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
SpheroGUI_Drive(handles.s);


% --- Executes on button press in pb_visualize_input_data.
function pb_visualize_input_data_Callback(hObject, eventdata, handles)
% hObject    handle to pb_visualize_input_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
SpheroGUI_VisualizeInputData(handles.s);


function et_device_name_Callback(hObject, eventdata, handles)
% hObject    handle to et_device_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_device_name as text
%        str2double(get(hObject,'String')) returns contents of et_device_name as a double


% --- Executes during object creation, after setting all properties.
function et_device_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_device_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
