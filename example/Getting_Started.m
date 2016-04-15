%% Getting_Started.m
% In this script, we'll discuss the basics for using the Sphero object.

%% Prerequisites
% Before getting started, take a look at the readme.txt in the root
% directory of this release.

%% Instantiate Sphero
% IMPORTANT!!!
% This object MUST be deleted and cleared before you call Sphero() again!
%
% i.e.
%   delete(s);
%   clear s;
%
% If you don't do this, you'll make a whole bunch of Bluetooth objects and
% won't be able to connect another Sphero device until deleting them
% forcibly by entering a command such as delete(instrfindall)

s = Sphero();

% optionally configure some default behavior
s.DEBUG_PRINT_FLAG = true; % debug output to command window when set
% s.answer_flag = true; % commands are synchronous by default when set
% s.reset_timeout_flag = true; % commands reset the command timeout by default when set 

%% Connect to Sphero

% You can uncomment the next two lines and comment s.ConnectDevice() if you
% know your device's remote name. Look for Sphero's display name in the OS
% or inspect the output of s.FindSpheroDevice() for this information.

% remote_name = 'Sphero-XXX'; % as displayed in your OS -- Mine are 'Sphero-OOR' and 'Sphero-WPP' 
% s.ConnectDevice(remote_name); % connection is quicker with remote_name

% this takes some time...
s.ConnectDevice(); % looks up and connects to a device containing 'Sphero' its name

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
s.SetRGBLEDOutput([1,0,0])

%% Move on to the other examples... (or uncomment to clean up)

% delete(s);
% clear s









