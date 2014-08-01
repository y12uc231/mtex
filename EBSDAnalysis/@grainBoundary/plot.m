function h = plot(gB,varargin)
% plot grain boundaries
%
% The function plots grain boundaries where the boundary is determined by
% the function <GrainSet.specialBoundary.html specialBoundary>
%
% Input
%  grains  - @grainBoundary
%  
% Options
%  property - colorize a special grain boundary property, variants are:
%
%    * |'phase'| -- boundaries between different phases
%
%    * |'phaseTransition'|  -- colorize boundaries according to phase change
%                   (same phase, different phase).
%    * |'angle'| -- misorientation angle between two neighboured ebsd
%            measurements on the boundary.
%    * |'misorientation'| -- calculate the misorientation on the grain boundary
%            between two ebsd measurements and [[orientation2color.html,colorize]]
%            it after a choosen colorcoding, i.e.
%
%            plot(grains,'property','misorientation',...
%              'colorcoding','ipdfHSV')
%
%    *  @quaternion | @rotation | @orientation -- plot grain boundaries with
%            a specified misorientation
%
%            plot(grains,'property',...
%               rotation('axis',zvector,'angle',60*degree))
%
%    *  @Miller | @vector3d -- plot grain boundaries such as specified
%            crystallographic face are parallel. use with option 'delta'
%
%  delta - specify a searching radius for special grain boundary
%            (default 5 degrees), if a orientation or crystallographic face
%            is specified.
%  
%  linecolor|edgecolor|facecolor - color of the boundary
%
%  linewidth - width of the line
%
% Flags
% internal - only plot boundaries within a grain which do not match the grain boundary
%         criterion
% external - only plot grain--boundaries to other grains.
%
% See also
% GrainSet/specialBoundary

% create a new plot
mP = newMapPlot(varargin{:});

obj.Faces    = gB.F;
obj.Vertices = gB.V;
obj.parent = mP.ax;
obj.FaceColor = 'none';

% color given by second argument
if nargin > 1 && isnumeric(varargin{1}) && size(varargin{1},1) == length(gB)

  obj.Faces(:,3) = size(obj.Vertices,1)+1;
  obj.Vertices(end+1,:) = NaN;
  obj.Vertices = obj.Vertices(obj.Faces',:);
  obj.Faces = 1:size(obj.Vertices,1);
  obj.EdgeColor = 'flat';
  obj.FaceVertexCData = varargin{1};

else % color given directly
    
  obj.EdgeColor = get_option(varargin,{'linecolor','edgecolor','facecolor'},'k');
  
end

h = optiondraw(patch(obj),varargin{:});
xlabel('x');ylabel('y');

if nargout == 0, clear h; end