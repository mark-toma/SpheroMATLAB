%% Getting_Started.m
% In this script, we'll discuss the basics for using the Sphero object.

%% Prerequisites
% Before getting started, take a look at the readme.txt in the root
% directory of this release.

%% Instantiate Sphero
% IMPORTANT!!! 
% If you had previously used a Sphero object, this object MUST be deleted 
% and cleared before you call Sphero() again!
%
% i.e.
%   delete(s);
%   clear s;
%
% If you don't do this, you'll make a whole bunch of Bluetooth objects and
% won't be able to connect another Sphero device until deleting them
% forcibly by entering a command such as delete(instrfindall)

%%
% You need to know the remote_name of your Sphero device in order to create
% a Sphero object. You can find this name by looking at the display name of
% your device in you OS (i.e. when you paired it), or use the following
% static method in the commented cod below.

% Look up available Sphero devices
% hw = Sphero.FindSpheroDevice();
% hw.RemoteNames % look at remote names
% idx = 1; % choose index of desired remote name
% remote_name = hw.RemoteNames{idx};

% Or directly specify the device name
remote_name = 'Sphero-WPP'; % Change WPP to match your device name

s = Sphero(remote_name);

% optionally configure some default behavior
% s.DEBUG_PRINT_FLAG = true; % debug output to command window when set
% s.answer_flag = true; % commands are synchronous by default when set
% s.reset_timeout_flag = true; % commands reset the command timeout by default when set 


%% Use the Sphero API functions

% Compare the Sphero API pdf to the list of available methods
methods(s);

% Use the help command for more info on API methods
help SpheroCore/Roll
help SpheroInterface/Roll

help SpheroCore/SetRGBLEDOutput

% Most of the commands have signatures simliar to the API documentation.
% The copy of this pdf provided in this release has comments to specify
% change in input parameters.

% Make Sphero red
s.SetRGBLEDOutput([1,0,0],false)

%% Move on to the other examples... (or uncomment to clean up)

% delete(s);
% clear s









