function [ output_args ] = rollTrajTrackCallback(src,evt,param)
%ROLLTRAJTRACKCALLBACK Issues Roll command from odo and user defined traj
%   Detailed explanation goes here

% current trajectory time (duration since streaming data was turned on)
tvec = src.time_log;
tt = tvec(end)-tvec(1);
fprintf('tt = %10f\n',tt);

% desired position
Xd = param.func(tt);
fprintf('Xd = [ %10f , %10f ]\n',Xd(1),Xd(2));

% actual position
X = src.odo;
fprintf('X = [ %10f , %10f ]\n',X(1),X(2));


% position error
Xe = Xd-X;
fprintf('Xe = [ %10f , %10f ]\n',Xe(1),Xe(2));

de = norm(Xe,2); % distance error
fprintf('de = %10f\n',de);


% compute speed and heading and send command
heading = atan2(Xe(2),Xe(1))*180/pi - 90;
speed = param.pgain*de;
speed(speed>param.max_speed) = param.max_speed;

fprintf('speed = %10f heading = %10f\n',speed,heading);

% must set answer_flag (input parameter 5) false!
% if default answer_flag is true and this is not set false, the event queue
% filla up and matlab hangs
src.RollWithOffset(speed,heading,[],[],false);

fprintf('done\n');
end

