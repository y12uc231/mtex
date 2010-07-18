function frame_wizard(varargin)
% 

%%

hw = 520;
rw = 265;
h = import_gui_empty('width',800,'height',hw+60,'name','Frame to PoleFigure'); %,varargin{:}
iconMTEX(h);


set(h,'WindowButtonDownFcn',{@eva,true});
set(h,'WindowButtonUpFcn',{@eva,false});


A = zeros(512);
A(1,1)=1;

handles.img = image(A,'CDataMapping','scaled');
handles.ax(1) = get(handles.img,'parent');

ma = makeColorMap([0,0,0],1,[0.45 0 0],32,[0.9 0 0],64,[0.95 0.7 0],160,[1 1 1]);
colormap(ma)



set(handles.ax(1),'Unit','pixels',...
  'Position',[800-512-10 10 512 512],...
  'color',[0 0 0],'XTick',[],'YTick',[]);

axis equal


handles.dir = '';

handles.folder = uicontrol('style','edit',...
  'HorizontalAlignment','left',...
  'position',[10 hw+25 rw-100 20]);
uicontrol('String','Project Folder',...
  'position',[rw-80 hw+25 80 22],...
  'Callback', @set_project_dir);

dat =  {};
columnname =   {'', 'Run'};
columnformat = { 'logical','bank'};
columneditable =  [true false ]; 
handles.runt = uitable('Units','pixels','Position',...
            [10 hw-80 rw-10 80], 'Data', dat,... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',{25,210},...
            'RowName',[],'CellEditCallback',@set_run);



% 
% handles.frames = uicontrol('style','listbox',...
%   'String','',...
%   'position',[10 hw-190 rw-10 100],...
%   'Callback',@display_frame)


handles.frames = uitable('Units','pixels','Position',...
            [10 hw-190 rw-10 100], ... 
            'ColumnName', {'Frame'},...
            'ColumnEditable', false,...
            'ColumnWidth',{235},...
            'RowName',[],'CellSelectionCallback',@display_frame);


%%

handles.tabpane = uitabpanel(...
  'Parent',h,...
  'TabPosition','lefttop',...
  'units','pixel',...
  'position',[10 hw-460 rw-8 260],...
  'Margins',{[2,2,2,2],'pixels'},...
  'PanelBorderType','beveledout',...
  'Title',{'Current Frame','2Theta','Settings'},... %,'Background','Defocussing','Defocussing BG'},...
  'FrameBackgroundColor',get(gcf,'color'),...
  'PanelBackgroundColor',get(gcf,'color'),...
  'TitleForegroundColor',[0,0,0],...
  'selectedItem',1);

% tabs = getappdata(handles.tabpane,'panels');

handles = create_tab_current_frame(handles);
handles = create_tab_2theta(handles);
  


          %%

uicontrol('style','pushbutton',...
  'String','Process',...
  'FontWeight','bold',...
  'position',[rw-80 10 80 30],...
  'callback',@process_data)
%%

setappdata(gcf,'handles',handles);



function set_project_dir(a,b)

folder = uigetdir;

if isnumeric(folder)
  return
end

handles = getappdata(gcf,'handles');
set(handles.folder,'String',folder);

files = dir(fullfile(folder,'*.gfrm'));
files = {files.name};

filier = regexp(files,'(?<name>\w*)_(?<runner>([0-9]*))_(?<frameno>([0-9]*)).gfrm','names');

filier = [filier{:}];

for k=1:numel(files)
  filier(k).file = files{k};
  filier(k).run = regexprep(files{k},'(\w*)_([0-9]*)_([0-9]*).gfrm','$1_$2');
end

setappdata(gcf,'folder',folder);
setappdata(gcf,'fileinfo',filier);

filier = getappdata(gcf,'fileinfo');

[runs a b]= unique({filier.run});

runst(:,2) = {filier(a).run};
runst(:,1) = {false};

set(handles.runt,'Data',runst);


function set_run(ev,fe)

% getappdata(gcf,'folder',folder);
handles = getappdata(gcf,'handles');
filier = getappdata(gcf,'fileinfo');
[runs a b]= unique({filier.run});

data = get(handles.runt,'Data');

sel = vertcat(data{:,1});
sel = ismember({filier.run},data(sel,2));

set(handles.frames,'Data',reshape({filier(sel).file},[],1));


function display_frame(a,ind)

handles = getappdata(gcf,'handles');
filier = getappdata(gcf,'fileinfo');
folder = getappdata(gcf,'folder');


[runs a b]= unique({filier.run});

data = get(handles.runt,'Data');

sel = vertcat(data{:,1});
sel = find(ismember({filier.run},data(sel,2)));


old_frame = getappdata(gcf,'frame');

if ~isempty(sel) && ~isempty(ind.Indices(:,1))
  sel = sel(ind.Indices(:,1));

  fname = fullfile(folder,filier(sel(1)).file);

  frame = fast_loadPoleFigure_frame(fname);

  if exist('frame','var')
  set(handles.img,'CData',frame.A);

  sz = size(frame.A);
  set(handles.ax(1),'XLim',[0 sz(1)],'YLim',[0 sz(2)]);

  angles = frame.angles/degree;

  deg = @(x) sprintf(['%11.1f' mtexdegchar],x);
  
  data = {'2 Theta',  deg(angles(1)) ; ...
          'Omega',    deg(angles(2)) ; ...
          'Phi',      deg(angles(3)) ; ...
          'Chi',      deg(angles(4)) ; ...
         
          'Counts',   frame.ncounts  ; ...
          'Max',      frame.max; ...         
          'Min',      frame.min;...
          '','';...
          'Day',      frame.date;...
          'Time',     frame.time};
        
  data{frame.axis,2} =  sprintf(['%7.1f' mtexdegchar  '%+.1f'],angles(frame.axis,1),frame.width);
  
  
  set(handles.frameinfotable,'Data',data);
  
 cdata = linspace(frame.min,frame.max,64)';
 cdata(:,2) = cdata;
 
 	set(handles.colorbar,'CData',cdata,...
    'ZData',ones(size(cdata)),...
    'YData',cdata);
  
  set(get(handles.colorbar,'parent'),'YLim',[frame.min,frame.max])

  end

  if ~isempty(old_frame)
    if old_frame.angles(1) ~= frame.angles(1),
      update_2theta
      drawnow
    end
  else
    update_2theta
  end
else
  A = zeros(512);
  A(1,1) = 1;  
  set(handles.img,'CData',A);

end


function frame = fast_loadPoleFigure_frame(fname,varargin)

fid = fopen(fname);

% frame.dfov = 9.8161;
frame.dfov = 9.5;
frame.ncounts = readline(fid,19);   %number of counts
frame.min = readline(fid,21); % minimum counts
frame.max = readline(fid,22); % maximum counts

s = readlinestr(fid,26);
d = regexp(s,'\s*','split');
frame.date = d{1};
frame.time = d{2};

frame.width = readline(fid,34);
starting     = readline(fid,37);   %angles
% angles2 = readline(fid,66)  %endangles 
frame.nr     = readline(fid,40);   %NROWS
frame.nc     = readline(fid,41);   %NCOLS
frame.cxcy   = readline(fid,54);   %shifting 
frame.dist   = readline(fid,55);   %detector distanc in cm;
frame.axis   = readline(fid,65);
ending       = readline(fid,66);

frame.angles = angle((exp(1i*starting*degree)+exp(1i*ending*degree))/2);   %angles 

%data
fseek(fid, 96*80, 'bof');
frame.A = fread(fid,frame.nr*frame.nc,'uint8');
fclose(fid);

frame.A = (reshape(frame.A,frame.nc,frame.nr)');

setappdata(gcf,'frame',frame);

function set_current_theta(a,b)

setappdata(gcf,'current_sel',b.Indices);


function shift_theta(a,b)

handles = getappdata(gcf,'handles');
sel = getappdata(gcf,'current_sel');

val = get(a,'Value');

data = get(handles.thetas,'Data'); 


data{sel(1),sel(2)} = data{sel(1),sel(2)}  + val;

set(handles.thetas,'Data',data);
set(a,'Value',0);
% 
%  getappdata(handles.thetas)
 update_2theta
%  drawnow
 
function update_2theta(a,b)


handles = getappdata(gcf,'handles');
data1 = get(handles.thetas,'Data');
data = cellfun(@(x) x.*degree,data1(:,2:6));

for k=1:size(data,1)
  d = data(k,:);
  h(1) = draw_circ(d(1),d(4)-5*degree,d(5)+5*degree,15,'color',[0.7 1 0.3],'LineStyle','-.','tag',[k 'm']);
  %   
  h(2) = draw_circ(d(1)+d(2),d(4),d(5),11,'color',[0 .9 0.7],'tag',[k 't2']);
  h(3) = draw_circ(d(1)-d(2),d(4),d(5),11,'color',[0 .9 0.7],'tag',[k 't1']);
  
  h(4) = draw_circ([d(1)-d(2) d(1)+d(2)],d(5),d(5),5,'color',[0 .9 0.7],'tag',[k 'tg1']);
  h(5) = draw_circ([d(1)-d(2) d(1)+d(2)],d(4),d(4),5,'color',[0 .9 0.7],'tag',[k 'tg2']);
%   
  h(6) = draw_circ(d(1)-d(2)-d(3),d(4),d(5),11,'color',[0.3 0.7 1],'tag',[k 'bg1']);
  h(7) = draw_circ(d(1)+d(2)+d(3),d(4),d(5),11,'color',[0.3 0.7 1],'tag',[k 'bg2']);  
  
  
  if data1{k,1} == 1,
    set(h,'visible','on')
  else
    set(h,'visible','off')
  end
end

% drawnow update

function h = draw_circ(theta,gamma_1,gamma_2,numl,varargin)

if nargin < 4
  numl = 21;
end

handles = getappdata(gcf,'handles');
img = handles.img;

frame = getappdata(gcf,'frame');

dfov = frame.dfov;
dpos = frame.cxcy;
angles = frame.angles;

center = vector3d(-frame.dist*frame.nr/dfov,0,0);
center_theta = axis2quat(zvector,angles(1)).*center;

theta2rot = axis2quat(zvector,theta);

gamma_shift = (axis2quat(xvector, linspace(gamma_1,gamma_2,numl))*theta2rot).*center;

dx = dot(center_theta./norm(center_theta),gamma_shift./norm(gamma_shift));

gamma_shift = axis2quat(zvector,-angles(1)).*gamma_shift./dx;

[x y z] = double(gamma_shift);

dgy = y+frame.cxcy(1);
dgz = z+(frame.nr-frame.cxcy(2));



h = getappdata(gcf,'annotations');
if ~isempty(h)
  delete(h);
  setappdata(gcf,'annotations',[])
end
  
h = findall(handles.ax(1),'tag',get_option(varargin,'tag'));

if ~isempty(h)
  set(h,'XData',dgy(:)','YData',dgz(:)');
else  
  h = line('Parent',handles.ax(1),'XData',dgy(:)','YData',dgz(:)','color','r',varargin{:});
end

% xy_to_theta_gamma(dgy,dgz)
% setappdata(gcf,'annotations',[h getappdata(gcf,'annotations')]);

% text(dgy(10,1),dgz(10,1),'111.8','color','r','fontweight','bold')

function eva(a,b,doit)

if doit && validate_image
  
  id1 = iptaddcallback(gcf, 'WindowButtonMotionFcn', @draw_currentpoint);
  setappdata(gcf,'drawlines',id1);
  set(gcf,'Pointer','circle')
  draw_currentpoint;
else
  id1 = getappdata(gcf,'drawlines');
  iptremovecallback(gcf, 'WindowButtonMotionFcn', id1);
  set(gcf,'Pointer','arrow')
  
  remove_helper
end


function remove_helper

delete(findall(gcf,'tag','helperline1'))
delete(findall(gcf,'tag','helperline2'))
delete(findall(gcf,'tag','helpertheta'))
delete(findall(gcf,'tag','helpergamma'))
  

function [isvalid,frame,xp,yp] = validate_image

frame = getappdata(gcf,'frame');
handles = getappdata(gcf,'handles');

isvalid = false;
if isempty(frame), return, end;

cp = get(handles.ax(1),'CurrentPoint');
xp = cp(1,1);
yp = cp(1,2);

if xp < 0 || xp > frame.nr || 0 > yp || frame.nr < yp 
  remove_helper  
  return
end
isvalid = true;



function draw_currentpoint(a,b)

[isvalid,frame,xp,yp] = validate_image;

if ~isvalid, return; end

[theta gamma] = xy_to_theta_gamma(xp,yp);

[a dg] = xy_to_theta_gamma(xp,0);
draw_circ(theta,-dg-2*degree,dg+2*degree,50,'color','w','tag','helperline2');

[dt1 a] = xy_to_theta_gamma(0,yp);
[dt2 a] = xy_to_theta_gamma(frame.nr,yp);
draw_circ([dt2-2*degree dt1+2*degree],gamma,gamma,40,'color','w','tag','helperline1');

xlm = xlim;
ylm = ylim;
dsx = abs(diff(xlm)./frame.nr);
dsy = abs(diff(ylm)./frame.nr);
if xlm(2)-xp < 75*dsx, dsx = -7*dsx; end
if ylm(2)-yp < 75*dsy, dsy = -1*dsy; end

delete(findall(gcf,'tag','helpertheta'))
text(xp+dsx*10,yp+dsy*20,['\theta ' sprintf('%5.2f',theta/degree) mtexdegchar],...
  'color','w','tag','helpertheta','horizontalalignment','left')
delete(findall(gcf,'tag','helpergamma'))
text(xp+dsx*10,yp+dsy*35,['\gamma ' sprintf('%5.2f',gamma/degree) mtexdegchar],...
  'color','w','tag','helpergamma','horizontalalignment','left')


function [theta,gamma] = xy_to_theta_gamma(y,z,frame)


handles = getappdata(gcf,'handles');
img = handles.img;

if nargin < 3
  frame = getappdata(gcf,'frame');
end

dfov = frame.dfov;
dpos = frame.cxcy;
angles = frame.angles;

center = vector3d(-frame.dist*frame.nr/dfov,0,0);
center_theta = axis2quat(zvector,angles(1)).*center;

dgx = -frame.dist*frame.nr/dfov;
dgy = y-frame.cxcy(1);
dgz = z-(frame.nr-frame.cxcy(2));

pos = vector3d(dgx,dgy,dgz);
gamma_shift_i = axis2quat(zvector,angles(1)).*pos;

dx = dot(gamma_shift_i./norm(gamma_shift_i),center_theta./norm(center_theta));

gamma_shift_i = gamma_shift_i.*dx;

gamma = -sign(dgz).*angle(zvector,cross(gamma_shift_i,xvector));
theta2rot = axis2quat(xvector,-gamma).*gamma_shift_i;
theta = angle(theta2rot,center);




function process_data(a,b)

handles = getappdata(gcf,'handles');
filier = getappdata(gcf,'fileinfo');
folder = getappdata(gcf,'folder');

data = get(handles.runt,'Data');

sel = vertcat(data{:,1});
sel = find(ismember({filier.run},data(sel,2)));

clear pfdata

pfdata.theta  = [];
pfdata.dgamma = [];
pfdata.ind = {};
pfdata.counts = {};
pfdata.angles = [];


if ~isempty(sel)
  files = {filier(sel).file};
  

  procax = axes('Parent', gcf, ...
            'XLim',[0 100],...
            'YLim',[0 1],...
            'Box','on', ...
            'Unit','Pixels',...
            'Position',[10 15 150 20],...
            'XTickMode','manual',...
            'YTickMode','manual',...
            'XTick',[],...
            'YTick',[],...
            'XTickLabelMode','manual',...
            'XTickLabel',[],...
            'YTickLabelMode','manual',...
            'YTickLabel',[]);
          
  proc = patch('parent',procax,...
    'Vertices',[[0 0 0 0];[0 0 1 1]]','Faces',[1 2 3 4 1],...
    'FaceColor',[0 0.2 0.7]);
  
  nf = numel(files);
  data = get(handles.thetas,'Data');
  
  for k=1:numel(files)
    
    if exist('frame','var'), old_angle = frame.angles(1);
    else old_angle = NaN; end
    
    file = fullfile(folder,files{k});
    frame = fast_loadPoleFigure_frame(file);    
    
    new_angle = frame.angles(1);
    
    %create mask
    if k==1 || (new_angle ~=old_angle) || ~exist('x','var') || ~exist('y','var')
        [x,y] = meshgrid(1:frame.nr);
        [theta,gamma] = xy_to_theta_gamma(x(:),y(:),frame);

        for n=1:size(data,1)
          d = [data{n,1:6}]*degree;      
          theta_ind = (theta > d(2)-d(3)) & (theta < d(2)+d(3));
          
          pfdata(n).process_current = false;
          if any(theta_ind(:))
            pfdata(n).process_current = true;
            pfdata(n).miller = string2Miller(data{n,7});
            pfdata(n).theta = d(2);
            
            dgamma = linspace(d(5),d(6),21);
            pfdata(n).dgamma = dgamma;

            for dg = 1:numel(dgamma)-1
              dgind =  theta_ind & (gamma > dgamma(dg) & gamma < dgamma(dg+1));
              pfdata(n).ind{dg} = find(dgind(:));
             
            end
          end
        end
    end
    
    % collect data
    for n=1:numel(pfdata)
      if pfdata(n).process_current
        pfdata(n).counts{end+1} = cellfun(@(x) sum(frame.A(x)),pfdata(n).ind(end:-1:1));
        pfdata(n).angles(end+1,:) = frame.angles;        
      end
    end
    
    pp = k./nf*100;
    set(proc,'Vertices',[[0 pp pp 0];[0 0 10 10]]');
    drawnow
  end
  
  delete(procax)
end

pf = PoleFigure;

for k=1:numel(pfdata)
  pfd = pfdata(k);
  
  if ~isempty(pfd.counts)
    counts = vertcat(pfd.counts{:});
    angles = pfd.angles;
    gamma = pfd.dgamma;

    gamma  = diff(gamma)./2+gamma(1:end-1); 

    theta2 = pfd.theta;

    r = (axis2quat(zvector,angles(:,3)).* ...
            axis2quat(yvector,pi/2-angles(:,4)).* ...
            axis2quat(xvector,angles(:,2)))* ...
         (axis2quat(yvector,gamma)* ...
            axis2quat(xvector,(pi-theta2)/2)).*yvector;

    pf(k) =  PoleFigure(pfdata(k).miller,S2Grid(r(:)),counts(:),symmetry('cubic'),symmetry,'comment',num2str(theta2));
  end
  
  
end

pf = pf(GridLength(pf)>0);

assignin('base','pf',pf)

figure, plot(pf,'markersize',2)
colormap(jet)






function data = readline(fid,line)

fseek(fid,line*80+8,'bof');
data = sscanf(char(fread(fid, 72, 'char')),'%f');


function data = readlinestr(fid,line)

fseek(fid,line*80+8,'bof');
data = char(fread(fid, 72, 'char')');



function handles = create_tab_current_frame(handles)
% current frame

tabs = getappdata(handles.tabpane,'panels');

th = 220;

fh = @(x) [180 th-x 60 20];
ft = @(x) [100 th-x 60 20];

handles.frameinfotable = uitable(...
            'parent',tabs(1),...
            'Units','pixels','Position',...
            [90 th-205 150 200], 'Data', {},...
            'FontName','monospaced',...
            'FontSize',9,...
            'FontWeight','bold',...
            'ColumnName', {},...
            'RowName',[],...
            'ColumnWidth',{60 86});


handles.ax(2) = axes;
handles.colorbar = pcolor(handles.ax(2),[0:255;0:255]');
set(handles.colorbar,'EdgeColor','none');
set(handles.ax(2),'parent',tabs(1),'TickDir','out','XMinorTick','off','YMinorTick','on','Layer','top',...
  'Unit','pixels','position',[50 th-165 20 160],'XTick',[]);



function handles = create_tab_2theta(handles)
% table theta gamma
th = 220;
tabs = getappdata(handles.tabpane,'panels');

dat =  {true,113.8,1.5,1.5,-15,15,'113';...
        true,90.6,1.5,1.5,-15,15,'220';...
        true,60.6,1.5,1.5,-18,18,'200';...
        true,51.4,1.5,1.5,-18,18,'111'};
      
columnname = {'','2Theta','dTheta','dBgTheta','gamma_1','gamma_2','hkl'};
columneditable = [true, true, true, true,true,true,true];
columnformat = {'logical','numeric','numeric','numeric','numeric','numeric', 'char'};
handles.thetas = uitable(...
            'parent',tabs(2),...
            'Units','pixels','Position',...
            [10 th-205 200 200], 'Data', dat,... 
            'ColumnName', columnname,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',{25,70,50,50,70,70},...
            'RowName',[],'CellEditCallback',@update_2theta,'CellSelectionCallback',{@set_current_theta});
          
        
          
% uicontrol('style','pushbutton',...
%    'parent',tabs(2),...
%   'String','+',...
%   'FontWeight','bold',...
%   'FontName','monospaced',...
%    'FontSize',12,...
%   'position',[210 80 20 20])
% 
% 
% uicontrol('style','pushbutton',...
%    'parent',tabs(2),...
%    'String','-',...
%   'FontWeight','bold',...
%   'FontName','monospaced',...
%    'FontSize',12,...
%   'position',[210 100 20 20])
          
          
% handles.thetaslider = uicontrol('parent',tabs(2),'style','slider',  ...
%   'Max',5,'Min',-5,'Value',0,'SliderStep',[0.1 0.1],'Position',[225 55 15 150],'KeyPressFcn',@shift_theta,'Callback',@(src,ev) set(src,'Value',0));