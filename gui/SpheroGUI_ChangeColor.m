function varargout = SpheroGUI_ChangeColor(varargin)
% SPHEROGUI_CHANGECOLOR MATLAB code for SpheroGUI_ChangeColor.fig
%      SPHEROGUI_CHANGECOLOR, by itself, creates a new SPHEROGUI_CHANGECOLOR or raises the existing
%      singleton*.
%
%      H = SPHEROGUI_CHANGECOLOR returns the handle to a new SPHEROGUI_CHANGECOLOR or the handle to
%      the existing singleton*.
%
%      SPHEROGUI_CHANGECOLOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPHEROGUI_CHANGECOLOR.M with the given input arguments.
%
%      SPHEROGUI_CHANGECOLOR('Property','Value',...) creates a new SPHEROGUI_CHANGECOLOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SpheroGUI_ChangeColor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SpheroGUI_ChangeColor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SpheroGUI_ChangeColor

% Last Modified by GUIDE v2.5 25-Aug-2015 00:37:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SpheroGUI_ChangeColor_OpeningFcn, ...
                   'gui_OutputFcn',  @SpheroGUI_ChangeColor_OutputFcn, ...
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


% --- Executes just before SpheroGUI_ChangeColor is made visible.
function SpheroGUI_ChangeColor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SpheroGUI_ChangeColor (see VARARGIN)

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

% init axes with colorwheel
r = linspace(0,1,50);
theta = linspace(0, 2*pi, 50);
[rg, thg] = meshgrid(r,theta);
[x,y] = pol2cart(thg,rg);
hw = pcolor(handles.ax_main,x,y,thg);
colormap(hObject,hsv);
shading interp;
axis equal;

set(handles.ax_main,'nextplot','add');

% plot a selection marker
hc = plot3(handles.ax_main,0,0,2,'o',...
  'markersize',10,...
  'markeredgecolor','w',...
  'markerfacecolor','none',...
  'linewidth',2);

% make axes look invisible
set(handles.ax_main,...
  'color',get(hObject,'color'),...
  'xcolo',get(hObject,'color'),...
  'ycolor',get(hObject,'color'),...
  'box','off',...
  'xticklabel',[],...
  'yticklabel',[],...
  'ticklength',[0,0]);

handles.color_wheel = hw;
handles.color_marker = hc;

set(hObject,...
  'WindowButtonDownFcn',@(src,evt)UpdateColorPicker(src,evt,handles));

% Choose default command line output for SpheroGUI_ChangeColor
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SpheroGUI_ChangeColor wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = SpheroGUI_ChangeColor_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function UpdateColorPicker(src,evt,handles)

hw = handles.color_wheel;
hc = handles.color_marker;
ha = handles.ax_main;

% current axes point
cp = get(ha,'currentpoint');
x0 = cp(1,1);
y0 = cp(1,2);

% bail if not on the colorwheel
if norm([x0,y0])>1
  return;
end

cmap = colormap('hsv');
nmap = size(cmap,1);

xv = get(hw,'xdata');
yv = get(hw,'ydata');

% find closest point in data
N = sqrt((xv-x0).^2 + (yv-y0).^2);
[val,id] = min(N(:));

Cv = get(hw,'cdata');
C0 = Cv(id);
Cmax = max(max(Cv));
Cmin = min(min(Cv));

% scale C0 into the range 
c0 = (C0/(Cmax-Cmin)-Cmin);
idc = floor(c0*(nmap-1))+1;
rgb = cmap(idc,:);
set(hc,'xdata',x0,'ydata',y0,'markerfacecolor',rgb);
drawnow;

% notify rgb in static text
rgb_string = sprintf('rgb = [ %s]',sprintf('%0.2f ',rgb));
set(handles.st_rgb,'string',rgb_string);

% send command to sphero
if ~isempty(handles.s)
  handles.s.SetRGBLEDOutput(rgb,[],[],true);
end
