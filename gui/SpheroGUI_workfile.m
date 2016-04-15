%% SpheroGUI_workfile

if exist('s','var') && isa(s,'Sphero')
  delete(s);
  clear s
end

clear all; close all; clc;

%%


s = Sphero

s.ConnectDevice()

%%




