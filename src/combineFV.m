function [fn,vn] = combineFV(f1,v1,f2,v2)
%COMBINE combines a pair of faces and vertices
%   Detailed explanation goes here      
    fn = [f1 ; f2+length(v1(:,1))];      
    vn = [v1 ; v2];
    
    [vn, ~, map] = unique(vn, 'rows', 'stable');
    for i = 1:numel(fn)
      fn(i) = map(fn(i));
    end
    
end
