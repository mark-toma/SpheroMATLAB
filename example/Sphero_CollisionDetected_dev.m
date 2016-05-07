%% Sphero_CollisionDetected_dev


% s.DEBUG_PRINT_FLAG = true;

s.DEBUG_PRINT_FLAG = false;

meth = 'one';
thresh = 0.5*[1,1];
spd = 0.3*[1,1];
dead = 0.5;

s.NewCollisionDetectedFcn = @(src,evt)myCollisionDetectionCallback(src,evt);

s.ConfigureCollisionDetection(meth,thresh,spd,dead)

%% Turn collision detection off
s.ConfigureCollisionDetection('off',thresh,spd,dead)








