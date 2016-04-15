%% RollTrajectoryTracking  Track a trajectory with Roll and streaming data
% Create a sphero named s and successfully connect the device first
%
% Then, run the following blocks sequentially as you please. Note that you
% may want to wait a bit before running the "Stop Data Streaming" block so
% that you can see the strip chart go.


%% Initialize parameters

% tangential speed along circular path with radius
speed = 2; % cm/s
radius = 20; % cm

pgain = 1;
max_speed = 0.5;

% anonymous function of time that returns desired coords [xd;yd]
f = @(t) [...
  radius*cos(speed/radius*t) - radius;...
  radius*sin(speed/radius*t)];

% pack parameters in a struct that will be passed to the callback
param.func = f;

param.pgain = pgain;
param.max_speed = max_speed;

%% Initialize Sphero

% optionally align sphero
s.SetBackLEDOutput(1); % turn on back led
s.heading_offset = 90; % change heading offset
s.RollWithOffset(0,0); % orient to the heading offset to check alignment
s.SetBackLEDOutput(1); % turn off back led

% streaming param
frame_rate = 10; % effective update rate of control
frame_count = 1;
packet_count = 0; % unlimited streaming
sensors = {'odo'};

% plop the callback into spherocore
s.OnNewDataStreamingFcn = @(src,evt)rollTrajTrackCallback(src,evt,param);

s.SetStabilization(true); % set stabilization on for Roll

s.ClearLogs();

s.ConfigureLocatorWithOffset(0,0);

%% Start Data Streaming

% let her rip
s.SetDataStreaming(frame_rate,frame_count,packet_count,sensors);

%% Stop Data Streaming

s.SetDataStreaming(1,1,0,{''});

%% Clearn up the figure

delete(hf);
