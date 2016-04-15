function myQuatCallback(src,evt,hx)
%MYQUATCALLBACK Updates hgtransform hx with quaterion from src (Sphero)

% get body quat
quat = src.quat;

% conjugate to get global quat
quat = quat .* [1;-1;-1;-1];

R = quat2rot(quat,'sv');

% homogeneous transform
H = [R,[0;0;0];[0,0,0,1]];
% disp(H)
set(hx,'matrix',H);

drawnow;

end

