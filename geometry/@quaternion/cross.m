function q = cross(q1, q2, q3)
% pointwise cross product of three quaternions
%
%% Input
%  q1,q2,q3 - @quaternion
%
%% Output
%  @quaternion
%

[a1,b1,c1,d1] = double(q1);
[a2,b2,c2,d2] = double(q2);
[a3,b3,c3,d3] = double(q3);

% Calculate cross product
q = q1;
q.a = b1.*c2.*d3 - b1.*c3.*d2 - b2.*c1.*d3 + b2.*c3.*d1 + b3.*c1.*d2 - b3.*c2.*d1;
q.b = a1.*c3.*d2 - a1.*c2.*d3 + a2.*c1.*d3 - a2.*c3.*d1 - a3.*c1.*d2 + a3.*c2.*d1;
q.c = a1.*b2.*d3 - a1.*b3.*d2 - a2.*b1.*d3 + a2.*b3.*d1 + a3.*b1.*d2 - a3.*b2.*d1;
q.d = a1.*b3.*c2 - a1.*b2.*c3 + a2.*b1.*c3 - a2.*b3.*c1 - a3.*b1.*c2 + a3.*b2.*c1;

