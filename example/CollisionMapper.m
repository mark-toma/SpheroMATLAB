function CollisionMapper(s,action)

if (nargin < 1) || ~isa(s,'Sphero')
  error('Invalid input');
end
if nargin < 2
  action = 'start';
end

switch action
  
  case 'start'
    
    hgfx.hf = figure;
    hgfx.ha = axes('nextplot','add');
    axis equal;
    hgfx.traj = plot(0,0,':k');
    hgfx.robot = plot(0,0,'ok','linewidth',2);
    hgfx.obs = plot(0,0,'xm','linewidth',4,'visible','off');    
    
    s.OnNewCollisionDetectedFcn = @(src,evt)collisionCallback(src,evt,hgfx);
    s.OnNewDataStreamingFcn = @(src,evt)dataStreamingCallback(src,evt,hgfx);  
    
    
    if s.SetDataStreaming(10,1,0,{'odo'})
      error('Set data streaming FAIL');
    end
    if s.ConfigureCollisionDetection('one',0.5*[1,1],0.3*[1,1],0.5)
      error('Configure collision detection FAIL.');
    end
        
    % create timer
    tmr = timer(...
      'executionmode','fixedrate',...
      'period',0.1,...
      'timerfcn',@(src,evt)timerCallback(src,evt,s),...
      'name','collision_mapper',...
      'startdelay',2);
    ud.timer = tmr;
    
    ud.IDLE_TIME = 2; % seconds to remain in idle state
    ud.DRIVE_TIME = 10; % max seconds to remain in drive state
    ud.SPEED = 0.5; % speed in fractional units
    ud.hgfx = hgfx;
    ud.heading = 0;
    ud.state = 'idle';
    ud.transition_time = s.time_since_init;
    
    ud.coll_pts = [];
    
    s.userdata = ud;
    
    start(tmr);
    
  case 'stop'
    stop(s.userdata.timer);
    delete(s.userdata.timer);
    delete(s.userdata.hgfx);
  otherwise
    error('bad action');
    
end

end

function timerCallback(tmr,evt,s)
% main program loop


ud = s.userdata;
%fprintf('TIMERFCN\n');

% run state machine
% idle => drive
switch ud.state
  case 'drive'
    %fprintf('DRIVE\n');
    % send roll command
    s.RollWithOffset(ud.SPEED,ud.heading,[],[],false);
    
    % by default, we exit this state in the collision callback
    % in the event of a collision, sphero is stopped and sphero transitions
    % to idle state
    
    % or if we timeout, we do the same here.
    
    if (s.time_since_init - ud.transition_time) > ud.DRIVE_TIME
      s.RollWithOffset(0,ud.heading,[],[],false); % stay still
      ud.transition_time = s.time_since_init;
      ud.state = 'idle';
      fprintf('DRIVE >> IDLE\n')
    end
    
    
  case 'idle'
    
    s.RollWithOffset(0,ud.heading,[],[],false); % stay still
    
    if (s.time_since_init - ud.transition_time) > ud.IDLE_TIME
      fprintf('IDLE >> DRIVE\n');
      ud.heading = randi([0,359]); % new random heading
      ud.state = 'drive';
    end
    
end

s.userdata = ud;

end

function dataStreamingCallback(s,evt,hgfx)

% update traj and robot
p = s.odo_log;
x = p(1,:);
y = p(2,:);
set(hgfx.traj,'xdata',x,'ydata',y);
set(hgfx.robot,'xdata',x(end),'ydata',y(end));

% update axes limits
set(hgfx.ax,'xlim',[min(x),max(x)],'ylim',[min(y),max(y)]);
drawnow;

end

function collisionCallback(s,evt,hgfx)
%
fprintf('COLLISION >> IDLE\n');

ud = s.userdata;

% if a collision is detected, stop, save collision info, and change state
% to idle

s.RollWithOffset(0,ud.heading,[],[],false); % stay still
ud.transition_time = s.time_since_init;
ud.state = 'idle';

p = s.odo;
x = p(1)
y = p(2)

ud.coll_pts

if isempty(ud.coll_pts)
  set(hgfx.obs,'xdata',x,'ydata',y);
  set(hgfx.obs,'visible','on');
else
  set(hgfx.obs,...
    'xdata',[ud.coll_pts(1,:),x],...
    'ydata',[ud.coll_pts(2,:),y]);  
end

ud.coll_pts = [ud.coll_pts,p]

s.userdata = ud;

end



