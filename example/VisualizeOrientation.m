%% VisualizeOrientation  Visualize Sphero's streaming quaternion data
% Create a sphero named s and successfully connect the device first
%
% Then, run the following blocks sequentially as you please. Note that you
% may want to wait a bit before running the "Stop Data Streaming" block so
% that you can see the strip chart go.

%% Initialize a figure

% make a figure and a plot to send into the callback
hf = figure;
ha = axes('nextplot','add','drawmode','fast');
% plot a see-through white sphere
sphere(ha); set(get(ha,'children'),'facecolor','w','facealpha',0.2);
% plot body-fixed axes
plot3(ha,[0,2],[0,0],[0,0],'-r','linewidth',2);
plot3(ha,[0,0],[0,2],[0,0],'-g','linewidth',2);
plot3(ha,[0,0],[0,0],[0,2],'-b','linewidth',2);
% put sphere and body-fixed axes in a transform object (for re-orientation)
hps = get(ha,'children'); % get axes children (all plotted stuff)
hx = hgtransform(); % make a transform object
set(hps,'parent',hx); % put plotted stuff in the transform
% plot global axes
plot3(ha,[0,2],[0,0],[0,0],'-r','linewidth',2);
plot3(ha,[0,0],[0,2],[0,0],'-g','linewidth',2);
plot3(ha,[0,0],[0,0],[0,2],'-b','linewidth',2);
set(ha,'dataaspectratio',[1,1,1]);
view(3); % set 3d view
pause(1); % wait a bit for the figure to come up

%% Initialize Sphero

% streaming params
frame_rate = 10;
frame_count = 1;
packet_count = 0; % unlimited streaming
sensors = {'quat'};

% plop the callback into spherocore
s.OnNewDataStreamingFcn = @(src,evt)myQuatCallback(src,evt,hx);

s.SetStabilization(false);

%% Start Data Streaming

% let her rip
s.SetDataStreaming(frame_rate,frame_count,packet_count,sensors);

%% Stop Data Streaming

s.SetDataStreaming(1,1,0,{''});

%% Clearn up the figure

delete(hf);

