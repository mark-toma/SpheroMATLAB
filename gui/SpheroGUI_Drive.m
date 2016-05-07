function varargout = SpheroGUI_Drive(varargin)
% SPHEROGUI_DRIVE MATLAB code for SpheroGUI_Drive.fig
%      SPHEROGUI_DRIVE, by itself, creates a new SPHEROGUI_DRIVE or raises the existing
%      singleton*.
%
%      H = SPHEROGUI_DRIVE returns the handle to a new SPHEROGUI_DRIVE or the handle to
%      the existing singleton*.
%
%      SPHEROGUI_DRIVE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPHEROGUI_DRIVE.M with the given input arguments.
%
%      SPHEROGUI_DRIVE('Property','Value',...) creates a new SPHEROGUI_DRIVE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SpheroGUI_Drive_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SpheroGUI_Drive_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SpheroGUI_Drive

% Last Modified by GUIDE v2.5 28-Aug-2015 01:02:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SpheroGUI_Drive_OpeningFcn, ...
                   'gui_OutputFcn',  @SpheroGUI_Drive_OutputFcn, ...
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


% --- Executes just before SpheroGUI_Drive is made visible.
function SpheroGUI_Drive_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SpheroGUI_Drive (see VARARGIN)

set(hObject,'hittest','off');

s = [];
sphero_rgb = [0,1,0];
if nargin > 3
  s = varargin{1};
  if ~isa(s,'Sphero')
    s = [];
  else
    set(hObject,'windowstyle','modal');
    sphero_rgb = s.rgb;
  end
end
handles.s = s;

% circle data
N = 101; t = linspace(0,2*pi,N); xt = cos(t); yt = sin(t);

% constants and environment variables

handles.const.control_rate = 5; % Hz
handles.const.workspace_dim = 100; % cm
handles.const.sphero_radius = 3.5; % cm
handles.const.tail_count = 10; % number of datas
handles.const.heading_length = 8; % cm
handles.const.min_vel = 10; % cm/s
handles.const.input_radius = 1.2; % axes units
handles.const.control_radius = 1; % axes units
handles.const.frame_rate = 10; % Hz
handles.const.frame_count = 1; % Hz

handles.env.state = 'idle';

% configure drive axes
set(handles.ax_drive,...
  'nextplot','add',...
  'color',get(hObject,'color'),...
  'xcolo',get(hObject,'color'),...
  'ycolor',get(hObject,'color'),...
  'box','off',...
  'xticklabel',[],...
  'yticklabel',[],...
  'ticklength',[0,0],...
  'xlim',handles.const.input_radius*[-1,1],...
  'ylim',handles.const.input_radius*[-1,1]);

% plot filled circle background
fill3(...
  handles.const.input_radius*xt,...
  handles.const.input_radius*yt,...
  -1*ones(1,N),'r','parent',handles.ax_drive);
fill3(...
  handles.const.control_radius*xt,...
  handles.const.control_radius*yt,...
  0*ones(1,N),'w','parent',handles.ax_drive);

% plot center dot and vector head marker
hp.tail = plot(handles.ax_drive,...
  0,0,'ok','linewidth',2);
hp.head = plot(handles.ax_drive,...
  0.5,0.5,'or','linewidth',2);
hp.vector = plot(handles.ax_drive,...
  [0,0.5],[0,0.5],':b','linewidth',2);

% configure odometry axes
set(handles.ax_odometry,...
  'nextplot','add',...
  'xlim',handles.const.workspace_dim*[-0.5,0.5],...
  'ylim',handles.const.workspace_dim*[-0.5,0.5]);

% plot robot stuff in a transform object
hp.robot = hgtransform('parent',handles.ax_odometry);
fill3(...
  handles.const.sphero_radius*xt,...
  handles.const.sphero_radius*yt,...
  2*ones(1,N),...
  sphero_rgb,'parent',hp.robot);
hp.heading = plot3(...
  [0,handles.const.heading_length],...
  [0,0],[3,3],'-r','linewidth',2,'parent',hp.robot);

% plot global datas
hp.trace = plot3(handles.ax_odometry,...
  0,0,0,':k','linewidth',2);
hp.tail = plot3(handles.ax_odometry,...
  0,0,1,'-m','linewidth',2);

handles.hp = hp;

% set up control timer and initialize plot
ud = struct('speed',0,'heading',0);
handles.tmr = timer(...
  'TimerFcn',@(src,evt)TimerCallback(src,evt,handles),...
  'Period',1/handles.const.control_rate,...
  'ExecutionMode','fixedrate',...
  'userdata',ud);
UpdateInputSetpoint(handles);

if ~isempty(handles.s)
  handles.s.NewDataStreamingFcn = @(src,evt)DataStreamingCallback(src,evt,handles);
  handles.s.ConfigureLocatorWithOffset(0,0);
end

% Choose default command line output for SpheroGUI_Drive
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

set(hObject,'hittest','on');

% UIWAIT makes SpheroGUI_Drive wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SpheroGUI_Drive_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- timer issues control command to sphero
function TimerCallback(src,evt,handles)
ud = src.userdata;
speed = ud.speed;
heading = ud.heading;
handles.s.RollWithOffset(speed,heading,'normal',[],false);

% --- updates control setpoint and graphical display of drive input
function UpdateInputSetpoint(handles)
if ~isfield(handles,'env'), return; end
switch handles.env.state
  case 'drive'
    cp = get(handles.ax_drive,'currentpoint');
    cp = cp(1,1:2);
    if norm(cp) > handles.const.input_radius
      % outside input area
      
      % set setpoint to stop
      set(handles.hp.vector,'visible','off');
      set(handles.hp.head,'visible','off');
      
      ud = handles.tmr.userdata;
      ud.speed = 0;
      handles.tmr.userdata = ud;
            
    elseif norm(cp) > handles.const.control_radius
      % outside control area, but inside input area
      % leave setpoint alone
      
      % project graphic update onto this heading at max speed
      t = atan2(cp(2),cp(1));
      x = cos(t);
      y = sin(t);
      set(handles.hp.vector,'xdata',[0,x],'ydata',[0,y],'visible','on');
      set(handles.hp.head,'xdata',[0,x],'ydata',[0,y],'visible','on');
     
      ud.speed = 1;
      ud.heading = 180/pi*atan2(y,x) - 90;
      handles.tmr.userdata = ud;
    else
      % inside control area
      
      x = cp(1);
      y = cp(2);
      set(handles.hp.vector,'xdata',[0,x],'ydata',[0,y],'visible','on');
      set(handles.hp.head,'xdata',[0,x],'ydata',[0,y],'visible','on');
      
      ud.speed = norm(cp);
      ud.heading = 180/pi*atan2(y,x) - 90;
      handles.tmr.userdata = ud;
    end
      
    
  case 'idle'
    
    set(handles.hp.vector,'visible','off');
    set(handles.hp.head,'visible','off');
    
    % change setpoint to zero
    ud = handles.tmr.userdata;
    ud.speed = 0;
    handles.tmr.userdata = ud;
    
  otherwise
    disp('unknown state')
end

function DataStreamingCallback(src,evt,handles)

% odometry data
odo_log = src.odo_log;
xvec = odo_log(1,:); yvec = odo_log(2,:);
x = xvec(end); y = yvec(end);

% velocity data
vel = src.vel; 
dx = vel(1); dy = vel(2);

% uncomment to print position data
% fprintf('x: %3.1f, y: %3.1f, dx: %3.1f, dy: %3.1f\n',...
%   x,y,dx,dy);

% update trace
set(handles.hp.trace,'xdata',xvec,'ydata',yvec,'zdata',0*xvec);
% update tail
if length(xvec) > handles.const.tail_count
  xtail = xvec(end-handles.const.tail_count+1:end);
  ytail = yvec(end-handles.const.tail_count+1:end);
else
  xtail = xvec; ytail = yvec;
end
set(handles.hp.tail,'xdata',xtail,'ydata',ytail,...
  'zdata',1+0*xtail);
% update xfrm
t = atan2(dy,dx);
H = [...
  cos(t),-sin(t),0,x;...
  sin(t),cos(t),0,y;...
  0,0,1,0;...
  0,0,0,1];
set(handles.hp.robot,'matrix',H);

% update axis limits
dim = handles.const.workspace_dim;
xlims = get(handles.ax_odometry,'xlim');
ylims = get(handles.ax_odometry,'ylim');
if all(min(x) < [xlims(1),dim/2])
  xlims(1) = min(x);
end
if all(max(x) > [xlims(2),dim/2])
  xlims(2) = max(x);
end
if all(min(y) < [ylims(1),dim/2])
  ylims(1) = min(y);
end
if all(max(y) > [ylims(2),dim/2])
  ylims(2) = max(y);
end
rx = range(xlims); ry = range(ylims);
if rx > ry
  ratio = rx/ry;
  ylims = ylims + [-1,1]*(ratio-1)*ry/2;
elseif ry > rx
  ratio = ry/rx;
  xlims = xlims + [-1,1]*(ratio-1)*rx/2;
end

set(handles.ax_odometry,'xlim',xlims,'ylim',ylims);


% hide heading if velocity is zero
if norm([dx,dy]) < handles.const.min_vel
  set(handles.hp.heading,'visible','off');
else
  set(handles.hp.heading,'visible','on');
end
drawnow;

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.env.state = 'drive';
guidata(hObject,handles);
UpdateInputSetpoint(handles);

% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
UpdateInputSetpoint(handles);



% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonUpFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.env.state = 'idle';
guidata(hObject,handles);
UpdateInputSetpoint(handles);


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'tmr') && ~isempty(handles.tmr)
  stop(handles.tmr);
  delete(handles.tmr);
end
if isfield(handles,'s') && ~isempty(handles.s)
  handles.s.NewDataStreamingFcn = []; % remove callback
  handles.s.SetDataStreaming(5,1,1,{'odo','vel'});
end



% --- Executes on button press in pb_enable_drive_mode.
function pb_enable_drive_mode_Callback(hObject, eventdata, handles)
% hObject    handle to pb_enable_drive_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch get(hObject,'string')
  case 'Enable Drive Mode'
    set(hObject,'string','Disable Drive Mode');
    if ~isempty(handles.s)
      start(handles.tmr);
    end
  case 'Disable Drive Mode'
    set(hObject,'string','Enable Drive Mode');
    if ~isempty(handles.s)
      handles.s.RollWithOffset(0,0,'stop');
      stop(handles.tmr);
    end
  otherwise
    disp('bad pb string for drive mode enabler');
end

% --- Executes on button press in pb_enable_data_streaming.
function pb_enable_data_streaming_Callback(hObject, eventdata, handles)
% hObject    handle to pb_enable_data_streaming (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch get(hObject,'string')
  case 'Enable Odometry'
    set(hObject,'string','Disable Odometry');
    set(handles.ax_odometry,...
      'xlim',handles.const.workspace_dim*[-0.5,0.5],...
      'ylim',handles.const.workspace_dim*[-0.5,0.5]);      
    if ~isempty(handles.s)
      handles.s.ClearLogs();
      handles.s.ConfigureLocatorWithOffset(0,0);
      handles.s.SetDataStreaming(...
        handles.const.frame_rate,...
        handles.const.frame_count,...
        0,...
        {'odo','vel'});
    end
  case 'Disable Odometry'
    set(hObject,'string','Enable Odometry');
    if ~isempty(handles.s)
      handles.s.SetDataStreaming(...
        handles.const.frame_rate,...
        handles.const.frame_count,...
        0,...
        {''});
    end
  otherwise
    disp('bad pb string for drive mode enabler');
end
