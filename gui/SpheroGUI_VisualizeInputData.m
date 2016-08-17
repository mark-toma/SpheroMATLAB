function varargout = SpheroGUI_VisualizeInputData(varargin)
% SPHEROGUI_VISUALIZEINPUTDATA MATLAB code for SpheroGUI_VisualizeInputData.fig
%      SPHEROGUI_VISUALIZEINPUTDATA, by itself, creates a new SPHEROGUI_VISUALIZEINPUTDATA or raises the existing
%      singleton*.
%
%      H = SPHEROGUI_VISUALIZEINPUTDATA returns the handle to a new SPHEROGUI_VISUALIZEINPUTDATA or the handle to
%      the existing singleton*.
%
%      SPHEROGUI_VISUALIZEINPUTDATA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPHEROGUI_VISUALIZEINPUTDATA.M with the given input arguments.
%
%      SPHEROGUI_VISUALIZEINPUTDATA('Property','Value',...) creates a new SPHEROGUI_VISUALIZEINPUTDATA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SpheroGUI_VisualizeInputData_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SpheroGUI_VisualizeInputData_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SpheroGUI_VisualizeInputData

% Last Modified by GUIDE v2.5 29-Aug-2015 18:57:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SpheroGUI_VisualizeInputData_OpeningFcn, ...
                   'gui_OutputFcn',  @SpheroGUI_VisualizeInputData_OutputFcn, ...
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


% --- Executes just before SpheroGUI_VisualizeInputData is made visible.
function SpheroGUI_VisualizeInputData_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SpheroGUI_VisualizeInputData (see VARARGIN)


s = [];
if nargin > 3
  s = varargin{1};
  if ~isa(s,'Sphero')
    s = [];
  else
    % set(hObject,'windowstyle','modal');
  end
end
handles.s = s;

handles.const.frame_rate = 40; % sample at 40 Hz
handles.const.frame_count = 4; % send 4 frames per packet: 10Hz

set(handles.sl_rotate_world,...
  'min',0,'max',360,'sliderstep',[1,10]/360);

set(handles.ax_main,...
  'nextplot','add',...
  'color',get(hObject,'color'),...
  'xcolor',get(hObject,'color'),...
  'ycolor',get(hObject,'color'),...
  'zcolor',get(hObject,'color'),...
  'box','off',...
  'xticklabel',[],...
  'yticklabel',[],...
  'zticklabel',[],...
  'ticklength',[0,0],...
  'dataaspectratio',[1,1,1]);
% plot a sphere, body axes, and put them in a xfom object
sphere(handles.ax_main,10);
hs = get(handles.ax_main,'children'); % sphere objects
set(hs,...
  'edgecolor',0.6*[1,1,1],...
  'facecolor','w',...
  'facealpha',0.8);
hb(1,1) = plot3(handles.ax_main,[0,2],[0,0],[0,0],'-r','linewidth',2);
hb(1,2) = plot3(handles.ax_main,[0,0],[0,2],[0,0],'-g','linewidth',2);
hb(1,3) = plot3(handles.ax_main,[0,0],[0,0],[0,2],'-b','linewidth',2);
hp.robot = hgtransform('parent',handles.ax_main);
set([hs,hb],'parent',hp.robot);

hw(1,1) = plot3(handles.ax_main,[0,2],[0,0],[0,0],'-r','linewidth',1);
hw(1,2) = plot3(handles.ax_main,[0,0],[0,2],[0,0],'-g','linewidth',1);
hw(1,3) = plot3(handles.ax_main,[0,0],[0,0],[0,2],'-b','linewidth',1);
hp.world = hgtransform('parent',handles.ax_main);
set(hw,'parent',hp.world);

set(hp.robot,'parent',hp.world);

view(handles.ax_main,135,10);
material shiny
lighting phong
camlight(30,30);

set(handles.ax_main,...
  'xlim',2*[-1,1],...
  'ylim',2*[-1,1],...
  'zlim',2*[-1,1]);
  

set(handles.ax_gyro,...
  'nextplot','add',...
  'xtick',[],...
  'xticklabel',[]);
hp.gyro(1,1) = plot(handles.ax_gyro,0,0,'-r');
hp.gyro(2,1) = plot(handles.ax_gyro,0,0,'-g');
hp.gyro(3,1) = plot(handles.ax_gyro,0,0,'-b');
ylabel(handles.ax_gyro,'Angular Velocity [deg/s]');

set(handles.ax_accel,'nextplot','add');
hp.accel(1,1) = plot(handles.ax_accel,0,0,'-r');
hp.accel(2,1) = plot(handles.ax_accel,0,0,'-g');
hp.accel(3,1) = plot(handles.ax_accel,0,0,'-b');
hp.accel(4,1) = plot(handles.ax_accel,0,0,'-k');
ylabel(handles.ax_accel,'Linear Acceleration [g]');
xlabel(handles.ax_accel,'Time [s]');

drawnow;

handles.hp = hp;

if ~isempty(handles.s)  
 
  % turn off stabilization
  if handles.s.SetStabilization(false);
    %failure
    disp('stab fail');
  end
 
end

% Choose default command line output for SpheroGUI_VisualizeInputData
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SpheroGUI_VisualizeInputData wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function DataStreamingCallback(src,evt,handles)

WINDOW = 10; % width of time axes in seconds

quat = src.quat;
quat = quat .* [1,-1,-1,-1]; % conjugate to get body w.r.t. global

R = quat2rot(quat','sv');

H = [R,[0;0;0];0,0,0,1]; % hom. transform
set(handles.hp.robot,'matrix',H);


% find data for strip charts based on time log and window
time = src.time_log;
time  = time - time(1);
if range(time) < WINDOW
  xlims = [min(time),min(time)+WINDOW];
else
  xlims = [max(time)-WINDOW,max(time)];
end

ids = find(time > xlims(1) & time < xlims(2));
time = time(ids);

% update strip chart data
g = src.gyro_raw_log; 
g = g(ids,:);
a = src.accel_raw_log; 
a = a(ids,:);

if strcmp('rb_world',get(get(handles.pnl_reference_frame,'selectedobject'),'tag'))
  q = handles.s.quat_log;
  q = q(ids,:);
  q = q .* [1,-1,-1,-1];
  Rq = quat2rot(q','sv');
  for ii = 1: size(Rq,3)
    g(ii,:) = (Rq(:,:,ii)*g(ii,:))';
    a(ii,:) = (Rq(:,:,ii)*a(ii,:))';
  end
end

set(handles.hp.gyro(1),'xdata',time,'ydata',g(:,1));
set(handles.hp.gyro(2),'xdata',time,'ydata',g(:,2));
set(handles.hp.gyro(3),'xdata',time,'ydata',g(:,3));

set(handles.hp.accel(1),'xdata',time,'ydata',a(:,1));
set(handles.hp.accel(2),'xdata',time,'ydata',a(:,2));
set(handles.hp.accel(3),'xdata',time,'ydata',a(:,3));
set(handles.hp.accel(4),'xdata',time,'ydata',sqrt(sum(a'.^2)));

% update axes limits
set(handles.ax_gyro,'xlim',xlims);
set(handles.ax_accel,'xlim',xlims);

if ~src.data_streaming_info.is_enabled
  set(handles.pb_start_streaming,'enable','on');
end

drawnow;  


% --- Outputs from this function are returned to the command line.
function varargout = SpheroGUI_VisualizeInputData_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

  
% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(handles.s)
  
  % turn off data streaming
  handles.s.NewDataStreamingFcn = [];
  if handles.s.SetDataStreaming(1,1,0,{''});
    % failure
  end
  
  % turn stabilization back on
  if handles.s.SetStabilization(true);
    % failure
  end
  
end


% --- Executes on button press in pb_start_streaming.
function pb_start_streaming_Callback(hObject, eventdata, handles)
% hObject    handle to pb_start_streaming (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

switch get(hObject,'string')
  case 'Enable Data Streaming'
    set(hObject,'string','Disable Data Streaming');
    % this button sets off data streaming
    if ~isempty(handles.s) 
      % set callback
      handles.s.NewDataStreamingFcn = @(src,evt)DataStreamingCallback(src,evt,handles);
      handles.s.ClearLogs;
      handles.s.SetDataStreaming(...
        handles.const.frame_rate,...
        handles.const.frame_count,...
        0,...
        {'accel_raw','gyro_raw','quat'});
      % disable this button
    end
    case 'Disable Data Streaming'
    set(hObject,'string','Enable Data Streaming');
    % clear callback to prevent more updates
    handles.s.NewDataStreamingFcn = [];

    % this button sets off data streaming
    if ~isempty(handles.s)
      handles.s.SetDataStreaming(1,1,0,{''});
      % disable this button 
    end
    
end


% --- Executes on slider movement.
function sl_rotate_world_Callback(hObject, eventdata, handles)
% hObject    handle to sl_rotate_world (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
t = get(hObject,'value'); ct = cosd(t); st = sind(t);
H = [ct,-st,0,0;st,ct,0,0;0,0,1,0;0,0,0,1];
set(handles.hp.world,'matrix',H);
drawnow;

% --- Executes during object creation, after setting all properties.
function sl_rotate_world_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sl_rotate_world (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes when selected object is changed in pnl_reference_frame.
function pnl_reference_frame_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in pnl_reference_frame 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
