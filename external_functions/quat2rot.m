function R = quat2rot(quat,type)
% type should be a string 'vs' or 'sv' specifying the order of the
% quaternion's scalar and vector parts. The default is 'sv' and all
% calculations are performed with this convention.

if nargin < 2, type = 'sv'; end

if ~any([strcmp(type,'sv'),strcmp(type,'vs')])
  error('Input type must be a string sv or vs.');
end

if ~any(size(quat)==4)
  error('quaternions must have 4 elements');
elseif size(quat,1) ~= 4
  quat = quat';
end

N = size(quat,2);

R = zeros(3,3,N);

for nn = 1:N
  R(:,:,nn) = q2r(quat(:,nn),type);
end

end

function R = q2r(q,type)

if strcmp(type,'sv')
  s = q(1);
  v = q(2:4);
else
  v = q(1:3);
  s = q(4);
end

R = eye(3) + 2*v*v' - 2*v'*v*eye(3) + 2*s*skew(v);
end