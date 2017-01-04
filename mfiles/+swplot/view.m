function view(ax)
% control 3D view of swplot
%
% SWPLOT.VIEW(ax)
%
% Input:
%
% ax        String to change view, options:
%               'a','b','c'     axis normal to view plane


% find active figure
hFigure = swplot.activefigure;

% hgtransform object
h = getappdata(hFigure,'h');

bv = getappdata(hFigure,'base');

if any(ax>'c')
    % for hkl
    bv = inv(bv)'*2*pi;
end

bvN = bsxfun(@rdivide,bv,sqrt(sum(bv.^2,1)));

x = bvN(:,1);
y = bvN(:,2);
z = bvN(:,3);

cc(1) = y'*z;
cc(2) = x'*z;
cc(3) = x'*y;

switch ax
    case {'ab' 'c' 'hk' 'l'}
        % ab
        xp = [1;0;0];
        yp = [cc(3);sqrt(1-cc(3)^2);0];
        zp = [cc(2);(cc(1)-yp(1)*cc(2))/yp(2)];
        zp(3) = sqrt(1-sum(zp.^2));
        zp(3) = sign(cross(xp,yp)'*zp)*zp(3);
    case {'bc' 'a' 'kl' 'h'}
        % bc
        yp = [1;0;0];
        zp = [cc(1);sqrt(1-cc(1)^2);0];
        xp = [cc(3);(cc(2)-zp(1)*cc(3))/zp(2)];
        xp(3) = sqrt(1-sum(xp.^2));
        xp(3) = sign(cross(xp,yp)'*zp)*xp(3);
    case {'ac' 'b' 'hl' 'k'}
        % ac
        xp = [1;0;0];
        zp = [cc(2);sqrt(1-cc(2)^2);0];
        yp = [cc(3);(cc(1)-zp(1)*cc(3))/zp(2)];
        yp(3) = sqrt(1-sum(yp.^2));
        yp(3) = sign(cross(xp,yp)'*zp)*yp(3);
    otherwise
        error('view:WrongInput','Wrong input!')
end

h.Matrix(1:3,1:3) = [xp yp zp]/bvN;

end