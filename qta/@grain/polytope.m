function p = polytope(grains,varargin)
% returns the polygon of grains as struct
%
%% Input
%  grains - @grain
%
%% Output
%  p    - @polygon
%
% p = grains.polygon;

n = numel(grains);
parts = [0:500:n-1 n];  % faster as at once
% 
p = cell(1,numel(parts)-1);
for k=1:numel(parts)-1  
	p{k} = horzcat(grains(parts(k)+1:parts(k+1)).polytope);
end
p = horzcat(p{:});

if ispolygon(p)
  p = polygon(p);
elseif ispolyeder(p)
  p = polyeder(p);
end