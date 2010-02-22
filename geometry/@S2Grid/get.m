function value = get(obj,vname)
% get object variable

switch vname
  case {'resolution','res'}
    value = obj.res;
  case fields(obj)
    value = [obj.(vname)];
  otherwise
    error('Unknown field in class S2Grid!')
end

