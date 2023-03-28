function levelPoints = vertsAtZIndex(X,Y,Z,F,ZIndex,x_max,y_max)
%vertsAtZIndex Returns vertices at a certain Z index
%   Detailed explanation goes here
    levelX = X(:,:,ZIndex);
    levelY = Y(:,:,ZIndex);
    levelZ = Z(:,:,ZIndex);
    idx = F(:,:,ZIndex) >= 0;
    levelPoints = [levelX(idx) levelY(idx) levelZ(idx)];
    levelPoints = levelPoints(levelPoints(:,1)>0,:);
    levelPoints = levelPoints(levelPoints(:,1)<x_max,:);
    levelPoints = levelPoints(levelPoints(:,2)>0,:);
    levelPoints = levelPoints(levelPoints(:,2)<y_max,:);
end