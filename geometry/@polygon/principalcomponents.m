function [cmp v]= principalcomponents(p,varargin)
% returns the principalcomponents of grain polygon, without Holes
%
%% Input
%  p - @grain / @polygon
%
%% Output
%  cmp   - angle of components as complex
%  v     - length of axis
%
%% Options
%  HULL  - components of convex hull
%
%% See also
% polygon/hullprincipalcomponents grain/plotellipse
%

p = polygon( p );

nc = length(p);
cmp = zeros(nc,2);
v = zeros(nc,2);

hull = check_option(varargin,'hull');

if hull
  c = hullcentroid( p );
else
  c = centroid( p );
end
%without respect to Holes

pVertices = {p.Vertices};
for k=1:nc
 Vertices = pVertices{k};
 
 if hull
   Vertices = Vertices(convhull(Vertices(:,1),Vertices(:,2)),:);
 else
   Vertices(end,:) = [];
 end
 
 Vertices = Vertices - repmat(c(k,:),length(Vertices),1);  %centering
 covar = Vertices'*Vertices./(length(Vertices)-1);                         %cov                
                                  
 [u f] = eigs(covar);
 v(k,:) = diag(f)';
 cmp(k,:) = [complex(u(1,1),u(1,2)) complex(u(2,1),u(2,2))].*v(k,:);
end

