%% RollToPoint.m
% Instantiate Sphero as variable s before running this script
% This script commands Sphero to Roll to a given point in the plane at a
% constant speed.

%% Parameters

% desired points sequence

% rectangle
% L = 100; W = 100;
% Pd = [0,-W,-W,0;L,L,0,0];

% circle
radius = 80;
Pd = [radius*cosd(0:30:360)-radius;radius*sind(0:30:360)];

SPEED = 0.15; % constant speed for Sphero

ERROR_THRESHOLD = 20;

%% Orient Sphero's coordinates

s.SetBackLEDOutput(1); % turn on back led
offset = 0;
while ~isempty(offset)
  offset = input('Enter heading offset in degrees or [ENTER] to continue: ');
  if isempty(offset) || ~isnumeric(offset), continue; end
  s.heading_offset = offset;
  s.RollWithOffset(0,0);
end
s.SetBackLEDOutput(0); % turn off back led


%% Turn on streaming data for odometer

if s.SetDataStreaming(10,1,0,{'odo'})
  error('Turn on data stream: FAIL');
end


%%


s.ConfigureLocatorWithOffset(0,0); % make sphero's current location (0,0)
s.ClearLogs();

% issue roll commands with updated heading based upon current position
curr_point = 1;
while 1
  p = s.odo; pd = Pd(:,curr_point);
  pe = pd - p;
  theta = atan2(pe(2),pe(1))*180/pi - 90;
  d = norm(pe,2);
  
  fprintf('%+1d %+5d %+5d %+5d %+5d %+5d %+5d\n',...
    curr_point,p(1),p(2),pe(1),pe(2),round(d),round(theta));
  
  if d < ERROR_THRESHOLD
    % move to next point
    curr_point = curr_point + 1;
    if curr_point > size(Pd,2), break; end
    continue;
  end
  
  s.RollWithOffset(SPEED,theta);  
  
  pause(0.1); % update roughly 10Hz 
end

s.RollWithOffset(0,0);

if s.SetDataStreaming(10,1,1,{'odo'})
  error('Turn off data stream: FAIL');
end

figure;
plot(s.odo_log(1,:),s.odo_log(2,:),'-b',Pd(1,:),Pd(2,:),'or');
legend('odometry','points');
axis equal


