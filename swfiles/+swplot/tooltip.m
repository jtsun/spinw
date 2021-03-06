function varargout = tooltip(text0,hFigure,win)
% creates tooltip axis on swplot figure
%
% SWPLOT.TOOLTIP({text}, {hFigure}, {window})
%
% status = SWPLOT.TOOLTIP
%
% Input:
%
% text          String, if it is 'on'/'off' the tooltip will be switched
%               on/off. Otherwise the text will be shown in the tooltip.
%               Default is 'on'.
% hFigure       Handle of the swplot figure. Default is the selected
%               figure.
% window        If true, the tooltips will be shown in a separate window.
%               Default is false.
%
% Output:
%
% status        String, can be 'on' or 'off'.
%
% Example:
%   swplot.figure
%   swplot.addcircle([0 0 0],[0 0 1],1)
%   swplot.tooltip
%

if nargin == 0
    text0 = 'on';
end

fontSize = swpref.getpref('fontsize',[]);

if nargin < 2 || isempty(hFigure)
    % find active figure
    hFigure = swplot.activefigure;
end

if nargin < 3
    win = [];
end

tDat = getappdata(hFigure,'tooltip');

if ~isempty(tDat.handle) && ~ishandle(tDat.handle(1))
    tDat.handle = gobjects(1,0);
end

% just get status
if nargout > 0
    if isempty(tDat.handle)
        varargout{1} = 'off';
    else
        varargout{1} = get(tDat.handle(2),'Visible');
    end
    return
end

if isempty(win)
    % create separate window
    win = false;
end

if win
    % Figure number
    if verLessThan('matlab','8.4.0')
        figNum = hFigure;
    else
        figNum = hFigure.Number;
    end

    delete(tDat.handle)
    tDat.handle = gobjects(1,0);
    pos0 = get(hFigure,'Position');
    tFigure = figure(...
        'Name',         'swplot.tooltip',...
        'DockControls', 'off',...
        'Tag',          ['tooltipfig_' num2str(figNum)],...
        'Toolbar',      'none',...
        'Position',     [pos0(1)+pos0(3)+5 pos0(2)+pos0(4)-350 250 350],...   
        'Menubar',      'none');
    tDat.handle(3) = tFigure;
else
    tFigure = hFigure;
end

if isempty(tDat.handle) || win
    % create tooltip axis
    tDat.handle(1) = axes('Parent',tFigure,'Units','Normalized','Position',[0.01 0.9 0.1 0.2],'Visible','off','tag','swtooltip');
    tDat.handle(2) = text(0.05,0.45,'','units','normalized','horizontalalignment','left',...
        'FontSize',fontSize,'VerticalAlignment','top','Parent',tDat.handle(1));
    % avoid object get active for strange zooming effect
    set(tDat.handle(1:2),'hittest','off','tag','tooltip');
    
    % switch to plot axis where all 3D objects are
    axes(getappdata(hFigure,'axis'));
    
    % save new handles
    setappdata(hFigure,'tooltip',tDat);
end

switch text0
    case 'on'
        if strcmp(get(tDat.handle(2),'Visible'),'off')
            set(tDat.handle(2),'String','');
        end
        
        set(tDat.handle(2:end),'Visible','on');
        % register callbacks
        obj = getappdata(hFigure,'objects');
        if ~isempty(obj)
            h   = getappdata(hFigure,'h');
            set(unique([obj(:).handle]),'ButtonDownFcn',@(obj,hit)swplot.tooltipcallback(obj,hit,hFigure,h));
        end
    case 'off'
        set(tDat.handle(2:end),'Visible','off');
        % remove callbacks
        obj = getappdata(hFigure,'objects');
        if ~isempty(obj)
            set(unique([obj(:).handle]),'ButtonDownFcn',[]);
        end
    otherwise
        set(tDat.handle(2),'String',text0);
end

end