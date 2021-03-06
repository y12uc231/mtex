function ebsd = rotate(ebsd,q,varargin)
% rotate EBSD orientations or spatial data around point of origin
%
% Syntax
%
%   % roate the whoole data set about the z-axis by 90*degree
%   ebsd = rotate(ebsd,10*degree) 
%
%   % rotate about the x-axis
%   ebsd = rotate(ebsd,rotation('axis',xvector,'angle',180*degree)) 
%   
%   % roate only the spatial data
%   ebsd = rotate(ebsd,180*degree,'keepEuler') 
%
% Input
%  ebsd - @EBSD
%  angle - double
%  q    - @quaternion
%
% Flags
%  keepXY    - rotate only the orientation data, i.e. the Euler angles
%  keepEuler - rotate only the spatial data, i.e., the x,y, and z values
%
% Output
%  ebsd - @EBSD

if isa(q,'double'), q = axis2quat(zvector,q); end

% rotate the orientations
if ~check_option(varargin,'keepEuler')
  ebsd.rotations = q .* ebsd.rotations;
end

% rotate the spatial data
if ~check_option(varargin,'keepXY')
  
  if isappr(abs(dot(axis(q),zvector)),1) 
    % rotation about z
    
    omega = dot(axis(q),zvector) * angle(q);
    A = [cos(omega) -sin(omega);sin(omega) cos(omega)];
    ebsd = affinetrans(ebsd,A);
    
  elseif isappr(angle(q),pi) && isnull(dot(axis(q),zvector)) 
    % rotation perpendicular to z
    
    [x y z] = double(axis(q)); %#ok<NASGU>
    omega = atan2(y,x);
    
    A = [cos(2*omega) sin(2*omega);sin(2*omega) -cos(2*omega)];
    ebsd = affinetrans(ebsd,A);
    
  elseif ~isappr(angle(q),0)
    warning('MTEX:rotate',...
      'Spatial rotation of EBSD data is only supported for rotations about the z-axis. I''m going to rotate only the orientation data!');
  end
end
