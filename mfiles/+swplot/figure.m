function hFigureOut = figure(mode)
% creates figure for crystal structure plot
%
% hFigure = SWPLOT.FIGURE({mode})
%
% The function creates an empty figure with all the controls for modifying
% the plot and the 3D roation engine that rotates the objects on the figure
% instead of the viewport. To plot anything onto the figure, the handle of
% the graphics object (after creating it using surf, patch, etc.) has to be
% added to the list using the function swplot.add.
%
% Input:
%
% mode      Optional string. If 'nohg', then no hgtransform object will be
%           used for fine object rotation. Can be usefull for certain
%           export functions, that are incompatible with hgtransform
%           objects. Default is 'hg' to use hgtransform.
%
% See also SWPLOT.ADD, HGTRANSFORM.
%

% Using code from:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2008 Andrea Tagliasacchi
% All Rights Reserved
% email: ata2 at cs dot nospam dot sfu dot ca
% $Revision: 1.0$ 10 February 2008
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% how to avoid overplotting?
% if ~isempty(get(0,'CurrentFigure'))
%     oldAxis = get(gcf,'CurrentAxes');
% end

if nargin == 0
    mode = 'hg';
end

% Create new figure.
hFigure = figure;
% show hidden child handles, such as hToolbar
showHidden = get(0,'Showhidden');
set(0,'Showhidden','on')
set(gcf,'color','w')

% create drawing axis
hAxis = axes(hFigure);

% set camera to full manual control
set(hAxis,...
    'Position',         [0 0 1 1],...
    'Color',            'none',...
    'Box',              'off',...
    'Clipping',         'off',...
    'CameraPosition',   [0 0 10000],...
    'CameraTarget',     [0 0 0],...
    'CameraUpVector',   [0 1 0],...
    'CameraViewAngle',  0.6,...
    'NextPlot',         'add',...
    'Tag',              'swaxis',...
    'XLim',             [-1 1],...
    'YLim',             [-1 1],...
    'ZLim',             [-1 1],...
    'Visible','off');

% fix 1:1 ratio for all scale
daspect([1 1 1]);
pbaspect([1 1 1]);

set(hFigure,...
    'Name',          'swplot',...
    'DockControls',  'off',...
    'PaperType',     'A4',...
    'Tag',           swpref.getpref('tag',[]),...
    'Toolbar',       'figure',...
    'DeleteFcn',     @closeSubFigs);

hToolbarT = get(hFigure,'children');

if verLessThan('matlab','8.4.0')
    hToolbar = hToolbarT(end);
else
    idx = 1;
    while ~isa(hToolbarT(idx),'matlab.ui.container.Toolbar')
        idx = idx + 1;
    end
    hToolbar = hToolbarT(idx);
end

hButton  = get(hToolbar,'children');
switch mode
    case 'hg'
        delete(hButton([1:(end-3) end-1 end]));
    case 'nohg'
        % keep the object rotation button
        delete(hButton([1:(end-9) (end-7):(end-3) end-1 end]));
end

% Loads the icon variable, that contains all the used icons.
iconPath = [sw_rootdir 'dat_files' filesep 'icons.mat'];
try
    load(iconPath,'icon');
catch err
    error('figure:FileNotFound',['Icon definition file not found: '...
        regexprep(iconPath,'\' , '\\\') '!']);
end

% Change button backgrounds to the toolbar background color using
% undocumented features
try
    drawnow;
    hToolbar = findall(gcf,'tag','FigureToolBar');
    jToolbar = get(get(hToolbar,'JavaContainer'),'ComponentPeer');
    jColor   = jToolbar.getParent.getParent.getBackground();
    bkgColor = [get(jColor,'Red') get(jColor,'Green') get(jColor,'Blue')];
    fNames   = fieldnames(icon);
    
    for ii = 1:length(fNames)
        matSel = icon.(fNames{ii})*255;
        matSelR = matSel(:,:,1);
        matSelG = matSel(:,:,2);
        matSelB = matSel(:,:,3);
        idx = (matSelR == 212) & (matSelG == 208) & (matSelB == 200);
        matSelR(idx) = bkgColor(1);
        matSelG(idx) = bkgColor(2);
        matSelB(idx) = bkgColor(3);
        matSel = cat(3,matSelR,matSelB,matSelG);
        icon.(fNames{ii}) = matSel/255;
    end
catch %#ok<CTCH>
    warning('figure:JavaSupport','Some functionality won''t work, due to Java incompatibility');
end

if strcmp(mode,'hg')
    % only works in hg mode
    button.aAxis = uipushtool(hToolbar,'CData',icon.aAxis,'TooltipString','View direction: a axis',...
        'ClickedCallback',@(i,j)swplot.view('a',hFigure),'Separator','on');
    button.bAxis = uipushtool(hToolbar,'CData',icon.bAxis,'TooltipString','View direction: b axis',...
        'ClickedCallback',@(i,j)swplot.view('b',hFigure));
    button.cAxis = uipushtool(hToolbar,'CData',icon.cAxis,'TooltipString','View direction: c axis',...
        'ClickedCallback',@(i,j)swplot.view('c',hFigure));
    button.anyAxis = uipushtool(hToolbar,'CData',icon.anyAxis,'TooltipString','Set view direction',...
        'ClickedCallback','');
end

button.zoomOut = uipushtool(hToolbar,'CData',icon.zoomOut,'TooltipString','Zoom out',...
    'ClickedCallback',@(i,j)swplot.zoom(1/sqrt(2),hFigure),'Separator','on');
button.zoomIn  = uipushtool(hToolbar,'CData',icon.zoomIn,'TooltipString','Zoom in ',...
    'ClickedCallback',@(i,j)swplot.zoom(sqrt(2),hFigure));
button.setRange = uipushtool(hToolbar,'CData',icon.setRange,'TooltipString','Set range',...
    'ClickedCallback',{@setrange hFigure},'Separator','on');
button.figActive = uipushtool(hToolbar,'CData',icon.active,'TooltipString','Keep figure',...
    'Separator','on');
button.ver = uipushtool(hToolbar,'CData',icon.ver,'TooltipString','Show SpinW version',...
    'Separator','on','ClickedCallback',{@sw_logo ''});
set(button.figActive,'ClickedCallback',{@activatefigure 'toggle'});

% zoom function
set(hFigure,'WindowScrollWheelFcn', @wheel_callback);
% activate figure
activatefigure([], [], 'initialize')

if strcmp(mode,'hg')
    % take care of fine object rotations via the mouse
    set(hFigure,'WindowButtonMotionFcn',@motion_callback);
    set(hFigure,'WindowButtonDownFcn',  @buttondown_callback);
    set(hFigure,'WindowButtonUpFcn',    @buttonup_callback);
    
    h2 = hgtransform('Parent',hAxis);
    % create hgtransform only if requested
    h = hgtransform('Parent',h2);
    mousestatus = 'buttonup';
    START = [0 0 0];
    M_previous = get(h,'Matrix');
    % add another h for translations
    % TODO
    %h2 = hgtransform('Parent',h);
    setappdata(hFigure,'h',h);
else
    h = gobjects(0,1);
    setappdata(hFigure,'h',h);
end

% save data to figure
setappdata(hFigure,'button',button);
setappdata(hFigure,'axis',hAxis);
setappdata(hFigure,'legend',struct('handle',gobjects(0),'text','','type',[],'color',[]));
setappdata(hFigure,'light',camlight('right'));
%setappdata(hFigure,'objects',struct('handle',cell(1,0)));
setappdata(hFigure,'icon',icon);
setappdata(hFigure,'base',eye(3));
swplot.zoom('auto',hFigure);
setappdata(hFigure,'tooltip',struct('handle',gobjects(0)));
swplot.tooltip('off',hFigure);
set(hFigure,'Visible','on');
% empty patch object for showing graphics with faces
hPatch = patch('Vertices',zeros(0,3),'Faces',zeros(0,3),'FaceLighting','flat',...
    'EdgeColor','none','FaceColor','flat','Tag','facepatch',...
    'FaceVertexCData',zeros(0,3),'Clipping','Off');
if ~isempty(h)
    set(hPatch,'Parent',h);
end
setappdata(hFigure,'facepatch',hPatch);
% setup the face --> object number translation table
setappdata(hPatch,'facenumber',zeros(0,1));

% empty patch object for showing graphics with edges
hPatch2 = patch('Vertices',zeros(0,3),'Faces',zeros(0,2),...
    'EdgeColor','flat','FaceColor','none','Tag','edgepatch',...
    'FaceVertexCData',zeros(0,3),'Clipping','Off');
if ~isempty(h)
    set(hPatch2,'Parent',h);
end
setappdata(hFigure,'edgepatch',hPatch2);
% setup the edge --> object number translation table
setappdata(hPatch2,'vertexnumber',zeros(0,1));

% set tooltip callback for the general object
% it is done in swplot.add
%set(hPatch,'ButtonDownFcn',@(obj,hit)swplot.tooltipcallback(obj,hit,hFigure));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2008 Andrea Tagliasacchi
% All Rights Reserved
% email: ata2 at cs dot nospam dot sfu dot ca
% $Revision: 1.0$ 10 February 2008
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% motion callback, event "every" mouse movement
    function motion_callback(src, ~)
        % retrieve the current point
        P = get(gcf,'CurrentPoint');
        % retrieve window geometry
        HGEOM = get(src, 'Position');
        % transform in sphere coordinates (3,4) = (WIDTH, HEIGHT)
        P = point_on_sphere( P, HGEOM(3), HGEOM(4) );
        
        % workaround condition (see point_on_sphere)
        if isnan(P)
            return
        end
        
        %%%%% ARCBALL COMPUTATION %%%%%
        if strcmp(mousestatus, 'buttondown')
            % compute angle and rotation axis
            rot_dir = cross( START, P ); rot_dir = rot_dir / norm( rot_dir );
            rot_ang = acos( dot( P, START ) );
            
            % convert direction in model coordinate system
            rot_dir = M_previous\[rot_dir,0]';
            rot_dir = rot_dir(1:3);
            if norm(rot_dir) > 0
                rot_dir = rot_dir / norm( rot_dir ); % renormalize
                % construct matrix
                R_matrix = makehgtform('axisrotate',rot_dir,rot_ang);
                % set hgt matrix
                set(h,'Matrix',M_previous*R_matrix);
                % refresh drawing
                drawnow;
            end
        end
    end

% only 1 event on click
    function buttondown_callback(src, ~ )
        % change status
        mousestatus = 'buttondown';
        % retrieve the current point
        P = get(gcf,'CurrentPoint');
        % retrieve window geometry
        HGEOM = get( src, 'Position');
        % SET START POSITION
        START = point_on_sphere( P, HGEOM(3), HGEOM(4) );
        % SET START MATRIX
        M_previous = get(h, 'Matrix');
    end

    function buttonup_callback(~, ~ )
        % change status
        mousestatus = 'buttonup';
        % reset the start position
        START = [0,0,0];
    end

%%%%%%%%%%%% UTILITY FUNCTION %%%%%%%%%%%%%
    function P = point_on_sphere( P, width, height )
        P(3) = 0;
        
        % determine radius of the sphere
        R = min(width, height)/2;
        
        % TRANSFORM the point in window coordinate into
        % the coordinate of a sphere centered in middle window
        ORIGIN = [width/2, height/2, 0];
        P = P - ORIGIN;
        
        % normalize position to [-1:1] WRT unit sphere
        % centered at the origin of the window
        P = P / R;
        
        % if position is out of sphere, normalize it to
        % unit length
        L = sqrt( P*P' );
        if L > 1
            % P = nan; % workaround to stop evaluation
            % disp('out of sphere');
            
            P = P / L;
            P(3) = 0;
        else
            % add the Z coordinate to the scheme
            P(3) = sqrt( 1 - P(1)^2 - P(2)^2 );
        end
    end

%%END OF FUNCTION%%

if nargout > 0
    hFigureOut = hFigure;
end

% restore showHidden property
set(0,'Showhidden',showHidden);

% TODO how to avoid overplotting
% if ~isempty(oldAxis)
%     % make old axis active to avoid overplotting
%     axes(oldAxis);
% end

    function wheel_callback(~, event)
        % zoom in/out for event
        cva = get(hAxis,'CameraViewAngle');
        set(hAxis,'CameraViewAngle',cva*1.02^(event.VerticalScrollCount));
        
    end

    function activatefigure(~,~,mode)
        % activate/deactivate figure
        %
        % mode = initialize/toggle
        %
        
        inact = 'inactive_';
        
        fTag = get(hFigure,'tag');
        
        switch mode
            case 'initialize'
                fTag = [inact fTag];
            case 'toggle'
        end
        
        
        if ~isempty(strfind(fTag,inact)) || strcmp(mode,'initialize')
            % activate figure
            newTag = fTag((numel(inact)+1):end);
            set(hFigure,'tag',newTag);
            set(button.figActive,'CData',icon.active);
            hList = findobj('Tag',newTag);
            hList(hList==hFigure) = [];
            % The handle of the activate button is Figure.Child(end).Child(1).
            for jj = 1:numel(hList)
                bt = getappdata(hList(jj),'button');
                set(bt.figActive,'CData',icon.inactive);
                set(hList(jj),'Tag',[inact newTag]);
            end
            
        else
            % inactivate figure
            set(hFigure,'tag',[inact fTag]);
            set(button.figActive,'CData',icon.inactive);
        end
        
        
    end

    function closeSubFigs(~, ~)
        % close all sub figures on plot window closing
        
        % close the "Set Range" window if it is open
        if verLessThan('matlab','8.4.0')
            sub1 = findobj('Tag',['setRange_' num2str(hFigure)]);
        else
            sub1 = findobj('Tag',['setRange_' num2str(hFigure.Number)]);
        end
        
        if ~isempty(sub1)
            close(sub1);
        end
        
        % delete spinw object
        %delete(getappdata(hFigure,'objects'));
        % delete figure
        delete(hFigure);
        
    end



end

function setrange(~, ~, hFigure)
% setrange() changes the plotting range

% if there is no crystal, don't do anything
if isempty(getappdata(hFigure,'obj'))
    return
end

param     = getappdata(hFigure,'param');
parentPos = get(hFigure,'Position');
fWidth    = 195;
fHeight   = 240;

% Figure number
if verLessThan('matlab','8.4.0')
    figNum = hFigure;
else
    figNum = hFigure.Number;
end

%    'WindowStyle',    'modal',...
objMod = findobj('Tag',['setRange_' num2str(figNum)]);

if ~isempty(objMod)
    close(objMod)
    return
end

objMod = figure(...
    'Units',          'pixel',...
    'Position',       [parentPos(1)+150 parentPos(2)+parentPos(4)-300 fWidth fHeight],...
    'Name',           'Plot range',...
    'NumberTitle',    'off',...
    'DockControls',   'off',...
    'Tag',            ['setRange_' num2str(figNum)],...
    'MenuBar',        'none',...
    'Toolbar',        'none',...
    'Resize',         'off',...
    'Visible',        'on');

handles.objMod = objMod;
handles.panel(1) = uipanel(objMod,...
    'Position',       [0 0 1 1],...
    'BorderType',     'none');
handles.checkbox_ud = uicontrol(handles.panel(1),...
    'Style',           'CheckBox',...
    'Units',           'pixel',...
    'String',          'Live Update',...
    'Enable',          'Off',...
    'Position',        [3 5 80 15]);
handles.text(1) = uicontrol(handles.panel(1),...
    'Style',           'text',...
    'String',          'Atoms in range:',...
    'Units',           'pixel',...
    'Position',        [3 30 80 15]);
handles.text(2) = uicontrol(handles.panel(1),...
    'Style',           'edit',...
    'String',          '30',...
    'Enable',          'off',...
    'Units',           'pixel',...
    'Position',        [110 30 60 15]);
handles.panel(2) = uipanel(objMod,...
    'Units',            'pixel',...
    'Title',            'Full XYZ Range',...
    'Position',         [1 50 fWidth 80]);
handles.panel(3) = uipanel(objMod,...
    'Units',            'pixel',...
    'Title',            'Axial Range Limits',...
    'Position',         [1 131 fWidth 109]);
handles.text(3) = uicontrol(handles.panel(3),...
    'Style',           'text',...
    'String',          'z:',...
    'Units',           'pixel',...
    'Position',        [5 5 20 15]);
handles.text(4) = uicontrol(handles.panel(3),...
    'Style',           'text',...
    'String',          'y:',...
    'Units',           'pixel',...
    'Position',        [5 30 20 15]);
handles.text(5) = uicontrol(handles.panel(3),...
    'Style',           'text',...
    'String',          'x:',...
    'Units',           'pixel',...
    'Position',        [5 55 20 15]);
handles.edit_range(1,1) = uicontrol(handles.panel(3),...
    'Style',     'edit',...
    'BackgroundColor',[1 1 1],...
    'Position',  [30 56 70 20]);
handles.edit_range(1,2) = uicontrol(handles.panel(3),...
    'Style',     'edit',...
    'BackgroundColor',[1 1 1],...
    'Position',  [105 56 70 20]);
handles.edit_range(2,1) = uicontrol(handles.panel(3),...
    'Style',     'edit',...
    'BackgroundColor',[1 1 1],...
    'Position',  [30 31 70 20]);
handles.edit_range(2,2) = uicontrol(handles.panel(3),...
    'Style',     'edit',...
    'BackgroundColor',[1 1 1],...
    'Position',  [105 31 70 20]);
handles.edit_range(3,1) = uicontrol(handles.panel(3),...
    'Style',     'edit',...
    'BackgroundColor',[1 1 1],...
    'Position',  [30 6 70 20]);
handles.edit_range(3,2) = uicontrol(handles.panel(3),...
    'Style',     'edit',...
    'BackgroundColor',[1 1 1],...
    'Position',  [105 6 70 20]);
handles.pushbutton_expand = uicontrol(handles.panel(2),...
    'Style',           'pushbutton',...
    'Units',           'pixel',...
    'String',          'Expand',...
    'Position',        [fWidth/2-40 44 80 20],...
    'Callback',         {@Callback_Scale hFigure objMod 1});
handles.pushbutton_contract = uicontrol(handles.panel(2),...
    'Style',           'pushbutton',...
    'Units',           'pixel',...
    'String',          'Contract',...
    'Position',        [fWidth/2-40 24 80 20],...
    'Callback',         {@Callback_Scale hFigure objMod 0});
handles.pushbutton_singlecell = uicontrol(handles.panel(2),...
    'Style',           'pushbutton',...
    'Units',           'pixel',...
    'String',          'Single Cell',...
    'Position',        [fWidth/2-40 4 80 20],...
    'Callback',         {@Callback_Single objMod});
handles.pushbutton_apply = uicontrol(handles.panel(1),...
    'Style',           'pushbutton',...
    'Units',           'pixel',...
    'String',          'Apply',...
    'Position',        [90 3 50 20],...
    'Callback',        {@Callback_Range hFigure objMod 0});
handles.pushbutton_ok = uicontrol(handles.panel(1),...
    'Style',           'pushbutton',...
    'Units',           'pixel',...
    'String',          'OK',...
    'Position',        [140 3 50 20],...
    'Callback',        {@Callback_Range hFigure objMod 1});

for ii=1:3
    for jj=1:2
        set(handles.edit_range(ii,jj),'String',sprintf('%.3f',param.range(ii,jj)));
    end
end

handles.text(6) = uicontrol(handles.panel(3),...
    'Style',           'text',...
    'String',          'Minimum',...
    'Units',           'pixel',...
    'Position',        [37 77 50 15]);
handles.text(7) = uicontrol(handles.panel(3),...
    'Style',           'text',...
    'String',          'Maximum',...
    'Units',           'pixel',...
    'Position',        [110 77 50 15]);

setappdata(objMod,'handles',handles);

    function Callback_Range(~, ~, hFigure, objMod , isclose)
        
        param   = getappdata(hFigure,'param');
        obj     = getappdata(hFigure,'obj');
        handles = getappdata(objMod,'handles');
        
        
        for iii=1:3
            for jjj=1:2
                param.range(iii,jjj) = str2double(get(handles.edit_range(iii,jjj),'String'));
            end
        end
        
        if all((param.range(:,1) - param.range(:,2)) < 0)
            param.hFigure = hFigure;
            plot(obj, param);
            figure(objMod);
        end
        
        % Okay button closes the settings window
        if isclose
            delete(handles.objMod);
        end
    end

    function Callback_Single(~, ~, objMod)
        
        handles = getappdata(objMod,'handles');
        for iii=1:3
            set(handles.edit_range(iii,1),'String', '0.000');
            set(handles.edit_range(iii,2),'String', '1.000');
        end
    end

    function Callback_Scale(~, ~, hFigure, ~, expand)
        
        obj     = getappdata(hFigure,'obj');
        lattice = obj.lattice;
        abc     = lattice.lat_const;
        d       = 0.1 * min(abc)./abc;
        
        range = zeros(3,2);
        for iii=1:3
            for jjj=1:2
                range(iii,jjj) = str2double(get(handles.edit_range(iii,jjj),'String'));
            end
        end
        
        if ~expand
            d = -d;
        end
        range(:,1) = range(:,1) - d';
        range(:,2) = range(:,2) + d';
        
        
        for iii=1:3
            for jjj=1:2
                set(handles.edit_range(iii,jjj),'String',sprintf('%6.3f',range(iii,jjj)));
            end
        end
        
        
    end
end