%% AccelStripChart  Visualize Sphero's streaming acceleration data
% Create a sphero named s and successfully connect the device first
%
% Then, run the following blocks sequentially as you please. Note that you
% may want to wait a bit before running the "Stop Data Streaming" block so
% that you can see the strip chart go.

%% Initialize the plot

hf = figure;
hp.hax(1) = subplot(3,1,1,'nextplot','add');
hp.har(1) = plot(hp.hax(1),0,0,'-r');
hp.har(2) = plot(hp.hax(1),0,0,'-g');
hp.har(3) = plot(hp.hax(1),0,0,'-b');
hp.har(4) = plot(hp.hax(1),0,0,'-k');
ylabel('accel raw');

hp.hax(2) = subplot(3,1,2,'nextplot','add');
hp.haf(1) = plot(hp.hax(2),0,0,'-r');
hp.haf(2) = plot(hp.hax(2),0,0,'-g');
hp.haf(3) = plot(hp.hax(2),0,0,'-b');
hp.haf(4) = plot(hp.hax(2),0,0,'-k');
ylabel('accel filt');

hp.hax(3) = subplot(3,1,3,'nextplot','add');
hp.hao = plot(hp.hax(3),0,0,'-k');
ylabel('accel one');
pause(1);

window = 10; % s

%% Initialize Sphero

% streaming params
frame_rate = 10;
frame_count = 1;
packet_count = 0; % unlimited streaming
sensors = {'accel_raw','accel_filt','accel_one'};

% plop the callback into spherocore
s.NewDataStreamingFcn = @(src,evt)myAccelCallback(src,evt,hp,window);

% clear any old log data
s.ClearLogs();

%% Start Data Streaming

% let her rip
s.SetDataStreaming(frame_rate,frame_count,packet_count,sensors);

%% Stop Data Streaming

% stop streaming data
s.SetDataStreaming(1,1,0,{''});

%% Clean up the figure

% clear out the callback
s.NewDataStreamingFcn = [];

% delete the figure
delete(hf);



