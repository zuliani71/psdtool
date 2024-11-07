function psdtool(action,opt1,opt2)
%PSDTOOL starts the Power Spectral Density tool.
%
%   Author:
%       name:   David Zuliani
%       e-mail: dzuliani@inogs.it
%       web:    www.crs.inogs.it
%   Modified by D. Zuliani, 17-03-04
%   Revision: 1.0 Date: 2004/03/17 13:17:40
%   Revision: 2.0 Date: 2007/07/26 17:02:00
%       - sac reading features added;
%       - platform independent;
%       - toolbox independent.
%   Revision: 2.1 Date: 2008/02/15 17:30:00
%       - rsac2 and lh implemented inside
%           psdtool (no external functions
%           neeeded).
%   Revision: 3.0 Date: 2008/02/18 20:03:00
%       - compare function added;
%       - confidence interval added.
%   Revision: 3.1 Date: 2009/02/11 11:00
%       - better usage of sac reading;
%       - avoidance of duplicates names in
%           the lateral bar list;
%       - removed some minor bugs.
%   Revision: 3.2 Date: 2009/02/12 11:34
%       - changed dirname command to the
%           better fileparts command;
%       - better handling of Symbolic
%           Toolbox lackness;
%       - data units check (both in the axes
%           labels and in the report files);
%       - removed Latex Interpreter from the
%           most part of legends and titles;
%       - removed some minor bugs.
%   Revision: 3.3 Date: 2012/02/28 10:00
%       - filetye added
%       - rsact added for reading text sac file


if nargin<1
    action='initialize';
end;
format short e
% Setting SLASH for computer dependent PATHS
if ispc
    SLASH_TYPE = '\';
else
    SLASH_TYPE = '/';
end

% try
if strcmp(action,'initialize');
    [Objects.LocalPathName,~,~] = fileparts(mfilename('fullpath'));
    Objects.ConfigFileName	=	[Objects.LocalPathName,SLASH_TYPE,'psdtool.cfg'];
    Objects.PathFileName	=	[Objects.LocalPathName,SLASH_TYPE,'psdtool.path'];
    Objects.NoiseRefMinFileName	=	[Objects.LocalPathName,SLASH_TYPE,'NLNM.par'];
    Objects.NoiseRefMaxFileName	=	[Objects.LocalPathName,SLASH_TYPE,'NHNM.par'];
    D=dir(Objects.PathFileName);
    if isempty(D)
        set_path({},{});
    end
    D=dir(Objects.ConfigFileName);
    % D: [Datalogger type] [Q] [Q units]
    Datalogger_fields={'type','Q','Units'};
    Datalogger_formats={'%s','%f','%s'};
    % S: [Sensor type] [S/N] [Sensitivity] [Sensitivity units] [Max period value] [Max period value units]
    Sensor_fields={'SensT','SensN','Sens','SensU','SensTmax','SensTmaxU'};
    Sensors_formats={'%s','%s','%f','%s','%f','%s'};
    % C: [Taper method] [Slot fraction (fraction of the sensor max period)] [Overlapping (fraction of the Slot length)]
    %Calculus_fields={'Method','Taper','Fraction','Overlap'};
    %Calculus_formats={'%s','%s','%f','%f', '%f'};
    Calculus_fields={'Method','Taper','Fraction','Overlap','Confidence'};
    Calculus_formats={'%s','%s','%f','%f', '%f'};
    % F: Supported file type
    % F: [.type1 .type2 .type3 ...]
    % e.g: F: she shz shn bhz bhe bhn vn vu ve
    if ~isempty(D)
        cont_S=0;
        cont_D=0;
        fid=fopen(Objects.ConfigFileName,'r');
        while 1
            line = fgetl(fid);
            if ~isstr(line) , break, end
            if ~isempty(line)
                Line = (strread(line,'%s'))';
                switch Line{1}
                    case '#'
                    case {'D:','d:'}
                        Line=Line(2:end);
                        cont_D=cont_D+1;
                        for cont =1:1:size(Datalogger_formats,2)
                            if strcmp(Datalogger_formats(cont),'%f')
                                Line{cont}=str2num(Line{cont});
                            end
                        end
                        Dataloggers(cont_D)=cell2struct(Line,Datalogger_fields,2);
                    case {'S:','s:'}
                        Line=Line(2:end);
                        cont_S=cont_S+1;
                        for cont =1:1:size(Sensors_formats,2)
                            if strcmp(Sensors_formats(cont),'%f')
                                Line{cont}=str2num(Line{cont});
                            end
                        end
                        Sensors(cont_S)=cell2struct(Line,Sensor_fields,2);
                    case {'C:','c:'}
                        Line=Line(2:end);
                        if  size(Line,2) == 4
                            % Confidence is not inserted within the config file (may be old version of
                            % pstoool and psdtool.cfg then add this info
                            % automatically is added
                            Line = {Line{:},'0.95'};
                        end
                        for cont =1:1:size(Calculus_formats,2)
                            if strcmp(Calculus_formats(cont),'%f')
                                Line{cont}=str2num(Line{cont});
                            end
                        end
                        Objects.Calculus=cell2struct(Line,Calculus_fields,2);
                    case {'F:','f:'}
                        Objects.FileType=Line(2:end);
                end
            end
        end
        fclose(fid);
    else
        % Default Values
        Values = {'None'    1   'V/count';
            'Q4120'     2.34E-6     'V/count';
            'Q330'      2.34E-6     'V/count';
            'RefTeq'    1.9E-9      'V/count';
            'MarsLite'  0.125E-6    'V/count';
            'M24'		0.596E-6    'V/count'};
        Dataloggers = cell2struct(Values,Datalogger_fields,2);
        Values = {  'None'          1 	1       'n.c.'       1    	's';
            'CMG40'		    1 	800  	'V/(m/s)' 	30  	's';
            'Lennartz_3D1s'	1	400	    'V/(m/s)'	1	    's';
            'Lennartz_3D5s'	1	400	    'V/(m/s)'	5	    's';
            'STS1'  		1	1500	'V/(m/s)'	360	    's';
            'STS2'   		1	1500	'V/(m/s)'	120	    's'};
        Sensors = cell2struct(Values,Sensor_fields,2);
        Objects.Calculus = cell2struct({'pwelch' 'hanning' 2 0.75 0.95},Calculus_fields,2);
        Objects.FileType = {'she' 'shz' 'shn' 'bhz' 'bhe' 'bhn' 'hhe' 'hhn' 'hhz' 'vn' 'vu' 've' '1' '2' '3' 'txt' 'asc'} ;
    end
    
    %***************** Main Figure ****************************
    Gen_units   =   'normalized';
    Pap_Units   =   Gen_units;
    Fnt_units   =   Gen_units;
    Fnt_size    =   0.2;
    Fnt_name    =   'helvetica';
    Fnt_wht     =   'bold';
    FigurePos   =   [0.05 0.2];
    FigureSize  =   [0.3 0.6];
    Bkg_color       =   [0.831372549019608 0.815686274509804 0.784313725490196];
    MainPWD=pwd;
    MainFigure = figure('Color',Bkg_color, ...
        'FileName',[MainPWD,'\trackviewer.m'], ...
        'PaperUnits',Pap_Units, ...
        'PaperPosition',[0 0 0.1 0.1], ...
        'Units',Gen_units, ...
        'Position',[FigurePos FigureSize], ...
        'Tag','MainFigure', ...
        'Name','Psdtool',...
        'NumberTitle','off',...
        'ToolBar','none');
    
    %Bkg_color       = [0.50 0.50 0.50];
    %***************** Main Frame ****************************
    FrameSize  =   [0.98,0.588];
    FrameLeft  =   0.01;
    FrameBottom   =   0.37;
    MainFrame = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',Bkg_color,...
        'Position',[FrameLeft FrameBottom FrameSize],...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Style','frame',...
        'enable','off',...
        'Tag','MainFrame');
    
    MainText = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',Bkg_color,...
        'ForegroundColor','black',...
        'ListboxTop',0, ...
        'Position',[0.1 0.949 0.11 0.04],...
        'HorizontalAlignment','center',...
        'String','PSD tool', ...
        'Style','text', ...
        'FontName','helvetica',...
        'FontUnits',Fnt_units,...
        'FontSize',1,...
        'FontWeight',Fnt_wht,...
        'Tag','TextLogger1');
    
    MainFrame2 = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',Bkg_color,...
        'Position',[FrameLeft 0.02 0.45 0.37],...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Style','frame',...
        'String','Load Tracks',...
        'enable','off',...
        'Tag','PictureFrame');
    
    TextForRemoving1 = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',Bkg_color,...
        'Position',[FrameLeft+0.001 0.372 0.47 0.02],...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Style','text',...
        'enable','off',...
        'Tag','PictureFrame');
    
    %***************** Frames ****************************
    FrameSize  =   [0.94,0.51];
    FrameLeft  =   0.03;
    FrameBottom   =   0.4;
    FrameColor=[0.5 0.5 0.5];
    TopFrame = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',FrameColor,...
        'Position',[FrameLeft FrameBottom FrameSize],...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Style','frame',...
        'String','Load Tracks',...
        'enable','off',...
        'Tag','MainFrame');
    MiddleFrame = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',FrameColor,...
        'Position',[FrameLeft 0.22 0.41 0.14],...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Style','frame',...
        'String','Load Tracks',...
        'enable','off',...
        'Tag','MiddleFrame');
    BottomFrame = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',FrameColor,...
        'Position',[FrameLeft 0.05 0.41 0.14],...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Style','frame',...
        'String','Load Tracks',...
        'enable','off',...
        'Tag','BottomFrame');
    
    Bkg_color       =   [0.831372549019608 0.815686274509804 0.784313725490196];
    %***************** Buttons ****************************
    ButtonSize  =   [0.8,0.1];
    ButtonSizeSmall = [0.17,0.08];
    ButtonSizeSmall1 = [0.08,0.08];
    ButtonLeft  =   0.05;
    ButtonLeft1  =   0.25;
    ButtonLeft2  =   0.34;
    ButtonTop   =   0.8;
    ButtonStep  =   0.05;
    CallBackString  =   'psdtool(''multiple'')';
    MultiplePSDButton = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',Bkg_color,...
        'ListboxTop',0,...
        'Position',[ButtonLeft 0.8 ButtonSizeSmall],...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',1.4*Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Style','pushbutton',...
        'String','Load Tracks',...
        'Call',CallBackString,...
        'Tag','ButtonLoad');
    
    CallBackString='psdtool(''doitmultiple'')';
    DoMultiplePSDButton = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',Bkg_color,...
        'ListboxTop',0,...
        'Position',[ButtonLeft 0.48-ButtonStep ButtonSizeSmall],...
        'Style','pushbutton',...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',1.4*Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Style','pushbutton',...
        'String','Perform PSD', ...
        'Call',CallBackString,...
        'Tag','ButtonPerform');
    
    CallBackString='psdtool(''multipleview'')';
    MultiplePSDViewButton = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',Bkg_color,...
        'ListboxTop',0, ...
        'Position',[ButtonLeft1 0.3-ButtonStep ButtonSizeSmall1], ...
        'Style','pushbutton', ...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',1.4*Fnt_size,...
        'FontWeight',Fnt_wht,...
        'String','Plot PSD', ...
        'Call',CallBackString,...
        'Tag','ButtonPlot');
    
    CallBackString='psdtool(''compare'')';
    CompareButton = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',Bkg_color,...
        'ListboxTop',0, ...
        'Position',[ButtonLeft2 0.3-ButtonStep ButtonSizeSmall1], ...
        'Style','pushbutton', ...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',1.4*Fnt_size,...
        'FontWeight',Fnt_wht,...
        'String','Compare', ...
        'Call',CallBackString,...
        'Tag','ButtonPlot');
    
    CallBackString='psdtool(''help'')';
    CloseButton = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',Bkg_color,...
        'ListboxTop',0, ...
        'Position',[ButtonLeft 0.13-ButtonStep ButtonSizeSmall], ...
        'Style','pushbutton', ...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',1.4*Fnt_size,...
        'FontWeight',Fnt_wht,...
        'String','Help', ...
        'Call',CallBackString,...
        'Tag','ButtonHelp');
    
    CallBackString='psdtool(''close'')';
    HelpButton = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',Bkg_color,...
        'ListboxTop',0, ...
        'Position',[ButtonLeft1 0.13-ButtonStep ButtonSizeSmall], ...
        'Style','pushbutton', ...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',1.4*Fnt_size,...
        'FontWeight',Fnt_wht,...
        'String','Close', ...
        'Call',CallBackString,...
        'Tag','ButtoClose');
    
    %***************** PopUps ****************************
    PopUpSize   =   [0.17,0.1];
    PopUpStepL  =   0;
    PopUpLeft1  =   0.05;
    PopUpLeft2  =   PopUpLeft1 + PopUpStepL;
    PopUpStepV  =   0.13;
    PopUpTop1   =   0.64;
    PopUpTop2   =   PopUpTop1-PopUpStepV;
    PopUpTop3   =   0.198;
    CallBackString='psdtool(''multipledatalogger'')';
    DataLoggerString={Dataloggers(:).type};
    MultipleLoggerPopUp = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',Bkg_color,...
        'ListboxTop',0, ...
        'Position',[PopUpLeft1 PopUpTop1 PopUpSize], ...
        'String',DataLoggerString, ...
        'Call',CallBackString,...
        'Style','popupmenu', ...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Tag','PopupDataloggers', ...
        'Enable','on',...
        'Value',1,...
        'UserData',Dataloggers);
    
    CallBackString='psdtool(''multiplesensor'')';
    SensorString={Sensors(:).SensT};
    MultipleSensorPopUp = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',Bkg_color,...
        'ListboxTop',0,...
        'Position',[PopUpLeft2 PopUpTop2 PopUpSize], ...
        'String',SensorString, ...
        'Call',CallBackString,...
        'Style','popupmenu', ...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Tag','PopupSensors', ...
        'Enable','on',...
        'Value',1,...
        'UserData',Sensors);
    
    SortingString={'frequency','period'};
    SortingPopUp = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',Bkg_color,...
        'ListboxTop',0,...
        'Position',[PopUpLeft2 PopUpTop3 PopUpSize], ...
        'String',SortingString, ...
        'Style','popupmenu', ...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Tag','PopupSorting', ...
        'Enable','on',...
        'Value',1);
    
    %************** Text ********************************
    TextSize  = [0.17,0.03];
    TextLeft  = 0.05;
    TextTop1  = PopUpTop1 + PopUpSize(2);
    TextTop2  = PopUpTop2 + PopUpSize(2);
    TextTop3  = 0.3;
    TextAlign = 'left';
    Fnt_size = 0.7;
    labelColor=192/255*[1 1 1];
    MultipleLoggerText = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',labelColor,...
        'ListboxTop',0, ...
        'Position',[TextLeft TextTop1 TextSize],...
        'HorizontalAlignment',TextAlign,...
        'String','Datalogger Type:', ...
        'Style','text', ...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Tag','TextLogger1');
    
    MultipleLoggerLoggValue = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',labelColor,...
        'ListboxTop',0, ...
        'Position',[TextLeft TextTop1-(TextSize(2)+ 0.4*PopUpSize(2)) TextSize],...
        'HorizontalAlignment',TextAlign,...
        'String','1 n.c.', ...
        'Style','text', ...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Style','text', ...
        'ForegroundColor','blue',...
        'Tag','TextLogger2');
    
    MultipleLoggerSensor = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',labelColor,...
        'ListboxTop',0, ...
        'Position',[TextLeft TextTop2 TextSize],...
        'HorizontalAlignment',TextAlign,...
        'String','Sensor Type:', ...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Style','text', ...
        'Tag','TextSensor1');
    
    MultipleLoggerSensorValue = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',labelColor,...
        'ListboxTop',0, ...
        'Position',[TextLeft TextTop2-(TextSize(2)+ 0.4*PopUpSize(2)) TextSize],...
        'String','1 n.c.', ...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Style','text', ...
        'HorizontalAlignment','left',...
        'ForegroundColor','blue',...
        'Tag','TextSensor2');
    
    SortingText = uicontrol('Parent',MainFigure, ...
        'Units',Gen_units,...
        'BackgroundColor',labelColor,...
        'ListboxTop',0, ...
        'Position',[TextLeft TextTop3 TextSize],...
        'HorizontalAlignment',TextAlign,...
        'String','Sort plots by:', ...
        'Style','text', ...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Tag','TextSorting');
    
    %***************** List ****************************
    EditSize  =   [0.7,0.45];
    EditLeft  =   0.25;
    EditTop  =   0.43;
    CallBackString  =   'psdtool(''list'')';
    MultiplePathNameText = uicontrol('Parent',MainFigure, ...
        'Max',1,...
        'Min',0,...
        'Units',Gen_units,...
        'BackgroundColor',Bkg_color,...
        'ListboxTop',1, ...
        'Position',[EditLeft EditTop EditSize], ...
        'String','', ...
        'Enable','on',...
        'FontName',Fnt_name,...
        'FontUnits',Fnt_units,...
        'FontSize',0.06*Fnt_size,...
        'FontWeight',Fnt_wht,...
        'Style','listbox', ...
        'HorizontalAlignment','left',...
        'Call',CallBackString,...
        'ForegroundColor','blue',...
        'Tag','List');
    
    %***************** Logo ****************************
    D=dir([Objects.LocalPathName,SLASH_TYPE,'Logo.jpg']);
    if ~isempty(D)
        PictureSize  =   [0.5,0.32];
        PicturePos  =   [0.48 0.03];
        PicAxes = axes('units','normal','Position', [PicturePos PictureSize]);
        Im  = imread('Logo.jpg','jpg');
        image(Im);
        axis off;
    else
        LogoPos=[0.46 0.020];
        LogoSize=[0.53,0.35];
        LogoButton = uicontrol('Parent',MainFigure, ...
            'Units',Gen_units,...
            'BackgroundColor',Bkg_color,...
            'ListboxTop',0, ...
            'Position',[LogoPos, LogoSize], ...
            'Style','pushbutton', ...
            'FontName',Fnt_name,...
            'FontUnits',Fnt_units,...
            'FontSize',1.4*Fnt_size,...
            'FontWeight',Fnt_wht,...
            'String','', ...
            'Enable','off',...
            'Tag','ButtonLogo');
        LogoFrame = uicontrol('Parent',MainFigure, ...
            'Units',Gen_units,...
            'BackgroundColor',Bkg_color,...
            'Position',[LogoPos(1)+0.004,LogoPos(2)+0.008,LogoSize(1)-0.01,LogoSize(2)-0.015],...
            'FontName',Fnt_name,...
            'FontUnits',Fnt_units,...
            'FontSize',Fnt_size,...
            'FontWeight',Fnt_wht,...
            'Style','frame',...
            'String','Load Tracks',...
            'enable','off',...
            'Tag','LogoFrame');
        LogoString = {'  Istituto Nazionale';...
            '  di Oceanografia e Geofisica Sperimentale - OGS';...
            '  -----------------------------------------------------------------';...
            '  dept: Centro di Ricerche Sismologiche - CRS';...
            '  Via Treviso, 55 - 33100 UDINE Italy';...
            '  Tel.: +39 0432 522433/522422';...
            '  Fax : +39 0432 522474';...
            '  http:\\www.crs.inogs.it'};
        LogoText = uicontrol('Parent',MainFigure, ...
            'Units',Gen_units,...
            'BackgroundColor',Bkg_color,...
            'ListboxTop',0, ...
            'Position',[LogoPos(1)+0.008,LogoPos(2)+0.015,LogoSize(1)-0.018,LogoSize(2)-0.025],...
            'HorizontalAlignment',TextAlign,...
            'String',LogoString, ...
            'Style','text', ...
            'FontName',Fnt_name,...
            'FontUnits',Fnt_units,...
            'FontSize',Fnt_size/7.8,...
            'FontWeight',Fnt_wht,...
            'Tag','TextLogo');
    end
    Objects.G_multiple				=	MultiplePSDButton;
    Objects.G_logg_multiple			=	MultipleLoggerPopUp;
    Objects.G_sens_multiple			=	MultipleSensorPopUp;
    Objects.G_doit_multiple			=	DoMultiplePSDButton;
    Objects.G_multiple_view			=	MultiplePSDViewButton;
    Objects.G_logg_value_multiple	=	MultipleLoggerLoggValue;
    Objects.G_sens_value_multiple	=	MultipleLoggerSensorValue;
    Objects.G_MultiplePathNameText  =	MultiplePathNameText;
    Objects.G_MultiplePathNameText  =	MultiplePathNameText;
    Objects.G_MultipleSortingPopUp  =   SortingPopUp;
    set([Objects.G_logg_multiple,...
        Objects.G_sens_multiple,....
        Objects.G_doit_multiple,....
        Objects.G_logg_value_multiple,...
        Objects.G_sens_value_multiple,...
        Objects.G_MultiplePathNameText],'Enable','off');
    Objects.MultiplePathName	=	[pwd,SLASH_TYPE];
    Objects.MultipleFileName	=	'';
    set(MainFigure,'UserData',Objects);
    
elseif strcmp(action,'multiple');
    MainFigure	=	gcf;
    Objects		=	get(MainFigure,'UserData');
    [Paths,Flags]=get_path({'LMT'},Objects.PathFileName);
    if isempty(Paths)
        Paths={[pwd,SLASH_TYPE]};
    end
    PATHNAME = uigetdir(Paths{1},'Choose the folder data file for PSD');
    if PATHNAME~=0
        PATHNAME=[PATHNAME,SLASH_TYPE];
        ListFiles = [];
        ListFilesNew = [];
        for i = 1:size(Objects.FileType,2)
            ListFilesNew = dir([PATHNAME,'*.',Objects.FileType{i}]);
            % for avoiding duplicates names after dir *.she and dir *.SHE
            if i == 1
                ListFiles = ListFilesNew;
            else
                LASTFILES = {ListFilesNew.name};
                LASTLIST  = {ListFiles.name};
                for j = 1:size(LASTFILES,2)
                    INDEX_ALREADY_EXIST = strmatch(LASTFILES(j),LASTLIST);
                    if isempty(INDEX_ALREADY_EXIST);
                        ListFiles = [ListFiles;ListFilesNew(j)];
                    else
                        
                    end
                end
            end
        end
        NumFiles=size(ListFiles,1);
        NumFilesMatched=0;
        for cont = 1:NumFiles
            ListFiles(cont);
            if ListFiles(cont).isdir==0
                IndexLastDot=findstr(ListFiles(cont).name,'.');
                if ~isempty(IndexLastDot)
                    IndexLastDot=IndexLastDot(end)+1;
                end
                Extension=ListFiles(cont).name(IndexLastDot:end);
                for i = 1:1:size(Objects.FileType,2)
                    if strmatch(Extension,Objects.FileType{i},'exact')
                        NumFilesMatched=NumFilesMatched+1;
                        ListFilesMatched(NumFilesMatched).name=ListFiles(cont).name;
                    end
                end
            else
            end
        end
        if exist('ListFilesMatched')
            str = {ListFilesMatched.name};
            [s,v] = listdlg('PromptString','Select the file:','SelectionMode','multiple','ListString',str,'ListSize',[300 300]);
            ListFilesMatched=ListFilesMatched(s);
            if size(ListFilesMatched,2) > 0
                if NumFilesMatched ~=0
                    set_path({'LMT'},{PATHNAME},Objects.PathFileName);
                    Objects.ListFilesMatched    =   ListFilesMatched;
                    Objects.MultipleFileName	=	{ListFilesMatched.name};
                    Objects.MultiplePathName	=	PATHNAME;
                    if strcmp(get(Objects.G_logg_value_multiple,'Enable'),'off')
                        set([Objects.G_logg_multiple,...
                            Objects.G_sens_multiple,....
                            Objects.G_doit_multiple,....
                            Objects.G_logg_value_multiple,...
                            Objects.G_sens_value_multiple,...
                            Objects.G_MultiplePathNameText],'Enable','on');
                    else
                    end
                    for i = 1:size(ListFilesMatched,2)
                        if exist('ListToShow')
                            ListToShow={ListToShow{:},[PATHNAME,ListFilesMatched(i).name]};
                        else
                            ListToShow={[PATHNAME,ListFilesMatched(i).name]};
                        end
                    end
                    set(Objects.G_MultiplePathNameText,'String',ListToShow);
                    Objects.Info_Multiple=''; %settaggio iniziale per le Info sui dati da file multipli
                    set(MainFigure,'UserData',Objects);
                    % ogni volta che psdtool viene chiamato con i parametri
                    % singledatalogger o singlesensor esso salva i dati
                    % Objects in
                    % UserData di MainFigure. In questo modo gli Objects sono disponibili
                    % da tutte le routine che usano MainFigure per recuperarli
                    psdtool('multipledatalogger');
                    psdtool('multiplesensor');
                else
                    set([Objects.G_logg_multiple,...
                        Objects.G_sens_multiple,....
                        Objects.G_doit_multiple,....
                        Objects.G_logg_value_multiple,...
                        Objects.G_sens_value_multiple,...
                        Objects.G_MultiplePathNameText],'Enable','off');
                    Objects.ListFilesMatched=[];
                    Objects.NumFilesMatched=NumFilesMatched;
                    set(MainFigure,'UserData',Objects);
                end
            else
                WARNSTRING = 'No data selected, list of loaded data will be unchanged.';
                DLGNAME = '!!Warning!!';
                warndlg(WARNSTRING,DLGNAME)
            end
        else
            for  i = 1:size(Objects.FileType,2)
                FileTypeToPrint{i}=['"',Objects.FileType{i},'", '];
            end
            WARNSTRING = ['No data of type: ',FileTypeToPrint{:},' available in this directory. ',...
                'List of loaded data will be unchanged.'];
            DLGNAME = '!!Warning!!';
            warndlg(WARNSTRING,DLGNAME)
        end
    else
        WARNSTRING = 'No data selected, list of loaded data will be unchanged.';
        DLGNAME = '!!Warning!!';
        warndlg(WARNSTRING,DLGNAME)
    end
    
elseif strcmp(action,'doitmultiple');
    MainFigure	=	gcf;
    Objects		=	get(MainFigure,'UserData');
    FILENAME_TRACKS	=	Objects.MultipleFileName;
    PATHNAME_TRACKS	=	Objects.MultiplePathName;
    [Paths,Flags]=get_path({'DMP'},Objects.PathFileName);
    if isempty(Paths)
        Paths={[pwd,SLASH_TYPE]};
    end
    ListFilesMatched=Objects.ListFilesMatched;
    NumFilesMatched=size(ListFilesMatched,2);
    Info_Multiple	=	Objects.Info_Multiple;
    Quantity='auto';
    Confidence = Objects.Calculus.Confidence;
    Method=Objects.Calculus.Method;
    TaperMode=Objects.Calculus.Taper;
    SlotFraction=Objects.Calculus.Fraction;
    Overlap=Objects.Calculus.Overlap;
    SensTmax=Objects.Info_Multiple.SensTmax;
    prompt = {'Quantity:',...
        'Calculus method:',...
        'Taper mode:',...
        'Slot size in [s]:',...
        'Overlap percent:',...
        'Confidence level:'};
    dlg_title = 'Calculus preferences';
    num_lines= 1;
    def     = {Quantity,Method,TaperMode,num2str(SensTmax*SlotFraction),num2str(100*Overlap),num2str(Confidence)};
    answers =   inputdlg(prompt,dlg_title,num_lines,def);
    Prompt_error.text='start';
    Prompt_error.code=0;
    while ~isempty(char({Prompt_error.text}))
        if isempty(answers)
            break
        end
        for i = 1:size(answers,1)
            if isempty(answers)
                break
            end
            switch i
                case 1
                    % quantity
                    switch lower(answers{i})
                        case {'auto','acc','vel','dis'}
                            Prompt_error.text='';
                        otherwise
                            Prompt_error.text = ['Bad "',prompt{i},' ',answers{i},'". Only "acc", "vel", "dis", quantities and the "auto" keyword are allowed.'];
                            Prompt_error.code=i;
                    end
                case 2
                    % calculus
                    switch lower(answers{i})
                        case {'pwelch'}
                            Prompt_error.text='';
                        otherwise
                            Prompt_error.text = 'Sorry only "pwelch" method is implemented right now.';
                            Prompt_error.code=i;
                    end
                case 3
                    % taper
                    ListWindowsAllowed={'barthannwin',...
                        'bartlett',...
                        'blackman',...
                        'blackmanharris',...
                        'bohmanwin',...
                        'flattopwin',...
                        'gausswin',...
                        'hamming',...
                        'hanning',...
                        'nuttallwin',...
                        'parzenwin',...
                        'rectwin',...
                        'triang'};
                    ListWindowToPlot={};
                    for j = 1:size(ListWindowsAllowed,2)
                        ListWindowToPlot{j}=['"',ListWindowsAllowed{j},'", '];
                    end
                    switch lower(answers{i})
                        case ListWindowsAllowed
                            Prompt_error.text='';
                        otherwise
                            Prompt_error.text = ['Bad "',prompt{i},' ',answers{i},'". Only ',ListWindowToPlot{:},' windows are allowed.'];
                            Prompt_error.code=i;
                    end
                case 4
                    % slot size
                    if ~isempty(str2num(answers{i}))
                        if str2num(answers{i})/SensTmax <= 0
                            Prompt_error.text = ['Bad "',prompt{i},' ',answers{i},...
                                '". You must use values greather than 0.'];
                            Prompt_error.code=i;
                        else
                            %SlotFraction=str2num(answers{i})/SensTmax;
                        end
                    else
                        Prompt_error.text = ['Bad "',prompt{i},' ',answers{i},'". Only numerical values are allowed.'];
                        Prompt_error.code=i;
                    end
                case 5
                    % overlap
                    %Overlap=str2num(answers{i})/100;
                    if ~isempty(str2num(answers{i}))
                        if (str2num(answers{i}) < 0) || (str2num(answers{i}) >100)
                            Prompt_error.text = ['Bad "',prompt{i},' ',answers{i},...
                                '". You must use values between 0 and 100.'];
                            Prompt_error.code=i;
                        else
                            %SlotFraction=str2num(answers{i})/SensTmax;
                        end
                    else
                        Prompt_error.text = ['Bad "',prompt{i},' ',answers{i},'". Only numerical values are allowed.'];
                        Prompt_error.code=i;
                    end
                case 6
                    % Confidence level must be between 0 and 1
                    if ~isempty(str2num(answers{i}))
                        if (str2num(answers{i}) < 0) || (str2num(answers{i}) >1)
                            Prompt_error.text = ['Bad "',prompt{i},' ',answers{i},...
                                '". Confidence level must be between 0 and 1.'];
                            Prompt_error.code=i;
                        else
                            %SlotFraction=str2num(answers{i})/SensTmax;
                        end
                    else
                        Prompt_error.text = ['Bad "',prompt{i},' ',answers{i},'". Only numerical values are allowed.'];
                        Prompt_error.code=i;
                    end
            end
            if ~isempty(char({Prompt_error.text}))
                break
            end
        end
        if ~isempty(char({Prompt_error.text}))
            button = questdlg([char({Prompt_error.text})],...
                'Warning','Correct','Cancel','Correct');
            if strcmp(button,'Correct')
                prompt = {'Quantity:',...
                    'Calculus method:',...
                    'Taper mode:',...
                    'Slot size in [s]:',...
                    'Overlap percent:'};
                dlg_title = 'Calculus preferences';
                num_lines= 1;
                %def     = {Quantity,Method,TaperMode,num2str(SensTmax*SlotFraction),num2str(100*Overlap)};
                def     = answers';
                answers=inputdlg(prompt,dlg_title,num_lines,def);
                Prompt_error.text='start';
                Prompt_error.code=0;
            elseif strcmp(button,'Cancel')
                return
            end
        else
        end
    end
    if isempty(answers)
        WARNSTRING = 'No preferences selected: PSD not performed.';
        DLGNAME = '!!Warning!!';
        warndlg(WARNSTRING,DLGNAME)
        return
    end
    Quantity_Want.name=answers{1};
    Method=answers{2};
    TaperMode=answers{3};
    SlotFraction=str2num(answers{4})/SensTmax;
    Overlap=str2num(answers{5})/100;
    Confidence=str2num(answers{6});
    FILENAME=ListFilesMatched(1).name;
    File_loaded=load_track([PATHNAME_TRACKS FILENAME],Objects.FileType);
    % Check if a warning string has issued by File_loaded
    if ischar(File_loaded)
        WARNSTRING = File_loaded;
        DLGNAME = '!!Warning!!';
        warndlg(WARNSTRING,DLGNAME);
        return
    end
    if license('test','symbolic_toolbox')
        try
            SensUnits=sym(Info_Multiple.SensU);
            DataLogUnits=sym(Info_Multiple.Units);
            DataUnits=sym('count');
            UnitOfMes=DataLogUnits*DataUnits/SensUnits;
        catch
            try
                SensUnits=Info_Multiple.SensU;
                DataLogUnits=Info_Multiple.Units;
                DataUnits='count';
                UnitOfMes=[DataLogUnits,'*',DataUnits,'/',SensUnits];
            catch
                WARNSTRING = 'Data Units problem';
                DLGNAME = '!!Warning!!';
                warndlg(WARNSTRING,DLGNAME);
                return
            end
        end
    else
        SensUnits=Info_Multiple.SensU;
        DataLogUnits=Info_Multiple.Units;
        DataUnits='count';
        UnitOfMes=[DataLogUnits,'*',DataUnits,'/',SensUnits];
    end
    Quantity_Orig=get_quant(char(UnitOfMes));
    FileType=Quantity_Orig.name;
    if strcmp(Quantity_Want.name,'auto')
    else
        FileType=Quantity_Want.name;
    end
    if NumFilesMatched == 1
        % single PSD file will be performed
        [FILENAME, PATHNAME] = uiputfile([Paths{1},FILENAME,'.',FileType,'.pwd'], 'Save as');
        No_Mean_Flag = 1;
    else
        % multiple PSD files will be performed
        Pathern_found={};
        No_Mean_Flag = 0;
        % check files choesen for better understand if they are of the
        % same type (or if they came from the same sensor component)
        % No_Mean_Flag = 1 -> files came from different sensor
        %         components, no mean file will be produced
        % No_Mean_Flag = 0 -> files came from the same sensor
        %         components, the mean file will be produced
        for cont_f =1:1:NumFilesMatched
            for count_p = 1:size(Objects.FileType,2)
                Pathern=['.',Objects.FileType{count_p}];
                MatchIndex=strfind(ListFilesMatched(cont_f).name,Pathern);
                if ~isempty(MatchIndex)
                    Pathern_found={Pathern_found{:},Objects.FileType{count_p}};
                    if size(strmatch(Objects.FileType{count_p},Pathern_found),1) == size(Pathern_found,2)
                    else
                        No_Mean_Flag = 1;
                        break
                    end
                end
            end
            if No_Mean_Flag == 1
                break
            end
        end
        if No_Mean_Flag == 1
            button = questdlg('Different data components have been chosen. No summary mean file will be performed. Do you want to continue?',...
                'Continue Operation','Yes','No','Yes');
            if strcmp(button,'Yes')
                PATHNAME = uigetdir(Paths{1},'Choose the folder for performing multiple PSD');
                PATHNAME = [PATHNAME,SLASH_TYPE];
            elseif strcmp(button,'No')
                return
            end
        else
            FILENAME='Mean';
            [FILENAME, PATHNAME] = uiputfile([Paths{1},FILENAME,'.',Pathern_found{1},'.',FileType,'.pwd'], 'Save as');
        end
    end
    if PATHNAME~=0
        % check if the directory choosen already contains files with
        % the same name files
        Exist_Flag.value = 0;
        if NumFilesMatched > 1
            for cont =1:1:NumFilesMatched
                D=dir([PATHNAME,ListFilesMatched(cont).name,'.',FileType,'.pwd']);
                if ~isempty(D)
                    Exist_Flag.value = 1;
                    break
                end
            end
            if Exist_Flag.value == 1
                button = questdlg('Some files will be overwritten. Do you want to continue?',...
                    'Continue Operation','Yes','No','Yes');
                if strcmp(button,'Yes')
                    Exist_Flag.value = 1;
                elseif strcmp(button,'No')
                    Exist_Flag.value = 1;
                    return
                end
            end
        end
        % calculus starting
        h = waitbar(0,'Please wait...');
        set(h,'Position',[249 259.5 400 56.25])
        Psd_Sum=0;
        Psd_ConfInt_Sum1=0;
        Psd_ConfInt_Sum2=0;
        for cont =1:1:NumFilesMatched
            File_loaded=load_track([PATHNAME_TRACKS ListFilesMatched(cont).name],Objects.FileType);
            % Check if a warning string has issued by File_loaded
            if ischar(File_loaded)
                WARNSTRING = File_loaded;
                DLGNAME = '!!Warning!!';
                warndlg(WARNSTRING,DLGNAME);
                return
            end
            if cont==1
                slot_length = SlotFraction*Info_Multiple.SensTmax/File_loaded.Tsamp;
                slot_length_power2 = 2;
                while slot_length_power2 <= slot_length
                    slot_length_power2 = 2*slot_length_power2;
                end
                slot_length = slot_length_power2;
                Info_Multiple.length=slot_length;
            else
                slot_length=Info_Multiple.length;
            end
            File_loaded.type=Info_Multiple.type;
            File_loaded.Q=Info_Multiple.Q;
            File_loaded.Units=Info_Multiple.Units;
            File_loaded.SensT=Info_Multiple.SensT;
            File_loaded.SensN=Info_Multiple.SensN;
            File_loaded.Sens=Info_Multiple.Sens;
            File_loaded.SensU=Info_Multiple.SensU;
            File_loaded.SensTmax=Info_Multiple.SensTmax;
            if license('test','symbolic_toolbox')
                try
                    SensUnits=sym(File_loaded.SensU);
                    DataLogUnits=sym(File_loaded.Units);
                    DataUnits=sym('count');
                    UnitOfMes=DataLogUnits*DataUnits/SensUnits;
                catch
                    try
                        SensUnits=File_loaded.SensU;
                        DataLogUnits=File_loaded.Units;
                        DataUnits='count';
                        UnitOfMes=[DataLogUnits,'*',DataUnits,'/',SensUnits];
                    catch
                        WARNSTRING = 'Data Units problem';
                        DLGNAME = '!!Warning!!';
                        warndlg(WARNSTRING,DLGNAME);
                        return
                    end
                end
            else
                SensUnits=File_loaded.SensU;
                DataLogUnits=File_loaded.Units;
                DataUnits='count';
                UnitOfMes=[DataLogUnits,'*',DataUnits,'/',SensUnits];
            end
            Quantity_Orig=get_quant(char(UnitOfMes));
            switch lower(Quantity_Want.name)
                case 'auto'
                    Quantity_Want=Quantity_Orig;
                case 'dis'
                    Quantity_Want=get_quant('');
                case 'vel'
                    Quantity_Want=get_quant('/s');
                case 'acc'
                    Quantity_Want=get_quant('/s^2');
            end
            Order=Quantity_Orig.order-Quantity_Want.order;
            if Order < 0
                while Order < 0
                    [a,b]=deriv(File_loaded.data(:,1),...
                        File_loaded.data(:,2));
                    File_loaded.data=[a,b];
                    Order=Order+1;
                    if license('test','symbolic_toolbox')
                        UnitOfMes=UnitOfMes/sym('s');
                    else
                        UnitOfMes=[UnitOfMes,'/s'];
                    end
                end
            elseif Order > 0
                while Order > 0
                    b = cumtrapz(File_loaded.data(:,1),...
                        File_loaded.data(:,2));
                    a = File_loaded.data(:,1);
                    File_loaded.data=[a,b];
                    Order=Order-1;
                    if license('test','symbolic_toolbox')
                        UnitOfMes=UnitOfMes*sym('s');
                    else
                        UnitOfMes=[UnitOfMes,'*s'];
                    end
                end
            else
            end
            File_loaded.Datasetsize=size(File_loaded.data,1);
            % arg #1: Flag_mode for performing psd
            %         'p' is for doing psd
            %         'd' or anything else is for skipping psd
            % arg #2: Gain used for performing PSD, leaving K empty will force
            %         data2psd to use the values of Q and sensor sensitivity for
            %         yelding K
            % arg #3: method used for PSD
            % arg #4: TaperMode, window type for tapering
            % arg #5: slot_length
            % arg #6: Overlapping percent
            % arg #7: PSD Units (could be accelerations, velocities or displacements)
            % arg #8: Confidence value, must be between 0 and 1.
            if NumFilesMatched == 1
                FILENAMETOWRITE=FILENAME;
            else
                FILENAMETOWRITE=[ListFilesMatched(cont).name,'.',Quantity_Want.name,'.pwd'];
            end
            if Confidence > 0
                File_psd=data2psdfile(File_loaded,...
                    [PATHNAME,FILENAMETOWRITE],...
                    'p',...
                    [],...
                    Method,...
                    TaperMode,...
                    slot_length,...
                    Overlap,...
                    char(UnitOfMes),...
                    Confidence);
            else
                File_psd=data2psdfile(File_loaded,...
                    [PATHNAME,FILENAMETOWRITE],...
                    'p',...
                    [],...
                    Method,...
                    TaperMode,...
                    slot_length,...
                    Overlap,...
                    char(UnitOfMes));
            end
            if cont==1
                %save first file data for headers
                Psd_first=File_psd;
            end
            set(h,'Name',['File ',num2str(cont),' of ',num2str(NumFilesMatched),' ',PATHNAME,ListFilesMatched(cont).name]);
            if No_Mean_Flag == 1
            else
                Psd_Sum=File_psd.data(:,2)+Psd_Sum;
                if Confidence > 0
                    Psd_ConfInt_Sum1=File_psd.data(:,3)+Psd_ConfInt_Sum1;
                    Psd_ConfInt_Sum2=File_psd.data(:,4)+Psd_ConfInt_Sum2;
                else
                end
            end
            waitbar(cont/NumFilesMatched,h);
        end
        if No_Mean_Flag == 1
        else
            Psd_Sum=Psd_Sum/NumFilesMatched;
            Psd_Mean=Psd_first;
            Psd_Mean.data(:,2)=Psd_Sum;
            if Confidence > 0
                Psd_ConfInt_Sum1    =   Psd_ConfInt_Sum1/NumFilesMatched;
                Psd_ConfInt_Sum2    =   Psd_ConfInt_Sum2/NumFilesMatched;
                Psd_Mean.data(:,3)  =   Psd_ConfInt_Sum1;
                Psd_Mean.data(:,4)  =   Psd_ConfInt_Sum2;
                passa=data2psdfile(Psd_Mean,[PATHNAME,FILENAME],'d',[],Method,TaperMode,slot_length,Overlap,char(UnitOfMes),Confidence);
            else
                passa=data2psdfile(Psd_Mean,[PATHNAME,FILENAME],'d',[],Method,TaperMode,slot_length,Overlap,char(UnitOfMes));
            end
        end
        set_path({'DMP'},{PATHNAME},Objects.PathFileName);
        close(h);
        msgbox('Jobs done with no errors.','PSD performed!','help')
    else
        WARNSTRING = 'PSD data not saved on a file.';
        DLGNAME = '!!Warning!!';
        warndlg(WARNSTRING,DLGNAME)
    end
    set(MainFigure,'UserData',Objects);
    
elseif strcmp(action,'list');
    MainFigure	=	gcf;
    Objects		=	get(MainFigure,'UserData');
    FILENAME_TRACKS	=	Objects.MultipleFileName;
    PATHNAME_TRACKS	=	Objects.MultiplePathName;
    Index = get(Objects.G_MultiplePathNameText,'val');
    Lists = get(Objects.G_MultiplePathNameText,'string');
    FileSelected = Lists{Index};
    ClickType=get(MainFigure,'SelectionType');
    %checking if it's a text file orn not
    EXTENSION = FileSelected(end-2:end);
    if strcmp(whichcase(EXTENSION),'L')
        edit(Lists{Index}); % it is a text file and it will be edited
    elseif strcmp(whichcase(EXTENSION),'U')
        % it is a SAC file and it won't be edited;
    else
        % it is an UNKNOWN file nothing is performed;
    end
    File_loaded=load_track(Lists{Index},Objects.FileType);
    % Check if a warning string has issued by File_loaded
    if ischar(File_loaded)
        WARNSTRING = File_loaded;
        DLGNAME = '!!Warning!!';
        warndlg(WARNSTRING,DLGNAME);
        return
    end
    t=File_loaded.Tsamp*(0:1:size(File_loaded.data(:,1),1)-1);
    figure;
    h=plot(t,File_loaded.data(:,2));
    h_ax=axis;
    axis([t(1),t(end),h_ax(3),h_ax(4)]);
    legend(h,[File_loaded.comp,' component of ',File_loaded.sta,' site']);
    xlabel('t [s]');
    ylabel('counts');
    grid on;
    title(['First sample at: ',File_loaded.time,' ',File_loaded.date,...
        ', sampling rate: ',num2str(File_loaded.Tsamp),'s'...
        ', num. of samples: ',num2str(size(File_loaded.data(:,1),1))]);
    set(MainFigure,'UserData',Objects);
    
elseif strcmp(action,'singleview');
    MainFigure	=	gcf;
    Objects		=	get(MainFigure,'UserData');
    SortTypes=get(Objects.G_MultipleSortingPopUp,'string');
    SortSelect=get(Objects.G_MultipleSortingPopUp,'value');
    SortType=SortTypes{SortSelect};
    if ~isempty(opt1)
        PATHNAME=opt1{1};
        FILENAME=opt1{2};
    else
        FilterSpec='*.acc.pwd;*.vel.pwd;*.dis.pwd';
        [FILENAME, PATHNAME] = uigetfile([Paths{1},FilterSpec], 'Choose the data to view');
    end
    %load minimum data values for psd
    D=dir(Objects.NoiseRefMinFileName);
    if ~isempty(D)
        %[Tmin,Amin,Vmin,Smin]=textread(Objects.NoiseRefMinFileName,'%f %f %f %f');
        [P,A,B]=textread(Objects.NoiseRefMinFileName,'%f %f %f','commentstyle','shell');
        Hmin=P;
        Amin=A + B.*log10(Hmin);
        Vmin=Amin+20.0.*log10(Hmin/(2*pi));
        Dmin=Amin+20.0.*log10(Hmin.^2/(2*pi)^2);
    else
        Hmin = [0.1 0.17 0.40 0.80 1.24 2.40 4.30 5 6 10 12 15.6 21.9 31.6 45 70 101 154 328 600 10000 100000]';
        Amin = [-168 -166.7	-166.7 -169.2 -163.7 -148.6 -141.1 -141.1 -149.0 -163.8 -166.2 -162.1 -177.5 -185 -187.5 -187.5 -185.0 -185 -187.5 -184.4 -151.9 -103.1]';
        Vmin = [-203.9 -198.1 -190.6 -187.1 -177.8 -157.0 -144.4 -143.1	-149.4 -159.7 -160.6	-154.2	-166.7	-171.0	-170.4	-166.6	-160.9	-157.2	-153.1	-144.8	-87.9	-19.1]';
        Dmin = [-239.9 -229.4 -214.6 -214.5 -191.9 -165.3 -147.7 -145.1 -149.8 -155.7 -155.0 -146.3 -155.8 -156.9 -153.3 -145.6 -136.8 -129.4 -118.7 -105.2 -23.8 -65.0]';
    end
    %load maximum data values for psd
    D=dir(Objects.NoiseRefMaxFileName);
    if ~isempty(D)
        %[Tmax,Amax,Vmax,Smax]=textread(Objects.NoiseRefMaxFileName,'%f %f %f %f');
        [P,A,B]=textread(Objects.NoiseRefMaxFileName,'%f %f %f','commentstyle','shell');
        Hmax=P;
        Amax=A + B.*log10(Hmax);
        Vmax=Amax+20.0.*log10(Hmax/(2*pi));
        Dmax=Amax+20.0.*log10(Hmax.^2/(2*pi)^2);
    else
        Hmax = [0.10 0.22 0.32 0.80	3.80 4.60 6.30 7.90	15.40 20.0 354.80 10000	100000]';
        Amax = [-91.5 -97.4 -110.5 -120.0 -98.0 -96.5 -101.0 -113.5 -120.0 -138.5 -126.0 -80.1 -48.5]';
        Vmax = [-127.46 -126.52 -136.36 -137.90 -102.37 -99.21 -100.98 -111.51 -112.22 -128.44 -90.97  -16.10 35.53]';
        Dmax = [-163.43 -155.64 -162.22 -155.80 -106.73 -101.91 -100.95 -109.52 -104.43 -118.38 -55.93 47.93 119.56]';
    end
    [Paths,Flags]=get_path({'VMP'},Objects.PathFileName);
    if isempty(Paths)
        Paths={[pwd,SLASH_TYPE]};
    end
    if PATHNAME~=0
        if ischar(FILENAME) & ischar(PATHNAME)
            set_path({'VMP'},{PATHNAME},Objects.PathFileName);
            PSD_loaded=load_psd_track([PATHNAME FILENAME]);
            Objects.SinglePSD=PSD_loaded;
            Objects.FileName=FILENAME;
            Objects.PathName=PATHNAME;
        end
        % Only for a good viewing of psd data
        %fmin_deriv=PSD_loaded.data(2,1);
        %fmax_deriv=max(Fmin(end),Fmax(end));
        if PSD_loaded.data(1,1) == 0
            Axis_min_PSD=PSD_loaded.data(2,1);
        else
            Axis_min_PSD=PSD_loaded.data(1,1);
        end
        Limit = PSD_loaded.SensTmax;
        Axis_max_PSD=PSD_loaded.data(end,1);
        % prompting for plot preferences
        switch lower(SortType)
            case 'frequency'
                if size(PSD_loaded.data,2) == 4
                    % confidence values available
                    PSD_Data=   [PSD_loaded.data(:,1),PSD_loaded.data(:,2),PSD_loaded.data(:,3),PSD_loaded.data(:,4)];
                else
                    PSD_Data=   [PSD_loaded.data(:,1),PSD_loaded.data(:,2)];
                end
                Hmin    =   fliplr((1./Hmin)');
                Amin    =   fliplr(Amin');
                Vmin    =   fliplr(Vmin');
                Dmin    =   fliplr(Dmin');
                Hmax    =   fliplr((1./Hmax)');
                Amax    =   fliplr(Amax');
                Vmax    =   fliplr(Vmax');
                Dmax    =   fliplr(Dmax');
                Index_Limit=find(PSD_Data(:,1)<=1/Limit);
                H_left_lim  =  Axis_min_PSD(1);
                H_right_lim =  max(Hmin(end),Hmax(end));
                Hor_prompt  = {'Frequency min value [Hz]:',...
                    'Frequency max value [Hz]:'};
                Hor_def     = {num2str(Axis_min_PSD(1)),'10'};
                XLABEL='f [Hz]';
            case 'period'
                if size(PSD_loaded.data,2) == 4
                    % confidence values available
                    PSD_Data =   [PSD_loaded.data(:,1),PSD_loaded.data(:,2),PSD_loaded.data(:,3),PSD_loaded.data(:,4)];
                    if PSD_loaded.data(1,1) == 0
                        PSD_Data = [(fliplr(1./PSD_loaded.data(2:end,1)'))',...
                            (fliplr(PSD_loaded.data(2:end,2)'))',...
                            (fliplr(PSD_loaded.data(2:end,3)'))',...
                            (fliplr(PSD_loaded.data(2:end,4)'))'];
                    else
                        PSD_Data = [(fliplr(1./PSD_loaded.data(:,1)'))',...
                            (fliplr(PSD_loaded.data(:,2)'))',...
                            (fliplr(PSD_loaded.data(:,3)'))',...
                            (fliplr(PSD_loaded.data(:,4)'))'];
                    end
                else
                    if PSD_loaded.data(1,1) == 0
                        PSD_Data = [(fliplr(1./PSD_loaded.data(2:end,1)'))',(fliplr(PSD_loaded.data(2:end,2)'))'];
                    else
                        PSD_Data = [(fliplr(1./PSD_loaded.data(:,1)'))',(fliplr(PSD_loaded.data(:,2)'))'];
                    end
                end
                Hmin    =   Hmin';
                Amin    =   Amin';
                Vmin    =   Vmin';
                Dmin    =   Dmin';
                Hmax    =   Hmax';
                Amax    =   Amax';
                Vmax    =   Vmax';
                Dmax    =   Dmax';
                Index_Limit=find(PSD_Data(:,1)>=Limit);
                H_left_lim  =   1/(max(Hmin(end),Hmax(end)));
                H_right_lim =   1/Axis_min_PSD;
                Hor_prompt = {'Period min value [s]:',...
                    'Period max value [s]:'};
                Hor_def = {'0.1',num2str(1/Axis_min_PSD(1))};
                XLABEL='P [s]';
        end
        QuantType=get_quant(PSD_loaded.PSDUnits{:});
        switch lower(QuantType.name)
            case 'acc'
                PSD_Max_Ref = Amax;
                PSD_Min_Ref = Amin;
                switch lower(SortType)
                    case 'frequency'
                        Vert_def  = {'-200','-70'};
                        PosText1  = [0.15,0.90];
                        PosText2  = [0.35,0.90];
                        PosLegend = [0.455,0.115];
                    case 'period'
                        Vert_def  = {'-200','-70'};
                        PosText1  = [0.35,0.90];
                        PosText2  = [0.55,0.90];
                        PosLegend = [0.2,0.115];
                end
            case 'vel'
                PSD_Max_Ref = Vmax;
                PSD_Min_Ref = Vmin;
                switch lower(SortType)
                    case 'frequency'
                        Vert_def  = {'-220','-50'};
                        PosText1  = [0.35,0.90];
                        PosText2  = [0.55,0.90];
                        PosLegend = [0.2,0.12];
                    case 'period'
                        Vert_def  = {'-220','-50'};
                        PosText1  = [0.15,0.90];
                        PosText2  = [0.35,0.90];
                        PosLegend = [0.45,0.12];
                end
            case 'dis'
                PSD_Max_Ref = Dmax;
                PSD_Min_Ref = Dmin;
                switch lower(SortType)
                    case 'frequency'
                        Vert_def  = {'-250','-25'};
                        PosText1  = [0.4,0.90];
                        PosText2  = [0.6,0.90];
                        PosLegend = [0.2,0.15];
                    case 'period'
                        Vert_def  = {'-250','-25'};
                        PosText1  = [0.15,0.90];
                        PosText2  = [0.35,0.90];
                        PosLegend = [0.45,0.12];
                end
        end
        Vert_prompt = {'PSD min value [dB]:',...
            'PSD max value [dB]:'};
        prompt = {'Enter title',...
            Hor_prompt{1:2},...
            Vert_prompt{1:2}};
        def     = {['PSD of the ',char(Objects.SinglePSD.comp),' component, day: ',char(Objects.SinglePSD.date),...
            ', start time:',char(Objects.SinglePSD.time)],...
            Hor_def{1:2},Vert_def{1:2}};
        if size(PSD_loaded.data,2) == 4
            % Confidence intervals available
            CONFIDENCEPROMPT    =   'Do you want to plot confidence bounds?:';
            CONFIDENCEDEFANS    =   'N';
            prompt  = {prompt{:},CONFIDENCEPROMPT};
            def     = {def{:},CONFIDENCEDEFANS};
        else
        end
        dlg_title = 'Preferences';
        num_lines= 1;
        answers=inputdlg(prompt,dlg_title,num_lines,def);
        if isempty(answers)
            WARNSTRING = ['No preferences selected: PSD plot not performed.'];
            DLGNAME = '!!Warning!!';
            warndlg(WARNSTRING,DLGNAME);
            return
        end
        if size(PSD_loaded.data,2) == 4
            % Confidence intervals available
            NewAxis = (str2num(strvcat(answers{2:end-1})))';
        else
            NewAxis = (str2num(strvcat(answers{2:end})))';
        end
        TextTitle=answers{1};
        % plotting single PSD
        % Using TAGS is useful for recovering plots and other graphic
        % handles during the multiplot procedure
        % h1    =   PLOT_PSD_TRU    : for main psd plot;
        % h0    =   PLOT_PSD_UNT    : for main untrustworthy psd plot;
        % h12   =   PLOT_CON_TRU2   : for main Confidence upper plot;
        % h11   =   PLOT_CON_TRU1   : for main Confidence lower plot;
        % h01   =   PLOT_CON_UNT1   : for main untrustworthy Confidence upper plot;
        % h02   =   PLOT_CON_UNT2   : for main untrustworthy Confidence lower plot;
        % h3    =   PLOT_PSD_MAXR   : for main psd reference max plot;
        % h2    =   PLOT_PSD_MINR   : for main psd reference min plot;
        CharSize=0.018;
        h=figure;
        HANDLE_OLD_PSD_FIG=findobj('-regexp','Name','PSD_Single');
        if isempty(HANDLE_OLD_PSD_FIG)
            TAG=1;
        else
            HTAGS=str2num(char(get(HANDLE_OLD_PSD_FIG,'Tag')));
            NUMFIGMAX = max(HTAGS);
            ARRFIGMAX = 1:1:NUMFIGMAX;
            HANDLE_AVAL=setdiff(ARRFIGMAX,HTAGS);
            if isempty(HANDLE_AVAL)
                TAG=NUMFIGMAX+1;
            else
                TAG=HANDLE_AVAL(1);
            end
        end
        PSD_FIG_NAME = ['PSD_Single:',num2str(TAG)];
        set(h,'Name',PSD_FIG_NAME,'NumberTitle','off','Tag',num2str(TAG));
        h_ax.num=gca;
        h_ax.pos=get(h_ax.num,'position');
        h_ax.scale=h_ax.pos(4);
        h0=semilogx(PSD_Data(Index_Limit,1),10*log10(PSD_Data(Index_Limit,2)),'b--');
        hold on;
        if (size(PSD_loaded.data,2) == 4) && strcmp(lower(answers{6}(1)),'y')
            % Confidence intervals available
            h01=semilogx(PSD_Data(Index_Limit,1),10*log10(PSD_Data(Index_Limit,3)),'c--');
            set(h01,'Tag','PLOT_CON_UNT1');
            h02=semilogx(PSD_Data(Index_Limit,1),10*log10(PSD_Data(Index_Limit,4)),'c--');
            set(h02,'Tag','PLOT_CON_UNT2');
        end
        h0=semilogx(PSD_Data(Index_Limit,1),10*log10(PSD_Data(Index_Limit,2)),'b--');
        set(h0,'Tag','PLOT_PSD_UNT');
        switch lower(SortType)
            case 'frequency'
                if (size(PSD_loaded.data,2) == 4) && strcmp(lower(answers{6}(1)),'y')
                    % Confidence intervals available
                    h11=semilogx(PSD_Data(Index_Limit(end):end,1),10*log10(PSD_Data(Index_Limit(end):end,3)),'c');
                    set(h11,'Tag','PLOT_CON_TRU1');
                    h12=semilogx(PSD_Data(Index_Limit(end):end,1),10*log10(PSD_Data(Index_Limit(end):end,4)),'c');
                    set(h12,'Tag','PLOT_CON_TRU2');
                end
                h1=semilogx(PSD_Data(Index_Limit(end):end,1),10*log10(PSD_Data(Index_Limit(end):end,2)),'b');
                set(h1,'Tag','PLOT_PSD_TRU');
            case 'period'
                if (size(PSD_loaded.data,2) == 4) && strcmp(lower(answers{6}(1)),'y')
                    % Confidence intervals available
                    h11=semilogx(PSD_Data(1:Index_Limit(1),1),10*log10(PSD_Data(1:Index_Limit(1),3)),'c');
                    set(h11,'Tag','PLOT_CON_TRU1');
                    h12=semilogx(PSD_Data(1:Index_Limit(1),1),10*log10(PSD_Data(1:Index_Limit(1),4)),'c');
                    set(h12,'Tag','PLOT_CON_TRU2');
                end
                h1=semilogx(PSD_Data(1:Index_Limit(1),1),10*log10(PSD_Data(1:Index_Limit(1),2)),'b');
                set(h1,'Tag','PLOT_PSD_TRU');
        end
        h2=semilogx(Hmin,PSD_Min_Ref,'g-');
        set(h2,'Tag','PLOT_PSD_MINR');
        h3=semilogx(Hmax,PSD_Max_Ref,'r-');
        set(h3,'Tag','PLOT_PSD_MAXR');
        if (size(PSD_loaded.data,2) == 4) && strcmp(lower(answers{6}(1)),'y')
            % Confidence intervals available
            hlegend.num=legend([h3,h12,h1,h0,h11,h2],'PSD max reference',...
                ['Upper conf.  bound level ',upper(num2str(100*Objects.SinglePSD.Confidence)),'%'],...
                ['True PSD of ',upper(char(Objects.SinglePSD.sta))],...
                ['Untrustworthy PSD of ',upper(char(Objects.SinglePSD.sta))],...
                ['Lower conf. bound level ',upper(num2str(100*Objects.SinglePSD.Confidence)),'%'],...
                'PSD min reference',2);
            set(h01,'linewidth',1);
            set(h02,'linewidth',1);
            set(h11,'linewidth',1);
            set(h12,'linewidth',1);
        else
            hlegend.num=legend([h3,h1,h0,h2],'PSD max reference',...
                ['True PSD of ',upper(char(Objects.SinglePSD.sta))],...
                ['Untrustworthy PSD of ',upper(char(Objects.SinglePSD.sta))],...
                'PSD min reference');
        end
        set(h0,'linewidth',1);
        set(h1,'linewidth',1);
        set(h2,'linewidth',2);
        set(h3,'linewidth',2);
        axis_old=axis;
        grid on;  zoom on;
        title(TextTitle,'FontName','helvetica','FontUnits','normalized','FontSize',1.5*CharSize,'FontWeight','bold','color','blue');
        xlabel(XLABEL,'FontName','helvetica','FontUnits','normalized','FontSize',CharSize,'FontWeight','bold');
        %ylabel(['dB ', PSD_loaded.PSDUnits{:},'/Hz'],'FontName','helvetica','FontUnits','normalized','FontSize',CharSize,'FontWeight','bold');
        ylabel(['dB ', PSD_loaded.PSDUnits{:}],'FontName','helvetica','FontUnits','normalized','FontSize',CharSize,'FontWeight','bold');
        hlegend.pos=get(hlegend.num,'position');
        set(hlegend.num,'Position',[PosLegend,hlegend.pos(3:4)]);
        set(hlegend.num,'FontName','helvetica','FontWeight','bold');
        M=Objects.SinglePSD.Datasetsize;
        L=Objects.SinglePSD.Length;
        NOVERLAP=Objects.SinglePSD.Length*Objects.SinglePSD.Overlap;
        K = (M-NOVERLAP)/(L-NOVERLAP); % number of segments yelded
        K=fix(K);
        set(h,'Units','normalized');
        NewAxes=axes('position',[0 0 1 1],'visible','off','Units','normalized');
        Text1={'- Datalogger';...
            ['  Type: ',char(Objects.SinglePSD.type)];...
            ['  Sampling Rate: ',num2str(1/Objects.SinglePSD.Tsamp),'S/s'];...
            ['  Q: ',num2str(Objects.SinglePSD.Q),char(Objects.SinglePSD.Units)];...
            ' ';...
            '-  Sensor';...
            ['  Type: ',char(Objects.SinglePSD.SensT)];...
            ['  Sensitivity: ',num2str(Objects.SinglePSD.Sens),char(Objects.SinglePSD.SensU)];...
            ['  Period: ',num2str(Objects.SinglePSD.SensTmax),'s']};
        Text2={'- Calculus method';...
            ['  Type: ',char(Objects.SinglePSD.Method)];...
            ['  Tapering: ',char(Objects.SinglePSD.Taper)];...
            ['  Total data set size: ',num2str(Objects.SinglePSD.Datasetsize),' samples, ',num2str(Objects.SinglePSD.Tsamp*Objects.SinglePSD.Datasetsize),'s'];...
            ['  Segments size: ',num2str(Objects.SinglePSD.Length),' samples, ',num2str(Objects.SinglePSD.Tsamp*Objects.SinglePSD.Length),'s'];...
            ['  Overlapping: ',num2str(100*Objects.SinglePSD.Overlap),'%'];...
            ['  Number of segments: ',num2str(K)]};
        if (size(PSD_loaded.data,2) == 4) && strcmp(lower(answers{6}(1)),'y')
            TEXTCONFIDENCE = ['  Confidence level: ',num2str(100*Objects.SinglePSD.Confidence),'%'];
            Text2 = strvcat(Text2{:},TEXTCONFIDENCE);
            Text2 = cellstr(Text2);
        else
        end
        htext1=text(PosText1(1),PosText1(2),Text1);
        htext2=text(PosText2(1),PosText2(2),Text2);
        set(htext1,'FontName','helvetica','FontUnits','normalized','FontSize',h_ax.scale*CharSize,'FontWeight','bold',...
            'visible','on','string',Text1,'HorizontalAlignment','left','VerticalAlignment','top','Interpreter','none');
        set(htext2,'FontName','helvetica','FontUnits','normalized','FontSize',h_ax.scale*CharSize,'FontWeight','bold',...
            'visible','on','string',Text2,'HorizontalAlignment','left','VerticalAlignment','top','Interpreter','none');
        set(h_ax.num,'FontName','helvetica','FontUnits','normalized','FontSize',CharSize,'FontWeight','bold');
        axis(h_ax.num,NewAxis);
        set(MainFigure,'UserData',Objects);
    end
    
elseif strcmp(action,'multipleview');
    MainFigure	=	gcf;
    Objects		=	get(MainFigure,'UserData');
    SortTypes=get(Objects.G_MultipleSortingPopUp,'string');
    SortSelect=get(Objects.G_MultipleSortingPopUp,'value');
    SortType=SortTypes{SortSelect};
    [Paths,Flags]=get_path({'VMP'},Objects.PathFileName);
    if isempty(Paths)
        Paths={[pwd,SLASH_TYPE]};
    end
    PATHNAME = uigetdir(Paths{1},'Choose the data dir to explore');
    PATHNAME=[PATHNAME,SLASH_TYPE];
    if PATHNAME (~0)
        List_all_pwd=dir([PATHNAME,'*.pwd']);
        List_last_pwd=[];
        if isempty(List_all_pwd)
            for  i = 1:size(Objects.FileType,2)
                FileTypeToPrint{i}=['"',Objects.FileType{i},'.pwd", '];
            end
            WARNSTRING = ['No data of type: ',FileTypeToPrint{:},' available in this directory. ',...
                'Impossible to perform a plot.'];
            DLGNAME = '!!Warning!!';
            warndlg(WARNSTRING,DLGNAME)
            return
        end
        Types={'dis','vel','acc'};
        ListFiles=[];
        % the following routines will help in sorting the data files by
        % sensor components and by quantity (vel, acc, dis)
        for i = 1:size(Types,2)
            ListByTypes=dir([PATHNAME,'*.',Types{i},'.pwd']);
            if ~isempty(ListByTypes)
                for j = 1:size(Objects.FileType,2)
                    for k = 1:size(ListByTypes,1)
                        if ~isempty(strfind(ListByTypes(k).name,['.',Objects.FileType{j},'.']))
                            ListFiles=[ListFiles;ListByTypes(k)];
                        end
                    end
                end
            end
        end
        % remaining pwd file list will be added in queue to the main list
        for i = 1:size(List_all_pwd,1)
            Flags_found=[];
            for j = 1:size(ListFiles,1)
                Flags_found=[Flags_found,strcmp(List_all_pwd(i).name,ListFiles(j).name)];
            end
            if sum(Flags_found) == 0
                List_last_pwd=[List_last_pwd;List_all_pwd(i)];
            end
        end
        ListFiles=[ListFiles;List_last_pwd];
    else
        WARNSTRING = ['No data directory selected. Plot not performed.'];
        DLGNAME = '!!Warning!!';
        warndlg(WARNSTRING,DLGNAME)
        ListFiles=[];
    end
    if ~isempty(ListFiles)
        if size(ListFiles,1) > 0
            if ischar(ListFiles(1).name) & ischar(PATHNAME)
                set_path({'VMP'},{PATHNAME},Objects.PathFileName);
            end
            StringDays='';
            Z=[];
            str = {ListFiles.name};
            [s,v] = listdlg('PromptString','Select the file:','SelectionMode','multiple','ListString',str,'ListSize',[300 300]);
            if size(ListFiles(s),1) > 1
                ListFiles=ListFiles(s);
                % multiple PSD plot will be performed
                NumFiles=size(ListFiles,1);
                Exit_Flag=0;
                Pathern_found={};
                % check files chosen for better understand if they are of the
                % same type (or if they came from the same sensor
                % component)???????????????????????????????????????????????
                % ?????????????????????????????????????????????????????????
                % ?????????????????????????????????????????????????????????
                % ?
                for cont_f = 1:NumFiles
                    for count_p = 1:size(Objects.FileType,2)
                        Pathern=['.',Objects.FileType{count_p},'.'];
                        MatchIndex=strfind(ListFiles(cont_f).name,Pathern);
                        if ~isempty(MatchIndex)
                            Pathern_found={Pathern_found{:},Objects.FileType{count_p}};
                            if size(strmatch(Objects.FileType{count_p},Pathern_found,'exact'),1) == size(Pathern_found,2)
                            else
                                Exit_Flag = 1;
                                break
                            end
                        end
                    end
                    if Exit_Flag == 1
                        break
                    end
                end
                if Exit_Flag == 1
                    WARNSTRING = 'Multiple plot of different components is not allowed';
                    DLGNAME = '!!Warning!!';
                    warndlg(WARNSTRING,DLGNAME);
                    return
                else
                end
                TimeHours=[];
                % recover infos from the header of the first file selected
                PSD_First=load_psd_track([PATHNAME ListFiles(1).name]);
                QuantType=get_quant(PSD_First.PSDUnits{:});
                switch lower(SortType)
                    case 'frequency'
                        Hor_prompt  = {'Frequency min value [Hz]:',...
                            'Frequency max value [Hz]:'};
                        YLABEL='f [Hz]';
                    case 'period'
                        Hor_prompt = {'Period min value [s]:',...
                            'Period max value [s]:'};
                        YLABEL='P [s]';
                end
                for cont = 1:NumFiles
                    PSD_Multi(cont)=load_psd_track([PATHNAME ListFiles(cont).name]);
                    % shift the f=0 data for a good log plotting
                    if PSD_Multi(cont).data(1,1) == 0
                        PSD_Multi(cont).data=PSD_Multi(cont).data(2:end,:);
                    else
                    end
                    % build up the data for the 3D picture
                    switch lower(SortType)
                        case 'frequency'
                            PSD_Data = [PSD_Multi(cont).data(:,1),PSD_Multi(cont).data(:,2)];
                        case 'period'
                            PSD_Data = [(fliplr(1./PSD_Multi(cont).data(:,1)'))',(fliplr(PSD_Multi(cont).data(:,2)'))'];
                    end
                    % build up horizontal and some vertical limits
                    if cont == 1
                        Hor_min = min(PSD_Data(:,1));
                        Hor_max = max(PSD_Data(:,1));
                        Max_PSD=max(10*log10(PSD_Data(1:end,2)));
                        Min_PSD=min(10*log10(PSD_Data(1:end,2)));
                    else
                        if Hor_min > min(PSD_Data(:,1))
                            Hor_min = min(PSD_Data(:,1));
                        end
                        if Hor_max < max(PSD_Data(:,1))
                            Hor_max = max(PSD_Data(:,1));
                        end
                        if max(10*log10(PSD_Data(1:end,2))) > Max_PSD
                            Max_PSD = max(10*log10(PSD_Data(1:end,2)));
                        end
                        if min(10*log10(PSD_Data(1:end,2))) < Min_PSD
                            Min_PSD = min(10*log10(PSD_Data(1:end,2)));
                        end
                    end
                    % build up the day string label for the 3D picture
                    if size(strmatch(PSD_Multi(cont).date,StringDays,'exact'),1)<=0
                        StringDays=strvcat(StringDays,char(PSD_Multi(cont).date));
                    end
                    % build up data to plot
                    Z=[Z,10*log10(PSD_Data(1:end,2))];
                    Pass=char(PSD_Multi(cont).time);
                    INDEX_Pass=findstr(Pass,':');
                    Pass=Pass(1:INDEX_Pass(1)-1);
                    TimeHours=[TimeHours,str2num(Pass)];
                end
                Hor_def   = {num2str(Hor_min),num2str(Hor_max)};
                % handle hours through multiple days
                NumberOfSessions=NumFiles;
                TimeToPlot=1:ceil(NumFiles/24):NumFiles;
                TimeHours=TimeHours(1:ceil(NumFiles/24):end);
                % 3D plot and labeling
                [X,Y]=meshgrid(1:NumFiles,PSD_Data(1:end,1));
                prompt = {'Enter title',...
                    'Days, min No:',...
                    'Days, max No:'...
                    Hor_prompt{1:2},...
                    'PSD min value [dB]:',...
                    'PSD max value [dB]:'};
                dlg_title = 'Enter plot limits:';
                num_lines= 1;
                TextTitle=['Power Spectral Density Evolution of the ',char(PSD_Multi(1).comp),' component at ',upper(char(PSD_Multi(1).sta)),' site'];
                def     = {TextTitle,...
                    num2str(X(1)),num2str(X(end)),...
                    Hor_def{1:2},...
                    num2str(Min_PSD),num2str(Max_PSD)};
                answers  = inputdlg(prompt,dlg_title,num_lines,def);
                if isempty(answers)
                    WARNSTRING = ['No preferences selected: PSD plot not performed.'];
                    DLGNAME = '!!Warning!!';
                    warndlg(WARNSTRING,DLGNAME);
                    return
                else
                end
                TextTitle = answers{1};
                NewAxis = (str2num(strvcat(answers{2:end})))';
                X_min_index = min(find(X(1,:)>=NewAxis(1)));
                X_max_index = max(find(X(1,:)<=NewAxis(2)));
                Y_min_index = min(find(Y(:,1)>=NewAxis(3)));
                Y_max_index = max(find(Y(:,1)<=NewAxis(4)));
                h=figure;
                set(h,'Name','PSD_Multiple');
                h_ax=gca;
                CharSize_Ori=0.014;
                CharFactor=0.82;
                CharSize=CharSize_Ori/CharFactor;
                h_surfc=surfc(X(1,X_min_index:X_max_index),...
                    Y(Y_min_index:Y_max_index,1),...
                    Z(Y_min_index:Y_max_index,X_min_index:X_max_index));
                Zlim_ori = get(gca,'zlim');
                Zlim_ori = Zlim_ori(1);
                for i = 2:length(h_surfc);
                    get(h_surfc(i),'Zdata');
                    newz = get(h_surfc(i),'Zdata') - (Zlim_ori-NewAxis(5));
                    set(h_surfc(i),'Zdata',newz)
                end
                colormap('jet');
                H_cb=colorbar;
                set(H_cb,'position',[0.88 0.11 0.06 0.82]);
                Title_H_cb=get(H_cb,'title');
                set(Title_H_cb,'string','dB','FontName','helvetica','FontUnits','normalized','FontSize',CharSize,'FontWeight','bold');
                set(H_cb,'FontName','helvetica','FontUnits','normalized','FontSize',CharSize,'FontWeight','bold');
                hidden on;
                shading interp;
                view([124 40]);
                if size(StringDays,1)<=1
                    xlabel(strvcat('Hours of the day:',StringDays),'FontName','helvetica','FontUnits','normalized','FontSize',CharSize,'FontWeight','bold');
                else
                    xlabel(strvcat('Hours of the days:',StringDays),'FontName','helvetica','FontUnits','normalized','FontSize',CharSize,'FontWeight','bold');
                end
                ylabel(YLABEL,'FontName','helvetica','FontUnits','normalized','FontSize',CharSize,'FontWeight','bold');
                %zlabel(['dB ', PSD_Multi(1).PSDUnits{:},'/Hz'],'FontName','helvetica','FontUnits','normalized','FontSize',CharSize,'FontWeight','bold');
                zlabel(['dB ', PSD_Multi(1).PSDUnits{:}],'FontName','helvetica','FontUnits','normalized','FontSize',CharSize,'FontWeight','bold');
                Title=title(TextTitle,'FontUnits','normalized','FontSize',2*CharSize,'FontWeight','bold','color','blue');
                set(Title,'units','normalized','position',[0.45 1.04 0])
                set(h_ax,'xtick',TimeToPlot);
                set(h_ax,'XTickLabel',TimeHours);
                set(h_ax,'YScale','log');
                set(h_ax,'position',[0.18 0.1 0.62 0.82]);
                axis(h_ax,NewAxis);
                M=PSD_Multi(1).Datasetsize;
                L=PSD_Multi(1).Length;
                NOVERLAP=PSD_Multi(1).Length*PSD_Multi(1).Overlap;
                K = (M-NOVERLAP)/(L-NOVERLAP); % number of segments yelded
                K=fix(K);
                set(h,'Units','normalized');
                NewAxes_Height=0.4;
                NewAxes=axes('position',[0.01 0.73 0.3 NewAxes_Height],'visible','off','units','normalized');
                Text_1={'- Calculus method';...
                    ['  Type: ',char(PSD_Multi(1).Method),' sessions'];...
                    ['  Tapering: ',char(PSD_Multi(1).Taper)];...
                    ['  Session data set size: '];...
                    ['          ',num2str(PSD_Multi(1).Datasetsize),' samples, '];...
                    ['          ',num2str(PSD_Multi(1).Tsamp*PSD_Multi(1).Datasetsize),'s'];...
                    ['  Number of sessions: ',num2str(NumberOfSessions)];...
                    ['  Segments size: '];...
                    ['          ',num2str(PSD_Multi(1).Length),' samples, '];...
                    ['          ',num2str(PSD_Multi(1).Tsamp*PSD_Multi(1).Length),'s'];...
                    ['  Overlapping: ',num2str(100*PSD_Multi(1).Overlap),'%'];...
                    ['  Number of segments: ',num2str(K)];...
                    ' ';...
                    '- Datalogger';...
                    ['  Type: ',char(PSD_Multi(1).type)];...
                    ['  Sampling Rate: ',num2str(1/PSD_Multi(1).Tsamp),'S/s'];...
                    ['  Q: ',num2str(PSD_Multi(1).Q),char(PSD_Multi(1).Units)];...
                    ' ';...
                    '- Sensor';...
                    ['  Type: ',char(PSD_Multi(1).SensT)];...
                    ['  Sensitivity: ',num2str(PSD_Multi(1).Sens),char(PSD_Multi(1).SensU)];...
                    ['  Period: ',num2str(PSD_Multi(1).SensTmax),'s']};
                h1_text=text(-0.8,6.1,Text_1);
                set(h1_text,'units','normalized','position',[0,0]);
                set(h1_text,'FontUnits','normalized','FontSize',CharSize_Ori/NewAxes_Height,'FontName','helvetica','FontWeight','bold','visible','on','HorizontalAlignment','left');
                set(h_ax,'FontName','helvetica','FontUnits','normalized','FontSize',CharSize,'FontWeight','bold');
                set(MainFigure,'UserData',Objects);
            else
                if size(ListFiles(s),1) == 1
                    psdtool('singleview',{PATHNAME ListFiles(s).name});
                else
                    WARNSTRING = ['No data selected. Plot not performed.'];
                    DLGNAME = '!!Warning!!';
                    warndlg(WARNSTRING,DLGNAME);
                end
            end
        end
    end
    
elseif strcmp(action,'compare');
    MainFigure	=	gcf;
    Objects		=	get(MainFigure,'UserData');
    FINDM=findobj('Name','PSD_Multiple');
    % get all the graphic figures that has the title: "PSD_Single"
    %FINDS=findobj('Name','PSD_Single');
    FINDS=findobj('-regexp','Name','PSD_Single');
    if isempty(FINDS)
        warndlg('Warning: nothing to compare, plot something first.','No plots')
        return
    end
    STR={};
    for i = 1:size(FINDS,1)
        %for each figure, that has a "PSD_Single" title, recover its
        %children
        PSD_CHILDREN=get(FINDS(i),'Children');
        % the children are of three types:
        % N.1   Text Children (for the text around the plot (e.g. extra info
        %       as  datalogger, sensor, method infos
        % N.2 the legend axexs (use the 'Tag' property to get this handle
        % N.3 the plots axexs handle but with the TAGS inserted at the
        % singleplot functions you also have that:
        % PLOT_PSD_TRU    : for main psd plot;
        % PLOT_PSD_UNT    : for main untrustworthy psd plot;
        % PLOT_CON_TRU2   : for main Confidence upper plot;
        % PLOT_CON_TRU1   : for main Confidence lower plot;
        % PLOT_CON_UNT1   : for main untrustworthy Confidence upper plot;
        % PLOT_CON_UNT2   : for main untrustworthy Confidence lower plot;
        % PLOT_PSD_MAXR   : for main psd reference max plot;
        % PLOT_PSD_MINR   : for main psd reference min plot;
        PSD_CHILDREN_PLOTS = get(PSD_CHILDREN(3),'Children');
        TEXT_PLOTS  =   get(PSD_CHILDREN(1),'Children');
        TEXT_PLOT   =   get(TEXT_PLOTS(2),'String');
        DATALOGGER_LEGEND   =   TEXT_PLOT{2}(9:end);
        TITLE_PLOT = get(get(PSD_CHILDREN(3),'Title'),'String');
        COMPONENT_LEGEND    = TITLE_PLOT(12:14);
        DAY_LEGEND          = TITLE_PLOT(32:41);
        TIME_LEGEND         = TITLE_PLOT(55:end);
        SENSOR_LEGEND       = TEXT_PLOT{7}(9:end);
        SITENAME_LEGEND =   get(PSD_CHILDREN_PLOTS(3),'DisplayName');
        SITENAME_LEGEND =   [get(FINDS(i),'Name'),'-',SITENAME_LEGEND(13:end)];
        FINAL_NAME_LIST =   [SITENAME_LEGEND,': ',...
            DAY_LEGEND,'-',...
            TIME_LEGEND,', ',...
            DATALOGGER_LEGEND,', ',...
            SENSOR_LEGEND,', ',...
            COMPONENT_LEGEND];
        STR={STR{:},FINAL_NAME_LIST};
    end
    [SELECTION,OK] = listdlg('PromptString','Select the file:','SelectionMode','multiple','ListString',STR,'ListSize',[350 300]);
    if OK == 0
        return
    end
    H1=figure;
    CharSize=0.036;
    H_TRUE_PLOTS=[];
    H_TRUE_CON_PLOTS1=[];
    H_TRUE_CON_PLOTS2=[];
    H_UNTR_CON_PLOTS1=[];
    H_UNTR_CON_PLOTS2=[];
    H_TRUE_LEGEND={};
    X_LIM_FIN=[];
    Y_LIM_FIN=[];
    FINAL_XLABEL=[];
    FINAL_YLABEL=[];
    PSDMAXREFEXIST = 0;
    PSDMINREFEXIST = 0;
    PSDCOLORTRACK=[0,0,1];
    PSDCOLORSTEP=0.4;
    for i = 1:size(FINDS(SELECTION),1)
        %for each plot that is a PSD_Single recover the data plots
        PSD_CHILDREN=get(FINDS(SELECTION(i)),'Children');
        PSD_CHILDREN_PLOTS = get(PSD_CHILDREN(3),'Children');
        X_LIM_TMP=get(PSD_CHILDREN(3),'Xlim');
        Y_LIM_TMP=get(PSD_CHILDREN(3),'Ylim');
        if isempty(X_LIM_FIN)
            X_LIM_FIN=X_LIM_TMP;
        else
            if X_LIM_TMP(1)>=X_LIM_FIN(1)
                X_LIM_FIN(1)=X_LIM_TMP(1);
            else
            end
            if X_LIM_TMP(2)<=X_LIM_FIN(2)
                X_LIM_FIN(2)=X_LIM_TMP(2);
            else
            end
        end
        if isempty(Y_LIM_FIN)
            Y_LIM_FIN=Y_LIM_TMP;
        else
            if Y_LIM_TMP(1)>=Y_LIM_FIN(1)
                Y_LIM_FIN(1)=Y_LIM_TMP(1);
            else
            end
            if Y_LIM_TMP(2)<=Y_LIM_FIN(2)
                Y_LIM_FIN(2)=Y_LIM_TMP(2);
            else
            end
        end
        FINAL_XLABEL_TMP    =   get(get(PSD_CHILDREN(3),'XLabel'),'String');
        FINAL_YLABEL_TMP    =   get(get(PSD_CHILDREN(3),'YLabel'),'String');
        if isempty(FINAL_XLABEL)
            FINAL_XLABEL=FINAL_XLABEL_TMP;
        else
            if strcmp(FINAL_XLABEL,FINAL_XLABEL_TMP);
            else
                close(H1);
                errordlg('Error: type of data (Hz and s) not consistent','Bad matching')
                return
            end
        end
        if isempty(FINAL_YLABEL)
            FINAL_YLABEL=FINAL_YLABEL_TMP;
        else
            if strcmp(FINAL_YLABEL,FINAL_YLABEL_TMP);
            else
                close(H1);
                errordlg('Error: magnitude of different kinds','Bad matching')
                return
            end
        end
        TEXT_PLOTS      =       get(PSD_CHILDREN(1),'Children');
        TEXT_PLOT1      =       get(TEXT_PLOTS(1),'String');
        METHOD_LEGEND   =       TEXT_PLOT1{2}(9:end);
        TAPERING_LEGEND =       TEXT_PLOT1{3}(13:end);
        SAMPLES_LEGEND  =       TEXT_PLOT1{4}(findstr(TEXT_PLOT1{4},':')+2:...
            findstr(TEXT_PLOT1{4},'samples')-2);
        DURATION_LEGEND =       TEXT_PLOT1{4}(findstr(TEXT_PLOT1{4},',')+2:end);
        SAMP_SEG_LEGEND =       TEXT_PLOT1{5}(findstr(TEXT_PLOT1{5},':')+2:...
            findstr(TEXT_PLOT1{5},'samples')-2);
        DURA_SEG_LEGEND =       TEXT_PLOT1{5}(findstr(TEXT_PLOT1{5},',')+2:end);
        OVERLAP_LEGEND  =       TEXT_PLOT1{6}(16:end);
        NUM_SEG_LEGEND  =       TEXT_PLOT1{7}(23:end);
        if size(TEXT_PLOT1,1) == 8
            CONF_LEGEND = [', Cnf.',TEXT_PLOT1{8}(21:end)];
        else
            CONF_LEGEND='';
        end
        CALCULUS_LEGEND =       ['DATA: ',DURATION_LEGEND,'/',SAMPLES_LEGEND,'S; ',...
            'Win(',TAPERING_LEGEND,'): ',NUM_SEG_LEGEND,'Seg/',DURA_SEG_LEGEND,'/',SAMP_SEG_LEGEND,'S; ',...
            METHOD_LEGEND,': Ovr.',OVERLAP_LEGEND,CONF_LEGEND];
        TEXT_PLOT2   =   get(TEXT_PLOTS(2),'String');
        DATALOGGER_LEGEND   =   [TEXT_PLOT2{2}(9:end),'(',TEXT_PLOT2{3}(18:end),')'];
        SENSOR_LEGEND       =   TEXT_PLOT2{7}(9:end);
        for j = 1:size(PSD_CHILDREN_PLOTS,1)
            % N.3 the plots axexs handle but with the TAGS inserted at the
            % singleplot functions you also have that:
            % PLOT_PSD_TRU    : for main psd plot;
            % PLOT_PSD_UNT    : for main untrustworthy psd plot;
            % PLOT_CON_TRU2   : for main Confidence upper plot;
            % PLOT_CON_TRU1   : for main Confidence lower plot;
            % PLOT_CON_UNT1   : for main untrustworthy Confidence upper plot;
            % PLOT_CON_UNT2   : for main untrustworthy Confidence lower plot;
            % PLOT_PSD_MAXR   : for main psd reference max plot;
            % PLOT_PSD_MINR   : for main psd reference min plot;
            TITLE_PLOT = get(get(PSD_CHILDREN(3),'Title'),'String');
            COMPONENT_LEGEND    = TITLE_PLOT(12:14);
            DAY_LEGEND          = TITLE_PLOT(32:41);
            TIME_LEGEND         = TITLE_PLOT(55:end);
            hold on;
            switch get(PSD_CHILDREN_PLOTS(j),'Tag')
                case 'PLOT_PSD_MAXR'
                    if ~PSDMAXREFEXIST
                        H_MAX_REF=semilogx(get(PSD_CHILDREN_PLOTS(j),'XData'),get(PSD_CHILDREN_PLOTS(j),'YData'),'r-');
                        set(H_MAX_REF,'linewidth',2.5);
                        PSDMAXREFEXIST = 1;
                        H_TRUE_PLOTS = [H_TRUE_PLOTS,H_MAX_REF];
                        H_TRUE_LEGEND = {H_TRUE_LEGEND{:},get(PSD_CHILDREN_PLOTS(j),'DisplayName')};
                    else
                    end
                case 'PLOT_PSD_MINR'
                    if ~PSDMINREFEXIST
                        H_MIN_REF=semilogx(get(PSD_CHILDREN_PLOTS(j),'XData'),get(PSD_CHILDREN_PLOTS(j),'YData'),'g-');
                        set(H_MIN_REF,'linewidth',2.5);
                        PSDMINREFEXIST = 1;
                        H_TRUE_PLOTS = [H_TRUE_PLOTS,H_MIN_REF];
                        H_TRUE_LEGEND = {H_TRUE_LEGEND{:},get(PSD_CHILDREN_PLOTS(j),'DisplayName')};
                    else
                    end
                case 'PLOT_PSD_TRU'
                    H_TRUE=semilogx(get(PSD_CHILDREN_PLOTS(j),'XData'),get(PSD_CHILDREN_PLOTS(j),'YData'),'Color',PSDCOLORTRACK);
                    set(H_TRUE,'linewidth',1.5);
                    H_TRUE_PLOTS = [H_TRUE_PLOTS,H_TRUE];
                    SITENAME_LEGEND =   get(PSD_CHILDREN_PLOTS(j),'DisplayName');
                    SITENAME_LEGEND = SITENAME_LEGEND(6:end);
                    if size(SITENAME_LEGEND,2) == 10
                        BLANK=' ';
                    else
                        BLANK='';
                    end
                    FINAL_LEGEND    =   [SITENAME_LEGEND,'.',BLANK,...
                        COMPONENT_LEGEND,': ',...
                        DAY_LEGEND,'-',...
                        TIME_LEGEND,', ',...
                        DATALOGGER_LEGEND,', ',...
                        SENSOR_LEGEND,'; ',...
                        CALCULUS_LEGEND];
                    H_TRUE_LEGEND = {H_TRUE_LEGEND{:},FINAL_LEGEND};
                case 'PLOT_CON_TRU1'
                    H_CON_TRUE1=semilogx(get(PSD_CHILDREN_PLOTS(j),'XData'),get(PSD_CHILDREN_PLOTS(j),'YData'),'Color',PSDCOLORTRACK);
                    set(H_CON_TRUE1,'linewidth',1);
                case 'PLOT_CON_TRU2'
                    H_CON_TRUE2=semilogx(get(PSD_CHILDREN_PLOTS(j),'XData'),get(PSD_CHILDREN_PLOTS(j),'YData'),'Color',PSDCOLORTRACK);
                    set(H_CON_TRUE2,'linewidth',1);
                case 'PLOT_CON_UNT1'
                    H_CON_UNTR1=semilogx(get(PSD_CHILDREN_PLOTS(j),'XData'),get(PSD_CHILDREN_PLOTS(j),'YData'),'--','Color',PSDCOLORTRACK);
                    set(H_CON_UNTR1,'linewidth',1);
                case 'PLOT_CON_UNT2'
                    H_CON_UNTR2=semilogx(get(PSD_CHILDREN_PLOTS(j),'XData'),get(PSD_CHILDREN_PLOTS(j),'YData'),'--','Color',PSDCOLORTRACK);
                    set(H_CON_UNTR2,'linewidth',1);
                case 'PLOT_PSD_UNT'
                    H_UNTRUST=semilogx(get(PSD_CHILDREN_PLOTS(j),'XData'),get(PSD_CHILDREN_PLOTS(j),'YData'),'--','Color',PSDCOLORTRACK);
                    set(H_UNTRUST,'linewidth',1);
            end
        end
        grid on;
        % Cycling colors for multiple plots
        if PSDCOLORTRACK(1) == 1 && PSDCOLORTRACK(2)<=1 && PSDCOLORTRACK(3)==0
            PSDCOLORTRACK(2)=PSDCOLORTRACK(2)+PSDCOLORSTEP;
            if PSDCOLORTRACK(2) > 1
                PSDCOLORTRACK(2)=1;
                PSDCOLORTRACK(1)-PSDCOLORSTEP;
            end
        end
        if PSDCOLORTRACK(1) <= 1 && PSDCOLORTRACK(2)==1 && PSDCOLORTRACK(3)==0
            PSDCOLORTRACK(1)=PSDCOLORTRACK(2)-PSDCOLORSTEP;
            if PSDCOLORTRACK(1) < 0
                PSDCOLORTRACK(1)=0;
                PSDCOLORTRACK(3)+PSDCOLORSTEP;
            end
        end
        if (PSDCOLORTRACK(1) == 0) && (PSDCOLORTRACK(2)==1) && (PSDCOLORTRACK(3)>=0)
            PSDCOLORTRACK(3)=PSDCOLORTRACK(3)+PSDCOLORSTEP;
            if PSDCOLORTRACK(3) > 1
                PSDCOLORTRACK(3)=1;
                PSDCOLORTRACK(2)=PSDCOLORTRACK(2)-PSDCOLORSTEP;
            end
        end
        if (PSDCOLORTRACK(1) == 0) && (PSDCOLORTRACK(2)<=1) && (PSDCOLORTRACK(3)==1)
            PSDCOLORTRACK(2)=PSDCOLORTRACK(2)-PSDCOLORSTEP;
            if PSDCOLORTRACK(2) < 0
                PSDCOLORTRACK(2)=0;
                PSDCOLORTRACK(1)=PSDCOLORTRACK(1)+PSDCOLORSTEP;
            end
        end
        if (PSDCOLORTRACK(1) >= 0) && (PSDCOLORTRACK(2)==0) && (PSDCOLORTRACK(3)==1)
            PSDCOLORTRACK(1)=PSDCOLORTRACK(1)+PSDCOLORSTEP;
            if PSDCOLORTRACK(1) > 1
                PSDCOLORTRACK(1) = 1;
                PSDCOLORTRACK(3)=PSDCOLORTRACK(3)-PSDCOLORSTEP;
            end
        end
        if PSDCOLORTRACK(1) == 1 && PSDCOLORTRACK(2) == 0 && PSDCOLORTRACK(3)<=1
            PSDCOLORTRACK(3)=PSDCOLORTRACK(3)-PSDCOLORSTEP;
            if PSDCOLORTRACK(3) < 0
                PSDCOLORTRACK(3) = 0;
                PSDCOLORTRACK(2)=PSDCOLORTRACK(2)+PSDCOLORSTEP;
            end
        end
    end
    axis([X_LIM_FIN Y_LIM_FIN]);
    set(gca,'XScale','log');
    TextTitle = 'PSD comparison';
    title(TextTitle,'FontName','helvetica','FontUnits','normalized','FontSize',1.2*CharSize,'FontWeight','bold','color','blue');
    xlabel(FINAL_XLABEL,'FontName','helvetica','FontUnits','normalized','FontSize',CharSize,'FontWeight','bold');
    ylabel(FINAL_YLABEL,'FontName','helvetica','FontUnits','normalized','FontSize',CharSize,'FontWeight','bold');
    FINALLEGEND=legend(H_TRUE_PLOTS,H_TRUE_LEGEND);
    %set(FINALLEGEND,'FontName','Arial','FontWeight','demi');
    set(FINALLEGEND,'FontName','FixedWidth','Interpreter','none','FontSize',6);
    
    % ******************** Multiple PopUP Calls *********************
elseif strcmp(action,'multipledatalogger');
    MainFigure	=	gcf;
    Objects		=	get(MainFigure,'UserData');
    Index=get(Objects.G_logg_multiple,'Value');
    Dataloggers=get(Objects.G_logg_multiple,'UserData');
    Datalogger = Dataloggers(Index);
    Objects.Info_Multiple=updatefields(Objects.Info_Multiple,Datalogger);
    StringToShow=[num2str(Objects.Info_Multiple.Q),char(Objects.Info_Multiple.Units)];
    set(Objects.G_logg_value_multiple,'String',StringToShow);
    set(MainFigure,'UserData',Objects);
    
elseif strcmp(action,'multiplesensor');
    MainFigure	=	gcf;
    Objects		=	get(MainFigure,'UserData');
    Index=get(Objects.G_sens_multiple,'Value');
    Sensors=get(Objects.G_sens_multiple,'UserData');
    Sensor = Sensors(Index);
    Objects.Info_Multiple=updatefields(Objects.Info_Multiple,Sensor);
    StringToShow=[num2str(Objects.Info_Multiple.Sens,4),char(Objects.Info_Multiple.SensU),...
        ' ',num2str(Objects.Info_Multiple.SensTmax),char(Objects.Info_Multiple.SensTmaxU)];
    set(Objects.G_sens_value_multiple,'String',StringToShow);
    set(MainFigure,'UserData',Objects);
    
elseif strcmp(action,'close');
    MainFigure	=	gcf;
    close all
    
elseif strcmp(action,'help');
    MainFigure	=	gcf;
    helpwin(mfilename);
end
%
% catch
%     errmsg = lasterr;
%     errordlg(errmsg,'Error');
% end

%******************************* FUNCTIONS ********************************
function [FLAG] = whichcase(varargin)
%FLAGS could be: L for lowercase, U for uppercase, M for mixed case.
if ~isempty (varargin)
    STRING=varargin;
    U_STRING=upper(STRING);
    L_STRING=lower(STRING);
    if strcmp(STRING,U_STRING)
        FLAG = 'U';
    elseif strcmp(STRING,L_STRING)
        FLAG = 'L';
    else
        FLAG = 'M';
    end
else
end

%--------------------------------------------------------------------------
function [dataout] = load_track(filename,varargin)
if ~isempty (varargin)
    FILETYPES = varargin{1};
    EXTENSION = filename(end-2:end);
    for COUNT = 1:size(FILETYPES,2)
        if strmatch(FILETYPES{COUNT},EXTENSION)
            FLAG = filetype(filename);
            switch FLAG
                case 'bin'
                    FILETYPE = 'SAC';
                case 'txt'
                    N               = 200;   %number of rows to read for the TXT check
                    N_SAC_HEADER    = 148;   % by default the header sac is made of 148 rows starting with the '#' char
                    INMAT = char(textread(filename,...
                        '%s',N,'delimiter','\n')); % reading first N file rows
                    if size(strfind(INMAT(:,1)','#'),2) == N_SAC_HEADER
                        FILETYPE = 'ASCII_SAC';                        
                    else
                        FILETYPE = 'ASCII';
                    end
                otherwise
                    FILETYPE = 'UNKNOWN';
            end
            %             if strcmp(whichcase(EXTENSION),'L')
            %                 FILETYPE = 'ASCII';
            %             elseif strcmp(whichcase(EXTENSION),'U')
            %                 FILETYPE = 'SAC';
            %             else
            %                 FILETYPE = 'UNKNOWN';
            %             end
        else
        end
    end
else
end
%load tracks data values
switch FILETYPE
    %if strcmp(FILETYPE,'ASCII')
    case 'ASCII'
        fid=fopen(filename,'r');
        header=fgetl(fid);
        fclose(fid);
        if header(1,1)=='#'
            [File.sta,...
                File.comp,...
                File.Tsamp,...
                File.date,...
                File.time]=textread(filename,...
                '%*s %*s %s %*s %s %*s %f %*s %s %s',1);
            File.Tsamp=(File.Tsamp)*1e-3;
            x=textread(filename,'%f','headerlines',1,'commentstyle','shell');
        else
            x=textread(filename,'%f','commentstyle','shell');
            File.Tsamp=1;
        end
        t=File.Tsamp*(0:1:size(x,1)-1);
        x=x(:);
        t=t(:);
        y=[t';x'];
        File.data=[t,x];
    case 'SAC'
        %elseif strcmp(FILETYPE,'SAC')
        SACDATA=rsac2(filename);
        if ischar(SACDATA)
            % if an error is caught by rsac2, load_track will push out
            % that error string instead of the data
            File = SACDATA;
        else
            File.sta   = lh(SACDATA,'KSTNM');
            File.comp  = lh(SACDATA,'KCMPNM');
            File.Tsamp = lh(SACDATA,'DELTA');
            YEAR = lh(SACDATA,'NZYEAR');
            DOY =  lh(SACDATA,'NZJDAY');
            FIRSTDOYSTR=['1-Jan-',num2str(YEAR)];
            FIRSTDOYNUM=datenum(FIRSTDOYSTR);
            CURRENTDOYNUM=FIRSTDOYNUM+DOY-1;
            File.date=datestr(CURRENTDOYNUM,29);
            File.time  = [num2str(lh(SACDATA,'NZHOUR')),':',...
                num2str(lh(SACDATA,'NZMIN')),':',...
                num2str(lh(SACDATA,'NZSEC')+lh(SACDATA,'NZMSEC')/1000)];
            TIMEVECT = (0:File.Tsamp:File.Tsamp*(size(SACDATA(:,2),1)-1))';
            %File.data  = [SACDATA(:,1),SACDATA(:,2)];
            File.data  = [TIMEVECT,SACDATA(:,2)];
        end
    case 'ASCII_SAC'
        File = rsact(filename);
    otherwise
        %else
end
dataout=File;

%--------------------------------------------------------------------------
function [dataout] = load_psd_track(filename)
%load quake data values
fid=fopen(filename,'r');
header1=fgetl(fid);
header2=fgetl(fid);
fclose(fid);
if header1(1,1)=='#'
    if strfind(header1,'Confidence')
        [File.sta,...
            File.type,...
            File.Q,...
            File.Units,...
            File.comp,...
            File.Tsamp,...
            File.SensT,...
            File.SensN,...
            File.Sens,...
            File.SensU,...
            File.SensTmax,...
            File.date,...
            File.time,...
            File.Method,...
            File.Taper,...
            File.Length,...
            File.Overlap,...
            File.Datasetsize,...
            File.Confidence]=strread(header1,...
            '%*s %*s %s %*s %s %*s %f %s %*s %s %*s %f %*s %s %*s %d %*s %f %s %*s %f %*s %s %s %*s %s %*s %s %*s %f %*s %f %*s %f %*s %f',1);
        Confidence=File.Confidence;
        if header2(1,1)=='#'
            [File.FUnits,File.PSDUnits]=strread(header2,'%*s %*s %s %*s %s');
            NumOfHeaders=2;
        else
            NumOfHeaders=1;
        end
    else
        [File.sta,...
            File.type,...
            File.Q,...
            File.Units,...
            File.comp,...
            File.Tsamp,...
            File.SensT,...
            File.SensN,...
            File.Sens,...
            File.SensU,...
            File.SensTmax,...
            File.date,...
            File.time,...
            File.Method,...
            File.Taper,...
            File.Length,...
            File.Overlap,...
            File.Datasetsize]=strread(header1,...
            '%*s %*s %s %*s %s %*s %f %s %*s %s %*s %f %*s %s %*s %d %*s %f %s %*s %f %*s %s %s %*s %s %*s %s %*s %f %*s %f %*s %f',1);
        if header2(1,1)=='#'
            [File.FUnits,File.PSDUnits]=strread(header2,'%*s %*s %s %*s %s');
            NumOfHeaders=2;
        else
            NumOfHeaders=1;
        end
    end
else
    NumOfHeaders=0;
end
if exist('Confidence')
    [x,y,c1,c2]=textread(filename,'%f %f %f %f','headerlines',NumOfHeaders,'commentstyle','shell');
    x=x(:);
    y=y(:);
    c1=c1(:);
    c2=c2(:);
    File.data=[x,y,c1,c2];
else
    [x,y]=textread(filename,'%f %f','headerlines',NumOfHeaders,'commentstyle','shell');
    x=x(:);
    y=y(:);
    File.data=[x,y];
    dataout=File;
end
dataout=File;

%--------------------------------------------------------------------------
function [dataout] = psd_gen(datain,varargin)
% Defaults:
K=1;
Method = 'pwelch';
TaperMode='hanning';
slot_length=size(datain,1);
Overlapping = 0;
%Psd of data input
if ~isempty (varargin)
    NumArg=size(varargin,2);
    switch NumArg
        % arg #1: K gain
        % arg #2: method used for PSD
        % arg #3: TaperMode, window type for tapering
        % arg #4: slot_length
        % arg #5: overlapping percentage
        % arg #6: Confidence Interval [0,1]
        case 1
            K=varargin{1};
        case 2
            K=varargin{1};
            Method = varargin{2};
        case 3
            K=varargin{1};
            Method = varargin{2};
            TaperMode=varargin{3};
        case 4
            K=varargin{1};
            Method = varargin{2};
            TaperMode=varargin{3};
            slot_length=varargin{4};
        case 5
            K=varargin{1};
            Method = varargin{2};
            TaperMode=varargin{3};
            slot_length=varargin{4};
            Overlapping = varargin{5};
        case 6
            K=varargin{1};
            Method = varargin{2};
            TaperMode=varargin{3};
            slot_length=varargin{4};
            Overlapping = varargin{5};
            Confidence = varargin{6};
    end
    
end
Win=eval([TaperMode,'(',num2str(slot_length),')']);
Overlap=round(Overlapping*slot_length);
Ver=ver('signal');
Ver.Version=str2num(Ver.Version);
fsample=1/(datain(2,1)-datain(1,1));
if Ver.Version <= 4.2
    switch lower(Method)
        case {'pwelch','welch'}
            if exist('Confidence')
                % syntax for signal processing toolbox ver 4.2:
                % [Pxx,Pxxc,f] = pwelch(x,nfft,Fs,window,noverlap,p);
                [dataout.psd,dataout.ConfInterval,dataout.f]=eval([Method,'(datain(:,2),slot_length,fsample,Win,Overlap,Confidence)']);
                dataout.ConfLevel=Confidence;
            else
                % syntax for signal processing toolbox ver 4.2:
                % [Pxx,f] = pwelch(x,nfft,Fs,window,noverlap);
                [dataout.psd,dataout.f]=eval([Method,'(datain(:,2),slot_length,fsample,Win,Overlap)']);
            end
    end
elseif (Ver.Version > 4.2) && (Ver.Version < 6.8)
    switch lower(Method)
        case {'pwelch','welch'}
            % syntax for signal processing toolbox ver 6.2:
            % [Pxx,F] = PWELCH(X,WINDOW,NOVERLAP,NFFT,Fs)
            % [dataout.psd,dataout.f]=pwelch(datain(:,2),Win,Overlap,slot_length,fsample);
            [dataout.psd,dataout.f]=eval([Method,'(datain(:,2),Win,Overlap,slot_length,fsample)']);
            if exist('Confidence')
                %since ver 6.2 up to 6.8 of the Signal Processing Toolbox
                %Confidence interval is not implemented. For this reason a
                %scaled version of the psd command is used to get the
                %confidence level
                %The psd2 is an exactc copy (except for the warning
                %message) of the psd function included in
                %MATLAB Version %7.0.0.19920 (R14), for this reason also
                %chi2conf and psdchk have been added to psdtool
                [PXX,PYYC,F]=psd2(datain(:,2),slot_length,fsample,Win,Overlap,Confidence);
                % scale ratio
                RATIO=dataout.psd./PXX;
                dataout.ConfLevel=Confidence;
                dataout.ConfInterval=[PYYC(:,1).*RATIO,PYYC(:,2).*RATIO];
            else
            end
    end
elseif Ver.Version >= 6.8
    switch lower(Method)
        case {'pwelch','welch'}
            % syntax for signal processing toolbox ver 6.8, some changes in
            % the definition for using the spectrum structure data
            if strcmp(TaperMode,lower('Hanning'))
                TaperXSpectrum='Hann';
            else
                TaperXSpectrum=Taper;
            end
            if strcmp(Method,'pwelch')
                MethodXSpectrum='welch';
            else
                MethodXSpectrum=Method;
            end
            % syntax Hs = spectrum.welch(WindowName,SegmentLength,OverlapPercent)
            % WindowName:               default is 'Hamming'
            % {WindowName,winparam}:    if you need to add some parameters for the
            %                           definition of the window type
            % SegmentLength:            default 64 Length of each of the time-based segments
            %                           into which the input signal is divided. A modified
            %                           periodogram is computed on each segment and the average
            %                           of the periodograms forms the spectral estimate.
            %                           Choosing the segment length is a compromise between
            %                           estimate reliability (shorter segments) and frequency
            %                           resolution (longer segments). A long segment length producese
            %                           better resolution while a short segment length produces more
            %                           averages, and therefore a decrease in the variance.
            % OverlapPercent:           default is 50% . It ss the percent overlap between segments
            HS1=spectrum.(MethodXSpectrum)(TaperXSpectrum,slot_length,Overlapping*100);
            % You can tune the spectral estimation parameters by the psdopt method,
            % and in this new ver. you can define the ConfLevel value.
            % pdopts avilable are:
            % SpectrumType              'onesided' or 'twosided'
            % NormalizedFrequency       Normalizes frequency between 0 and 1
            % Fs                        Fs sampling frequency in Hz
            % NFFT                      number of FFT points
            % CenterDC                  shifts data and frequencies to center DC component
            % FreqPoints                'All' or 'User Defined'
            % FrequencyVector           frequencies at which to compute spectrum
            % ConfLevel                 confidence level to calculate the confidence interval. Value must be from 0 to 1.
            OPTS_HS1=psdopts(HS1); % get the defaults
            % change the psd defaults values by psdopts
            if exist('Confidence')
                set(OPTS_HS1,'NFFT',slot_length,'SpectrumType','onesided','Fs',fsample,'ConfLevel',Confidence);
                HPSD1=psd(HS1,datain(:,2),OPTS_HS1);
                dataout.psd =   HPSD1.Data;
                dataout.f   =   HPSD1.Frequencies;
                dataout.ConfLevel       =   Confidence;
                dataout.ConfInterval    =   HPSD1.ConfInterval;
            else
                set(OPTS_HS1,'NFFT',slot_length,'SpectrumType','onesided','Fs',fsample);
                HPSD1=psd(HS1,x,OPTS_HS1);
                dataout.psd =   HPSD1.Data;
                dataout.f   =   HPSD1.Frequencies;
            end
    end
end
dataout.psd=(K^2)*dataout.psd;
if exist('Confidence') && (size(dataout.ConfInterval,1) == size(dataout.psd,1))
    dataout.ConfInterval(:,1)=(K^2)*dataout.ConfInterval(:,1);
    dataout.ConfInterval(:,2)=(K^2)*dataout.ConfInterval(:,2);
end

%--------------------------------------------------------------------------
function [xd,yd] = deriv(x,y)
x=x(:);
y=y(:);
h=x(2,1)-x(1,1);
yd=diff(y)/h;
xd=x(1)+(0:1:size(yd,1)-1)*h;
xd=xd(:);
yd=yd(:);

%--------------------------------------------------------------------------
function [Fileout] = data2psdfile(Filein,filename,varargin)
% defaults
Flag_mode ='d'; % do not perform PSD
Method = 'none'; % default method used: Pwelch
slot_length=size(Filein.data(:,1),1); % the PSD slot size is equal to the data vector size
K=[]; % default Gain
TaperMode='none'; % default: haing (see psd_gen for syntax)
Overlapping=0; % default: no overlapping (sse psd_gen for syntax)
if ~isempty (varargin)
    NumArg=size(varargin,2);
    switch NumArg
        % arg #1: Flag_mode for performing psd
        %         'p' is for doing psd
        %         'd' or anything else is for skipping psd
        % arg #2: Gain used for performing PSD, leaving K empty will force
        %         data2psd to use the values of Q and sensor sensitivity for
        %         yelding K
        % arg #3: method used for PSD
        % arg #4: TaperMode, window type for tapering
        % arg #5: slot_length
        % arg #6: Overlapping percent
        % arg #7: PSD Units (could be accelerations, velocities or displacements)
        % arg #8: Confidence value, must be between 0 and 1.
        case 1
            Flag_mode=varargin{1};
        case 2
            Flag_mode=varargin{1};
            K=varargin{2};
        case 3
            Flag_mode=varargin{1};
            K=varargin{2};
            Method=varargin{3};
        case 4
            Flag_mode=varargin{1};
            K=varargin{2};
            Method=varargin{3};
            TapperMode=varargin{4};
        case 5
            Flag_mode=varargin{1};
            K=varargin{2};
            Method=varargin{3};
            TapperMode=varargin{4};
            slot_length=varargin{5};
        case 6
            Flag_mode=varargin{1};
            K=varargin{2};
            Method=varargin{3};
            TaperMode=varargin{4};
            slot_length=varargin{5};
            Overlapping=varargin{6};
        case 7
            Flag_mode=varargin{1};
            K=varargin{2};
            Method=varargin{3};
            TaperMode=varargin{4};
            slot_length=varargin{5};
            Overlapping=varargin{6};
            Units=varargin{7};
        case 8
            Flag_mode=varargin{1};
            K=varargin{2};
            Method=varargin{3};
            TaperMode=varargin{4};
            slot_length=varargin{5};
            Overlapping=varargin{6};
            Units=varargin{7};
            Confidence=varargin{8};
    end
end
header1 = [ '# Station: ',char(Filein.sta),...
    ' DataLogger: ',char(Filein.type),...
    ' Q: ',num2str(Filein.Q),' ',char(Filein.Units),' ',...
    ' Comp: ',char(Filein.comp),...
    ' Samp: ',num2str(Filein.Tsamp),...
    ' Sensor: ',char(Filein.SensT),' S/N ',num2str(Filein.SensN),...
    ' Sensty: ',num2str(Filein.Sens),' ',char(Filein.SensU),...
    ' SensorPeriod: ',num2str(Filein.SensTmax),...
    ' Start: ',char(Filein.date),...
    ' ',char(Filein.time),...
    ' Method: ',char(Method),...
    ' Taper: ',char(TaperMode),...
    ' Length: ',num2str(slot_length),...
    ' Overlap: ',num2str(Overlapping),...
    ' Datasetsize: ',num2str(Filein.Datasetsize)];
if exist('Confidence')
    header1=[header1,' Confidence: ',num2str(Confidence)];
else
end
if NumArg > 6
    if exist('Confidence')
        header2 = { '# Freq.: Hz',...
            ['PSD: (',char(Units),')^2/Hz'],...
            ['Min.C.: (',char(Units),')^2/Hz'],...
            ['Max.C.: (',char(Units),')^2/Hz']};
    else
        header2 = {'# Freq.: Hz',...
            ['PSD: (',char(Units),')^2/Hz']};
    end
end
% Flag_mode ='p'=> do psd Flag_mode ='d' => don't do psd
if Flag_mode =='p'
    if isempty(K)
        K=Filein.Q/Filein.Sens;
    end
    % arg #1: K gain
    % arg #2: method used for PSD
    % arg #3: TaperMode, window type for tapering
    % arg #4: slot_length
    % arg #5: overlapping percentage
    % arg #6: confidence interval requested
    if exist('Confidence')
        Data_psd=psd_gen(Filein.data,K,Method,TaperMode,slot_length,Overlapping,Confidence);
    else
        Data_psd=psd_gen(Filein.data,K,Method,TaperMode,slot_length,Overlapping);
    end
    Fileout=Filein;
    fid=fopen(filename,'w');
    fprintf(fid,[header1,'\n']);
    if exist('header2')
        if exist('Confidence')
            fprintf(fid,'%-13s\t %-17s\t %-17s\t %-17s\n',header2{:});
        else
            fprintf(fid,'%-13s\t %-17s\n',header2{:});
        end
    end
    if exist('Confidence')
        Fileout.data=[Data_psd.f,Data_psd.psd, Data_psd.ConfInterval(:,1), Data_psd.ConfInterval(:,2)];
        %fprintf(fid,'%-7.10g\t %-9.10g\t %-11.10g\t %-13.10g\n',[Data_psd.f';...
        fprintf(fid,'%-7.10f\t %-9.10e\t %-11.10e\t %-13.10e\n',[Data_psd.f';...
            Data_psd.psd';...
            Data_psd.ConfInterval(:,1)';...
            Data_psd.ConfInterval(:,2)']);
    else
        Fileout.data=[Data_psd.f,Data_psd.psd];
        %fprintf(fid,'%-7.10g\t %-9.10g\n',[Data_psd.f';Data_psd.psd']);
        fprintf(fid,'%-7.10f\t %-9.10e\n',[Data_psd.f';Data_psd.psd']);
    end
    fclose(fid);
else
    Fileout=Filein;
    fid=fopen(filename,'w');
    fprintf(fid,[header1,'\n']);
    if exist('header2')
        if exist('Confidence')
            fprintf(fid,'%-13s\t %-17s\t %-17s\t %-17s\n',header2{:});
        else
            fprintf(fid,'%-13s\t %-17s\n',header2{:});
        end
    end
    if exist('Confidence')
        %fprintf(fid,'%-7.10g\t %-9.10g\t %-11.10g\t %-13.10g\n',[Fileout.data(:,1)';...
        fprintf(fid,'%-7.10f\t %-9.10e\t %-11.10e\t %-13.10e\n',[Fileout.data(:,1)';...
            Fileout.data(:,2)';...
            Fileout.data(:,3)';...
            Fileout.data(:,4)']);
    else
        %fprintf(fid,'%-7.10g\t %-9.10g\n',[Fileout.data(:,1)';Fileout.data(:,2)']);
        fprintf(fid,'%-7.10f\t %-9.10e\n',[Fileout.data(:,1)';Fileout.data(:,2)']);
    end
    fclose(fid);
end

%--------------------------------------------------------------------------
function [struct_out] = updatefields(struct1,struct2)
if isempty(struct1)
    struct_out = struct2;
else
    if isstruct(struct1) && isstruct(struct2)
        fieldnames1 = fieldnames(struct1);
        fieldnames2 = fieldnames(struct2);
        size1 = size(fieldnames1,1);
        size2 = size(fieldnames2,1);
        for cont2 = 1:1:size2
            cont1 = strmatch(fieldnames2(cont2),fieldnames1,'exact');
            if isempty(cont1)
                struct1.(char(fieldnames2(cont2)))=struct2.(char(fieldnames2(cont2)));
            else
                struct1.(char(fieldnames1(cont1)))=struct2.(char(fieldnames2(cont2)));
            end
        end
    end
    struct_out = struct1;
end

%--------------------------------------------------------------------------
function [typeout] = get_quant(typein,varargin)
if ~isempty(varargin)
else
end
if ~isempty(strfind(typein,'/s^2'))
    Quantity_Orig.name = 'acc';
    Quantity_Orig.order = 2;
else
    if ~isempty(strfind(typein,'/s'))
        Quantity_Orig.name = 'vel';
        Quantity_Orig.order = 1;
    else
        Quantity_Orig.name = 'dis';
        Quantity_Orig.order = 0;
    end
end
typeout=Quantity_Orig;

%--------------------------------------------------------------------------
function [msg] = set_path(Flags_new,Paths_new,varargin)
% Setting SLASH for computer dependent PATHS
if ispc
    SLASH_TYPE = '\';
else
    SLASH_TYPE = '/';
end
if ~isempty(varargin)
    PathFileName=varargin{1};
else
    PathFileName='psdtool.path';
end
if isempty(Flags_new)
    % LST: Load Single Track path
    % DSP: Do Single PSD path
    % VSP: View Single PSD path
    % LMT: Load Multiple Track path
    % DMP: Do Multiple PSD path
    % VMP: View Multiple PSD path
    %Flags_new = {'LST','DSP','VSP','LMT','DMP','VMP'};
    Flags_new = {'LMT','DMP','VMP'};
end
Size_new=size(Flags_new,2);
if isempty(Paths_new)
    Paths_new=cell(1,Size_new);
    [Paths_new{:}]=deal([pwd,SLASH_TYPE]);
end
Dir=dir(PathFileName);
if isempty(Dir)
    Flags=Flags_new;
    Paths=Paths_new;
else
    [Flags,Paths]=textread(PathFileName,'%s %s','delimiter','|');
    Flags=Flags';
    Paths=Paths';
    Size=size(Flags,2);
    for cont = 1:1:size(Flags_new,2)
        Index = strmatch(Flags_new(cont),Flags);
        if ~isempty(Index)
            Paths(Index)=Paths_new(cont);
            Flags(Index)=Flags_new(cont);
        else
            Paths(Size+1)=Paths_new(cont);
            Flags(Size+1)=Flags_new(cont);
        end
    end
end
fid=fopen(PathFileName,'w');
for count = 1:1:size(Flags,2)
    fprintf(fid,'%s\n',[Flags{count},'|',Paths{count}]);
end
fclose(fid);

%--------------------------------------------------------------------------
function [Paths_out,Flags_out] = get_path(Flags,varargin)
if ~isempty(varargin{1})
    PathFileName=varargin{1};
else
    PathFileName='psdtool.path';
end
if isempty(Flags)
    % LST: Load Single Track path
    % DSP: Do Single PSD path
    % VSP: View Single PSD path
    % LMT: Load Multiple Track path
    % DMP: Do Multiple PSD path
    % VMP: View Multiple PSD path
    %Flags = {'LST','DSP','VSP','LMT','DMP','VMP'};
    Flags = {'LMT','DMP','VMP'};
end
Dir=dir(PathFileName);
if isempty(Dir)
    Flags_out=[];
    Paths_out=[];
else
    [Flags_tmp,Paths_tmp]=textread(PathFileName,'%s %s','delimiter','|');
    Flags_tmp=Flags_tmp';
    Paths_tmp=Paths_tmp';
    Size=size(Flags_tmp,2);
    for cont = 1:1:size(Flags,2)
        Index = strmatch(Flags(cont),Flags_tmp);
        if ~isempty(Index)
            if exist('Flags_out')
                Flags_out={Flags_out{:},Flags_tmp{Index}};
                Path_out={Path_out{:},Path_tmp{Index}};
            else
                Flags_out{1}=Flags_tmp{Index};
                Paths_out{1}=Paths_tmp{Index};
            end
        else
            Flags_out=[];
            Paths_out=[];
        end
    end
end

%--------------------------------------------------------------------------
function [varargout] = rsac2(varargin);
%RSAC    Read SAC binary files.
%    RSAC('sacfile') reads in a SAC (seismic analysis code) binary
%    format file into a 3-column vector.
%    Column 1 contains time values.
%    Column 2 contains amplitude values.
%    Column 3 contains all SAC header information.
%    Default byte order is big-endian.  M-file can be set to default
%    little-endian byte order.
%
%    usage:  output = rsac('sacfile')
%
%    Examples:
%
%    KATH = rsac('KATH.R');
%    plot(KATH(:,1),KATH(:,2))
%
%    [SQRL, AAK] = rsac('SQRL.R','AAK.R');
%
%    by Michael Thorne (4/2004)   mthorne@asu.edu
%    Modified by David Zuliani (26/07/2007) dzuliani@inogs.it (auto byte
%    oreder selecting + error messages)
try
    for nrecs = 1:nargin
        
        sacfile = varargin{nrecs};
        
        %---------------------------------------------------------------------------
        %    Default byte-order
        %    endian  = 'big-endian' byte order (e.g., UNIX)
        %            = 'little-endian' byte order (e.g., LINUX)
        ENDIANS = {'big-endian','little-endian'};
        for COUNT = 1:size(ENDIANS,2)
            endian = ENDIANS{COUNT};
            h=[];
            if strcmp(endian,'big-endian')
                fid = fopen(sacfile,'r','ieee-be');
            elseif strcmp(endian,'little-endian')
                fid = fopen(sacfile,'r','ieee-le');
            end
            % read in single precision real header variables:
            %---------------------------------------------------------------------------
            for i=1:70
                h(i) = fread(fid,1,'single');
            end
            
            % read in single precision integer header variables:
            %---------------------------------------------------------------------------
            for i=71:105
                h(i) = fread(fid,1,'int32');
            end
            
            % Check header version = 6 and issue warning
            %---------------------------------------------------------------------------
            % If the header version is not NVHDR == 6 then the sacfile is likely of the
            % opposite byte order.  This will give h(77) some ridiculously large
            % number.  NVHDR can also be 4 or 5.  In this case it is an old SAC file
            % and rsac cannot read this file in.  To correct, read the SAC file into
            % the newest verson of SAC and w over.
            %
            if (h(77) == 4 | h(77) == 5)
                message = ['NVHDR = 4 or 5. File: "',sacfile,'" may be from an old version of SAC.'];
                fclose(fid);
                % if an error is caught, the message error is pushed out instead of
                % the data
                varargout{1}=message;
                return
            elseif h(77) == 6
                break
            else
                if COUNT == size(ENDIANS,2)
                    message = ['NVHDR = ', num2str(h(77)),' is wrong inside ', sacfile,' No operation performed.'];
                    fclose(fid);
                    varargout{1}=message;
                    % if an error is caught, the message error is pushed out instead of
                    % the data
                    return
                end
            end
        end
        
        % read in logical header variables
        %---------------------------------------------------------------------------
        for i=106:110
            h(i) = fread(fid,1,'int32');
        end
        
        % read in character header variables
        %---------------------------------------------------------------------------
        for i=111:302
            h(i) = (fread(fid,1,'char'))';
        end
        
        % read in amplitudes
        %---------------------------------------------------------------------------
        
        YARRAY     = fread(fid,'single');
        
        if h(106) == 1
            XARRAY = (linspace(h(6),h(7),h(80)))';
        else
            error('LEVEN must = 1; SAC file not evenly spaced')
        end
        
        % add header signature for testing files for SAC format
        %---------------------------------------------------------------------------
        h(303) = 77;
        h(304) = 73;
        h(305) = 75;
        h(306) = 69;
        
        % arrange output files
        %---------------------------------------------------------------------------
        % ADD BY D. Zuliani 2012.02.23 to cheat the ambiguous SAC ARRAY
        %if (size(YARRAY,1) ~= size(XARRAY,1))
        %    XARRAY = ((0:size(YARRAY,1)-1)*h(1)+h(6))';
        %end
        OUTPUT = [XARRAY,YARRAY];
        %OUTPUT(:,1) = XARRAY;
        %OUTPUT(:,2) = YARRAY;
        OUTPUT(1:306,3) = h(1:306)';
        
        %pad xarray and yarray with NaN if smaller than header field
        if h(80) < 306
            OUTPUT((h(80)+1):306,1) = NaN;
            OUTPUT((h(80)+1):306,2) = NaN;
        end
        
        fclose(fid);
        
        varargout{nrecs} = OUTPUT;
        
    end
catch exception
    if (strcmp(exception.identifier, ...
            'MATLAB:catenate:dimensionMismatch'))
        varargout{1} = 'BAD DATA FILE.';
    else
        varargout{1} = 'UNKNOWN DATA FILE.';
    end
end
%--------------------------------------------------------------------------
function [varargout] = lh(file,varargin);
%LH    list SAC header
%
%    Read or set matlab variables to SAC header variables from
%    SAC files read in to matlab with rsac.m
%
%    Examples:
%
%    To list all defined header variables in the file KATH:
%    lh(KATH)
%
%    To assign the SAC variable DELTA from station KATH to
%    the matlab variable dt:
%
%    dt = lh(KATH,'DELTA');
%
%    To assign the SAC variables STLA and STLO from station KATH
%    to the matlab variables lat and lon:
%
%    [lat,lon] = lh(KATH,'STLA','STLO')
%
%    by Michael Thorne (4/2004)  mthorne@asu.edu
%
%    See also:  RSAC, CH, BSAC, WSAC

%N.B.
% IDEP, Type of dependent variable:
%
%     * IUNKN (Unknown)                     = 5 %it should be counts
%     * IDISP (Displacement in nm)          = 6
%     * IVEL (Velocity in nm/sec)           = 7
%     * IVOLTS (Velocity in volts)          = 50
%     * IACC (Acceleration in nm/sec/sec)   = 8
%
%

% first test to see if the file is indeed a sacfile
%---------------------------------------------------------------------------
if (file(303,3)~=77 & file(304,3)~=73 & file(305,3)~=75 & file(306,3)~=69)
    error('Specified Variable is not in SAC format ...')
end

h(1:306) = file(1:306,3);


% read real header variables
%---------------------------------------------------------------------------
DELTA = h(1);
if (h(1) ~= -12345 & nargin == 1); disp(sprintf('DELTA      = %0.8g',h(1))); end
DEPMIN = h(2);
if (h(2) ~= -12345 & nargin == 1); disp(sprintf('DEPMIN     = %0.8g',h(2))); end
DEPMAX = h(3);
if (h(3) ~= -12345 & nargin == 1); disp(sprintf('DEPMAX     = %0.8g',h(3))); end
SCALE = h(4);
if (h(4) ~= -12345 & nargin == 1);  disp(sprintf('SCALE      = %0.8g',h(4))); end
ODELTA = h(5);
if (h(5) ~= -12345 & nargin == 1);  disp(sprintf('ODELTA     = %0.8g',h(5))); end
B = h(6);
if (h(6) ~= -12345 & nargin == 1); disp(sprintf('B          = %0.8g',h(6))); end
E = h(7);
if (h(7) ~= -12345 & nargin == 1); disp(sprintf('E          = %0.8g',h(7))); end
O = h(8);
if (h(8) ~= -12345 & nargin == 1); disp(sprintf('O          = %0.8g',h(8))); end
A = h(9);
if (h(9) ~= -12345 & nargin == 1); disp(sprintf('A          = %0.8g',h(9))); end
T0 = h(11);
if (h(11) ~= -12345 & nargin == 1); disp(sprintf('T0         = %0.8g',h(11))); end
T1 = h(12);
if (h(12) ~= -12345 & nargin == 1); disp(sprintf('T1         = %0.8g',h(12))); end
T2 = h(13);
if (h(13) ~= -12345 & nargin == 1); disp(sprintf('T2         = %0.8g',h(13))); end
T3 = h(14);
if (h(14) ~= -12345 & nargin == 1); disp(sprintf('T3         = %0.8g',h(14))); end
T4 = h(15);
if (h(15) ~= -12345 & nargin == 1); disp(sprintf('T4         = %0.8g',h(15))); end
T5 = h(16);
if (h(16) ~= -12345 & nargin == 1); disp(sprintf('T5         = %0.8g',h(16))); end
T6 = h(17);
if (h(17) ~= -12345 & nargin == 1); disp(sprintf('T6         = %0.8g',h(17))); end
T7 = h(18);
if (h(18) ~= -12345 & nargin == 1); disp(sprintf('T7         = %0.8g',h(18))); end
T8 = h(19);
if (h(19) ~= -12345 & nargin == 1); disp(sprintf('T8         = %0.8g',h(19))); end
T9 = h(20);
if (h(20) ~= -12345 & nargin == 1); disp(sprintf('T9         = %0.8g',h(20))); end
F = h(21);
if (h(21) ~= -12345 & nargin == 1); disp(sprintf('F          = %0.8g',h(21))); end
RESP0 = h(22);
if (h(22) ~= -12345 & nargin == 1); disp(sprintf('RESP0      = %0.8g',h(22))); end
RESP1 = h(23);
if (h(23) ~= -12345 & nargin == 1); disp(sprintf('RESP1      = %0.8g',h(23))); end
RESP2 = h(24);
if (h(24) ~= -12345 & nargin == 1); disp(sprintf('RESP2      = %0.8g',h(24))); end
RESP3 = h(25);
if (h(25) ~= -12345 & nargin == 1); disp(sprintf('RESP3      = %0.8g',h(25))); end
RESP4 = h(26);
if (h(26) ~= -12345 & nargin == 1); disp(sprintf('RESP4      = %0.8g',h(26))); end
RESP5 = h(27);
if (h(27) ~= -12345 & nargin == 1); disp(sprintf('RESP5      = %0.8g',h(27))); end
RESP6 = h(28);
if (h(28) ~= -12345 & nargin == 1); disp(sprintf('RESP6      = %0.8g',h(28))); end
RESP7 = h(29);
if (h(29) ~= -12345 & nargin == 1); disp(sprintf('RESP7      = %0.8g',h(29))); end
RESP8 = h(30);
if (h(30) ~= -12345 & nargin == 1); disp(sprintf('RESP8      = %0.8g',h(30))); end
RESP9 = h(31);
if (h(31) ~= -12345 & nargin == 1); disp(sprintf('RESP9      = %0.8g',h(31))); end
STLA = h(32);
if (h(32) ~= -12345 & nargin == 1); disp(sprintf('STLA       = %0.8g',h(32))); end
STLO = h(33);
if (h(33) ~= -12345 & nargin == 1); disp(sprintf('STLO       = %0.8g',h(33))); end
STEL = h(34);
if (h(34) ~= -12345 & nargin == 1); disp(sprintf('STEL       = %0.8g',h(34))); end
STDP = h(35);
if (h(35) ~= -12345 & nargin == 1); disp(sprintf('STDP       = %0.8g',h(35))); end
EVLA = h(36);
if (h(36) ~= -12345 & nargin == 1); disp(sprintf('EVLA       = %0.8g',h(36))); end
EVLO = h(37);
if (h(37) ~= -12345 & nargin == 1); disp(sprintf('EVLO       = %0.8g',h(37))); end
EVEL = h(38);
if (h(38) ~= -12345 & nargin == 1); disp(sprintf('EVEL       = %0.8g',h(38))); end
EVDP = h(39);
if (h(39) ~= -12345 & nargin == 1); disp(sprintf('EVDP       = %0.8g',h(39))); end
MAG = h(40);
if (h(40) ~= -12345 & nargin == 1); disp(sprintf('MAG        = %0.8g',h(40))); end
USER0 = h(41);
if (h(41) ~= -12345 & nargin == 1); disp(sprintf('USER0      = %0.8g',h(41))); end
USER1 = h(42);
if (h(42) ~= -12345 & nargin == 1); disp(sprintf('USER1      = %0.8g',h(42))); end
USER2 = h(43);
if (h(43) ~= -12345 & nargin == 1); disp(sprintf('USER2      = %0.8g',h(43))); end
USER3 = h(44);
if (h(44) ~= -12345 & nargin == 1); disp(sprintf('USER3      = %0.8g',h(44))); end
USER4 = h(45);
if (h(45) ~= -12345 & nargin == 1); disp(sprintf('USER4      = %0.8g',h(45))); end
USER5 = h(46);
if (h(46) ~= -12345 & nargin == 1); disp(sprintf('USER5      = %0.8g',h(46))); end
USER6 = h(47);
if (h(47) ~= -12345 & nargin == 1); disp(sprintf('USER6      = %0.8g',h(47))); end
USER7 = h(48);
if (h(48) ~= -12345 & nargin == 1); disp(sprintf('USER7      = %0.8g',h(48))); end
USER8 = h(49);
if (h(49) ~= -12345 & nargin == 1);  disp(sprintf('USER8     = %0.8g',h(49))); end
USER9 = h(50);
if (h(50) ~= -12345 & nargin == 1); disp(sprintf('USER9      = %0.8g',h(50))); end
DIST = h(51);
if (h(51) ~= -12345 & nargin == 1); disp(sprintf('DIST       = %0.8g',h(51))); end
AZ = h(52);
if (h(52) ~= -12345 & nargin == 1); disp(sprintf('AZ         = %0.8g',h(52))); end
BAZ = h(53);
if (h(53) ~= -12345 & nargin == 1); disp(sprintf('BAZ        = %0.8g',h(53))); end
GCARC = h(54);
if (h(54) ~= -12345 & nargin == 1); disp(sprintf('GCARC      = %0.8g',h(54))); end
DEPMEN = h(57);
if (h(57) ~= -12345 & nargin == 1); disp(sprintf('DEPMEN     = %0.8g',h(57))); end
CMPAZ = h(58);
if (h(58) ~= -12345 & nargin == 1); disp(sprintf('CMPAZ      = %0.8g',h(58))); end
CMPINC = h(59);
if (h(59) ~= -12345 & nargin == 1); disp(sprintf('CMPINC     = %0.8g',h(59))); end
XMINIMUM = h(60);
if (h(60) ~= -12345 & nargin == 1); disp(sprintf('XMINIMUM   = %0.8g',h(60))); end
XMAXIMUM = h(61);
if (h(61) ~= -12345 & nargin == 1); disp(sprintf('XMAXIMUM   = %0.8g',h(61))); end
YMINIMUM = h(62);
if (h(62) ~= -12345 & nargin == 1); disp(sprintf('YMINIMUM   = %0.8g',h(62))); end
YMAXIMUM = h(63);
if (h(63) ~= -12345 & nargin == 1); disp(sprintf('YMAXIMUM   = %0.8g',h(63))); end

% read integer header variables
%---------------------------------------------------------------------------
NZYEAR = round(h(71));
if (h(71) ~= -12345 & nargin == 1); disp(sprintf('NZYEAR     = %d',h(71))); end
NZJDAY = round(h(72));
if (h(72) ~= -12345 & nargin == 1); disp(sprintf('NZJDAY     = %d',h(72))); end
NZHOUR = round(h(73));
if (h(73) ~= -12345 & nargin == 1); disp(sprintf('NZHOUR     = %d',h(73))); end
NZMIN = round(h(74));
if (h(74) ~= -12345 & nargin == 1); disp(sprintf('NZMIN      = %d',h(74))); end
NZSEC = round(h(75));
if (h(75) ~= -12345 & nargin == 1); disp(sprintf('NZSEC      = %d',h(75))); end
NZMSEC = round(h(76));
if (h(76) ~= -12345 & nargin == 1); disp(sprintf('NZMSEC     = %d',h(76))); end
NVHDR = round(h(77));
if (h(77) ~= -12345 & nargin == 1); disp(sprintf('NVHDR      = %d',h(77))); end
NORID = round(h(78));
if (h(78) ~= -12345 & nargin == 1); disp(sprintf('NORID      = %d',h(78))); end
NEVID = round(h(79));
if (h(79) ~= -12345 & nargin == 1); disp(sprintf('NEVID      = %d',h(79))); end
NPTS = round(h(80));
if (h(80) ~= -12345 & nargin == 1); disp(sprintf('NPTS       = %d',h(80))); end
NWFID = round(h(82));
if (h(82) ~= -12345 & nargin == 1); disp(sprintf('NWFID      = %d',h(82))); end
NXSIZE = round(h(83));
if (h(83) ~= -12345 & nargin == 1); disp(sprintf('NXSIZE     = %d',h(83))); end
NYSIZE = round(h(84));
if (h(84) ~= -12345 & nargin == 1); disp(sprintf('NYSIZE     = %d',h(84))); end
IFTYPE = round(h(86));
if (h(86) ~= -12345 & nargin == 1); disp(sprintf('IFTYPE     = %d',h(86))); end
IDEP = round(h(87));
if (h(87) ~= -12345 & nargin == 1); disp(sprintf('IDEP       = %d',h(87))); end
IZTYPE = round(h(88));
if (h(88) ~= -12345 & nargin == 1); disp(sprintf('IZTYPE     = %d',h(88))); end
IINST = round(h(90));
if (h(90) ~= -12345 & nargin == 1); disp(sprintf('IINST      = %d',h(90))); end
ISTREG = round(h(91));
if (h(91) ~= -12345 & nargin == 1); disp(sprintf('ISTREG     = %d',h(91))); end
IEVREG = round(h(92));
if (h(92) ~= -12345 & nargin == 1); disp(sprintf('IEVREG     = %d',h(92))); end
IEVTYP = round(h(93));
if (h(93) ~= -12345 & nargin == 1); disp(sprintf('IEVTYP     = %d',h(93))); end
IQUAL = round(h(94));
if (h(94) ~= -12345 & nargin == 1); disp(sprintf('IQUAL      = %d',h(94))); end
ISYNTH = round(h(95));
if (h(95) ~= -12345 & nargin == 1); disp(sprintf('ISYNTH     = %d',h(95))); end
IMAGTYP = round(h(96));
if (h(96) ~= -12345 & nargin == 1); disp(sprintf('IMAGTYP    = %d',h(96))); end
IMAGSRC = round(h(97));
if (h(97) ~= -12345 & nargin == 1); disp(sprintf('IMAGSRC    = %d',h(97))); end

%read logical header variables
%---------------------------------------------------------------------------
LEVEN = round(h(106));
if (h(106) ~= -12345 & nargin == 1); disp(sprintf('LEVEN      = %d',h(106))); end
LPSPOL = round(h(107));
if (h(107) ~= -12345 & nargin == 1); disp(sprintf('LPSPOL     = %d',h(107))); end
LOVROK = round(h(108));
if (h(108) ~= -12345 & nargin == 1); disp(sprintf('LOVROK     = %d',h(108))); end
LCALDA = round(h(109));
if (h(109) ~= -12345 & nargin == 1); disp(sprintf('LCALDA     = %d',h(109))); end

%read character header variables
%---------------------------------------------------------------------------
KSTNM = char(h(111:118));
if (str2double(KSTNM) ~= -12345 & nargin == 1); disp(sprintf('KSTNM      = %s', KSTNM)); end
KEVNM = char(h(119:134));
if (str2double(KEVNM) ~= -12345 & nargin == 1); disp(sprintf('KEVNM      = %s', KEVNM)); end
KHOLE = char(h(135:142));
if (str2double(KHOLE) ~= -12345 & nargin == 1); disp(sprintf('KHOLE      = %s', KHOLE)); end
KO = char(h(143:150));
if (str2double(KO) ~= -12345 & nargin == 1); disp(sprintf('KO         = %s', KO)); end
KA = char(h(151:158));
if (str2double(KA) ~= -12345 & nargin == 1); disp(sprintf('KA         = %s', KA)); end
KT0 = char(h(159:166));
if (str2double(KT0) ~= -12345 & nargin == 1); disp(sprintf('KT0        = %s', KT0)); end
KT1 = char(h(167:174));
if (str2double(KT1) ~= -12345 & nargin == 1); disp(sprintf('KT1        = %s', KT1)); end
KT2 = char(h(175:182));
if (str2double(KT2) ~= -12345 & nargin == 1); disp(sprintf('KT2        = %s', KT2)); end
KT3 = char(h(183:190));
if (str2double(KT3) ~= -12345 & nargin == 1); disp(sprintf('KT3        = %s', KT3)); end
KT4 = char(h(191:198));
if (str2double(KT4) ~= -12345 & nargin == 1); disp(sprintf('KT4        = %s', KT4)); end
KT5 = char(h(199:206));
if (str2double(KT5) ~= -12345 & nargin == 1); disp(sprintf('KT5        = %s', KT5)); end
KT6 = char(h(207:214));
if (str2double(KT6) ~= -12345 & nargin == 1); disp(sprintf('KT6        = %s', KT6)); end
KT7 = char(h(215:222));
if (str2double(KT7) ~= -12345 & nargin == 1); disp(sprintf('KT7        = %s', KT7)); end
KT8 = char(h(223:230));
if (str2double(KT8) ~= -12345 & nargin == 1); disp(sprintf('KT8        = %s', KT8)); end
KT9 = char(h(231:238));
if (str2double(KT9) ~= -12345 & nargin == 1); disp(sprintf('KT9        = %s', KT9)); end
KF = char(h(239:246));
if (str2double(KF) ~= -12345 & nargin == 1); disp(sprintf('KF         = %s', KF)); end
KUSER0 = char(h(247:254));
if (str2double(KUSER0) ~= -12345 & nargin == 1); disp(sprintf('KUSER0     = %s', KUSER0)); end
KUSER1 = char(h(255:262));
if (str2double(KUSER1) ~= -12345 & nargin == 1); disp(sprintf('KUSER1     = %s', KUSER1)); end
KUSER2 = char(h(263:270));
if (str2double(KUSER2) ~= -12345 & nargin == 1); disp(sprintf('KUSER2     = %s', KUSER2)); end
KCMPNM = char(h(271:278));
if (str2double(KCMPNM) ~= -12345 & nargin == 1); disp(sprintf('KCMPNM     = %s', KCMPNM)); end
KNETWK = char(h(279:286));
if (str2double(KNETWK) ~= -12345 & nargin == 1); disp(sprintf('KNETWK     = %s', KNETWK)); end
KDATRD = char(h(287:294));
if (str2double(KDATRD) ~= -12345 & nargin == 1); disp(sprintf('KDATRD     = %s', KDATRD)); end
KINST = char(h(295:302));
if (str2double(KINST) ~= -12345 & nargin == 1); disp(sprintf('KINST      = %s', KINST)); end
if nargin > 1
    for nrecs = 1:(nargin-1);
        varargout{nrecs} = eval(varargin{nrecs});
    end
end
function [Pxx, Pxxc, f] = psd2(varargin)
%PSD Power Spectral Density estimate.
%   PSD has been replaced by SPECTRUM.WELCH.  PSD still works but may be
%   removed in the future. Use SPECTRUM.WELCH (or its functional form
%   PWELCH) instead. Type help SPECTRUM/WELCH for details.
%
%   See also SPECTRUM/PSD, SPECTRUM/MSSPECTRUM, SPECTRUM/PERIODOGRAM.

%   Author(s): T. Krauss, 3-26-93
%   Copyright 1988-2004 The MathWorks, Inc.
%   $Revision: 1.12.4.2 $  $Date: 2004/04/13 00:18:55 $

%   NOTE 1: To express the result of PSD, Pxx, in units of
%           Power per Hertz multiply Pxx by 1/Fs [1].
%
%   NOTE 2: The Power Spectral Density of a continuous-time signal,
%           Pss (watts/Hz), is proportional to the Power Spectral
%           Density of the sampled discrete-time signal, Pxx, by Ts
%           (sampling period). [2]
%
%               Pss(w/Ts) = Pxx(w)*Ts,    |w| < pi; where w = 2*pi*f*Ts

%   References:
%     [1] Petre Stoica and Randolph Moses, Introduction To Spectral
%         Analysis, Prentice hall, 1997, pg, 15
%     [2] A.V. Oppenheim and R.W. Schafer, Discrete-Time Signal
%         Processing, Prentice-Hall, 1989, pg. 731
%     [3] A.V. Oppenheim and R.W. Schafer, Digital Signal
%         Processing, Prentice-Hall, 1975, pg. 556

error(nargchk(1,7,nargin))
x = varargin{1};
[msg,nfft,Fs,window,noverlap,p,dflag]=psdchk(varargin(2:end),x);
error(msg)

% compute PSD
window = window(:);
n = length(x);		    % Number of data points
nwind = length(window); % length of window
if n < nwind            % zero-pad x if it has length less than the window length
    x(nwind)=0;  n=nwind;
end
% Make sure x is a column vector; do this AFTER the zero-padding
% in case x is a scalar.
x = x(:);

k = fix((n-noverlap)/(nwind-noverlap));	% Number of windows
% (k = fix(n/nwind) for noverlap=0)
%   if 0
%       disp(sprintf('   x        = (length %g)',length(x)))
%       disp(sprintf('   y        = (length %g)',length(y)))
%       disp(sprintf('   nfft     = %g',nfft))
%       disp(sprintf('   Fs       = %g',Fs))
%       disp(sprintf('   window   = (length %g)',length(window)))
%       disp(sprintf('   noverlap = %g',noverlap))
%       if ~isempty(p)
%           disp(sprintf('   p        = %g',p))
%       else
%           disp('   p        = undefined')
%       end
%       disp(sprintf('   dflag    = ''%s''',dflag))
%       disp('   --------')
%       disp(sprintf('   k        = %g',k))
%   end

index = 1:nwind;
KMU = k*norm(window)^2;	% Normalizing scale factor ==> asymptotically unbiased
% KMU = k*sum(window)^2;% alt. Nrmlzng scale factor ==> peaks are about right

Spec = zeros(nfft,1); Spec2 = zeros(nfft,1);
for i=1:k
    if strcmp(dflag,'none')
        xw = window.*(x(index));
    elseif strcmp(dflag,'linear')
        xw = window.*detrend(x(index));
    else
        xw = window.*detrend(x(index),'constant');
    end
    index = index + (nwind - noverlap);
    Xx = abs(fft(xw,nfft)).^2;
    Spec = Spec + Xx;
    Spec2 = Spec2 + abs(Xx).^2;
end

% Select first half
if ~any(any(imag(x)~=0)),   % if x is not complex
    if rem(nfft,2),    % nfft odd
        select = (1:(nfft+1)/2)';
    else
        select = (1:nfft/2+1)';
    end
    Spec = Spec(select);
    Spec2 = Spec2(select);
    %    Spec = 4*Spec(select);     % double the signal content - essentially
    % folding over the negative frequencies onto the positive and adding.
    %    Spec2 = 16*Spec2(select);
else
    select = (1:nfft)';
end
freq_vector = (select - 1)*Fs/nfft;

% find confidence interval if needed
if (nargout == 3)|((nargout == 0)&~isempty(p)),
    if isempty(p),
        p = .95;    % default
    end
    % Confidence interval from Kay, p. 76, eqn 4.16:
    % (first column is lower edge of conf int., 2nd col is upper edge)
    confid = Spec*chi2conf(p,k)/KMU;
    
    if noverlap > 0
        %disp('Warning: confidence intervals inaccurate for NOVERLAP > 0.');
    end
end

Spec = Spec*(1/KMU);   % normalize

% set up output parameters
if (nargout == 3),
    Pxx = Spec;
    Pxxc = confid;
    f = freq_vector;
elseif (nargout == 2),
    Pxx = Spec;
    Pxxc = freq_vector;
elseif (nargout == 1),
    Pxx = Spec;
elseif (nargout == 0),
    if ~isempty(p),
        P = [Spec confid];
    else
        P = Spec;
    end
    newplot;
    plot(freq_vector,10*log10(abs(P))), grid on
    xlabel('Frequency'), ylabel('Power Spectrum Magnitude (dB)');
end

function [msg,nfft,Fs,window,noverlap,p,dflag] = psdchk(P,x,y)
%PSDCHK Helper function for PSD, CSD, COHERE, and TFE.
%   [msg,nfft,Fs,window,noverlap,p,dflag]=PSDCHK(P,x,y) takes the cell
%   array P and uses each element as an input argument.  Assumes P has
%   between 0 and 7 elements which are the arguments to psd, csd, cohere
%   or tfe after the x (psd) or x and y (csd, cohere, tfe) arguments.
%   y is optional; if given, it is checked to match the size of x.
%   x must be a numeric vector.
%   Outputs:
%     msg - error message, [] if no error
%     nfft - fft length
%     Fs - sampling frequency
%     window - window vector
%     noverlap - overlap of sections, in samples
%     p - confidence interval, [] if none desired
%     dflag - detrending flag, 'linear' 'mean' or 'none'

%   Author(s): T. Krauss, 10-28-93
%   Copyright 1988-2002 The MathWorks, Inc.
%       $Revision: 1.6 $  $Date: 2002/04/15 01:08:06 $

msg = [];

if length(P) == 0
    % psd(x)
    nfft = min(length(x),256);
    window = hanning(nfft);
    noverlap = 0;
    Fs = 2;
    p = [];
    dflag = 'none';
elseif length(P) == 1
    % psd(x,nfft)
    % psd(x,dflag)
    if isempty(P{1}),   dflag = 'none'; nfft = min(length(x),256);
    elseif isstr(P{1}), dflag = P{1};       nfft = min(length(x),256);
    else              dflag = 'none'; nfft = P{1};   end
    Fs = 2;
    window = hanning(nfft);
    noverlap = 0;
    p = [];
elseif length(P) == 2
    % psd(x,nfft,Fs)
    % psd(x,nfft,dflag)
    if isempty(P{1}), nfft = min(length(x),256); else nfft=P{1};     end
    if isempty(P{2}),   dflag = 'none'; Fs = 2;
    elseif isstr(P{2}), dflag = P{2};       Fs = 2;
    else              dflag = 'none'; Fs = P{2}; end
    window = hanning(nfft);
    noverlap = 0;
    p = [];
elseif length(P) == 3
    % psd(x,nfft,Fs,window)
    % psd(x,nfft,Fs,dflag)
    if isempty(P{1}), nfft = min(length(x),256); else nfft=P{1};     end
    if isempty(P{2}), Fs = 2;     else    Fs = P{2}; end
    if isstr(P{3})
        dflag = P{3};
        window = hanning(nfft);
    else
        dflag = 'none';
        window = P{3};
        if length(window) == 1, window = hanning(window); end
        if isempty(window), window = hanning(nfft); end
    end
    noverlap = 0;
    p = [];
elseif length(P) == 4
    % psd(x,nfft,Fs,window,noverlap)
    % psd(x,nfft,Fs,window,dflag)
    if isempty(P{1}), nfft = min(length(x),256); else nfft=P{1};     end
    if isempty(P{2}), Fs = 2;     else    Fs = P{2}; end
    window = P{3};
    if length(window) == 1, window = hanning(window); end
    if isempty(window), window = hanning(nfft); end
    if isstr(P{4})
        dflag = P{4};
        noverlap = 0;
    else
        dflag = 'none';
        if isempty(P{4}), noverlap = 0; else noverlap = P{4}; end
    end
    p = [];
elseif length(P) == 5
    % psd(x,nfft,Fs,window,noverlap,p)
    % psd(x,nfft,Fs,window,noverlap,dflag)
    if isempty(P{1}), nfft = min(length(x),256); else nfft=P{1};     end
    if isempty(P{2}), Fs = 2;     else    Fs = P{2}; end
    window = P{3};
    if length(window) == 1, window = hanning(window); end
    if isempty(window), window = hanning(nfft); end
    if isempty(P{4}), noverlap = 0; else noverlap = P{4}; end
    if isstr(P{5})
        dflag = P{5};
        p = [];
    else
        dflag = 'none';
        if isempty(P{5}), p = .95;    else    p = P{5}; end
    end
elseif length(P) == 6
    % psd(x,nfft,Fs,window,noverlap,p,dflag)
    if isempty(P{1}), nfft = min(length(x),256); else nfft=P{1};     end
    if isempty(P{2}), Fs = 2;     else    Fs = P{2}; end
    window = P{3};
    if length(window) == 1, window = hanning(window); end
    if isempty(window), window = hanning(nfft); end
    if isempty(P{4}), noverlap = 0; else noverlap = P{4}; end
    if isempty(P{5}), p = .95;    else    p = P{5}; end
    if isstr(P{6})
        dflag = P{6};
    else
        msg = 'DFLAG parameter must be a string.'; return
    end
end

% NOW do error checking
if (nfft<length(window)),
    msg = 'Requires window''s length to be no greater than the FFT length.';
end
if (noverlap >= length(window)),
    msg = 'Requires NOVERLAP to be strictly less than the window length.';
end
if (nfft ~= abs(round(nfft)))|(noverlap ~= abs(round(noverlap))),
    msg = 'Requires positive integer values for NFFT and NOVERLAP.';
end
if ~isempty(p),
    if (prod(size(p))>1)|(p(1,1)>1)|(p(1,1)<0),
        msg = 'Requires confidence parameter to be a scalar between 0 and 1.';
    end
end
if min(size(x))~=1 | ~isnumeric(x) | length(size(x))>2
    msg = 'Requires vector (either row or column) input.';
end
if (nargin>2) & ( (min(size(y))~=1) | ~isnumeric(y) | length(size(y))>2 )
    msg = 'Requires vector (either row or column) input.';
end
if (nargin>2) & (length(x)~=length(y))
    msg = 'Requires X and Y be the same length.';
end

dflag = lower(dflag);
if strncmp(dflag,'none',1)
    dflag = 'none';
elseif strncmp(dflag,'linear',1)
    dflag = 'linear';
elseif strncmp(dflag,'mean',1)
    dflag = 'mean';
else
    msg = 'DFLAG must be ''linear'', ''mean'', or ''none''.';
end

function c = chi2conf(conf,k);
%CHI2CONF Confidence interval using inverse of chi-square cdf.
%   C = CHI2CONF(P,K) is the confidence interval of an unbiased power spectrum
%   estimate made up of K independent measurements.  C is a two element
%   vector.  We are P*100% confident that the true PSD lies in the interval
%   [C(1)*X C(2)*X], where X is the PSD estimate.
%
%   Reference:
%     Stephen Kay, "Modern Spectral Analysis, Theory & Application,"
%     p. 76, eqn 4.16.

%   Copyright 1988-2002 The MathWorks, Inc.
%   $Revision: 1.6 $  $Date: 2002/04/15 01:07:39 $

if nargin < 2,
    error('Requires two input arguments.');
end

v=2*k;
alfa = 1 - conf;
c=chi2inv([1-alfa/2 alfa/2],v);
c=v./c;

function x = chi2inv(p,v);
%CHI2INV Inverse of the chi-square cumulative distribution function (cdf).
%   X = CHI2INV(P,V)  returns the inverse of the chi-square cdf with V
%   degrees of freedom at the values in P. The chi-square cdf with V
%   degrees of freedom, is the gamma cdf with parameters V/2 and 2.
%
%   The size of X is the common size of P and V. A scalar input
%   functions as a constant matrix of the same size as the other input.

%   References:
%      [1]  M. Abramowitz and I. A. Stegun, "Handbook of Mathematical
%      Functions", Government Printing Office, 1964, 26.4.
%      [2] E. Kreyszig, "Introductory Mathematical Statistics",
%      John Wiley, 1970, section 10.2 (page 144)

%  Was: Revision: 1.2, Date: 1996/07/25 16:23:36

if nargin < 2,
    error('Requires two input arguments.');
end

[errorcode p v] = distchck(2,p,v);

if errorcode > 0
    error('Requires non-scalar arguments to match in size.');
end

% Call the gamma inverse function.
x = gaminv(p,v/2,2);

% Return NaN if the degrees of freedom is not a positive integer.
k = find(v < 0  |  round(v) ~= v);
if any(k)
    tmp  = NaN;
    x(k) = tmp(ones(size(k)));
end


function x = gaminv(p,a,b);
%GAMINV Inverse of the gamma cumulative distribution function (cdf).
%   X = GAMINV(P,A,B)  returns the inverse of the gamma cdf with
%   parameters A and B, at the probabilities in P.
%
%   The size of X is the common size of the input arguments. A scalar input
%   functions as a constant matrix of the same size as the other inputs.
%
%   GAMINV uses Newton's method to converge to the solution.

%   References:
%      [1]  M. Abramowitz and I. A. Stegun, "Handbook of Mathematical
%      Functions", Government Printing Office, 1964, 6.5.

%   B.A. Jones 1-12-93
%   Was: Revision: 1.2, Date: 1996/07/25 16:23:36

if nargin<3,
    b=1;
end

[errorcode p a b] = distchck(3,p,a,b);

if errorcode > 0
    error('The arguments must be the same size or be scalars.');
end

%   Initialize X to zero.
x = zeros(size(p));

k = find(p<0 | p>1 | a <= 0 | b <= 0);
if any(k),
    tmp = NaN;
    x(k) = tmp(ones(size(k)));
end

% The inverse cdf of 0 is 0, and the inverse cdf of 1 is 1.
k0 = find(p == 0 & a > 0 & b > 0);
if any(k0),
    x(k0) = zeros(size(k0));
end

k1 = find(p == 1 & a > 0 & b > 0);
if any(k1),
    tmp = Inf;
    x(k1) = tmp(ones(size(k1)));
end

% Newton's Method
% Permit no more than count_limit interations.
count_limit = 100;
count = 0;

k = find(p > 0  &  p < 1 & a > 0 & b > 0);
pk = p(k);

% Supply a starting guess for the iteration.
%   Use a method of moments fit to the lognormal distribution.
mn = a(k) .* b(k);
v = mn .* b(k);
temp = log(v + mn .^ 2);
mu = 2 * log(mn) - 0.5 * temp;
sigma = -2 * log(mn) + temp;
xk = exp(norminv(pk,mu,sigma));

h = ones(size(pk));

% Break out of the iteration loop for three reasons:
%  1) the last update is very small (compared to x)
%  2) the last update is very small (compared to sqrt(eps))
%  3) There are more than 100 iterations. This should NEVER happen.

while(any(abs(h) > sqrt(eps)*abs(xk))  &  max(abs(h)) > sqrt(eps)    ...
        & count < count_limit),
    
    count = count + 1;
    h = (gamcdf(xk,a(k),b(k)) - pk) ./ gampdf(xk,a(k),b(k));
    xnew = xk - h;
    % Make sure that the current guess stays greater than zero.
    % When Newton's Method suggests steps that lead to negative guesses
    % take a step 9/10ths of the way to zero:
    ksmall = find(xnew < 0);
    if any(ksmall),
        xnew(ksmall) = xk(ksmall) / 10;
        h = xk-xnew;
    end
    xk = xnew;
end


% Store the converged value in the correct place
x(k) = xk;

if count == count_limit,
    fprintf('\nWarning: GAMINV did not converge.\n');
    str = 'The last step was:  ';
    outstr = sprintf([str,'%13.8f'],h);
    fprintf(outstr);
end

function x = norminv(p,mu,sigma);
%NORMINV Inverse of the normal cumulative distribution function (cdf).
%   X = NORMINV(P,MU,SIGMA) finds the inverse of the normal cdf with
%   mean, MU, and standard deviation, SIGMA.
%
%   The size of X is the common size of the input arguments. A scalar input
%   functions as a constant matrix of the same size as the other inputs.
%
%   Default values for MU and SIGMA are 0 and 1 respectively.

%   References:
%      [1]  M. Abramowitz and I. A. Stegun, "Handbook of Mathematical
%      Functions", Government Printing Office, 1964, 7.1.1 and 26.2.2

%   Was: Revision: 1.2, Date: 1996/07/25 16:23:36

if nargin < 3,
    sigma = 1;
end

if nargin < 2;
    mu = 0;
end

[errorcode p mu sigma] = distchck(3,p,mu,sigma);

if errorcode > 0
    error('Requires non-scalar arguments to match in size.');
end

% Allocate space for x.
x = zeros(size(p));

% Return NaN if the arguments are outside their respective limits.
k = find(sigma <= 0 | p < 0 | p > 1);
if any(k)
    tmp  = NaN;
    x(k) = tmp(ones(size(k)));
end

% Put in the correct values when P is either 0 or 1.
k = find(p == 0);
if any(k)
    tmp  = Inf;
    x(k) = -tmp(ones(size(k)));
end

k = find(p == 1);
if any(k)
    tmp  = Inf;
    x(k) = tmp(ones(size(k)));
end

% Compute the inverse function for the intermediate values.
k = find(p > 0  &  p < 1 & sigma > 0);
if any(k),
    x(k) = sqrt(2) * sigma(k) .* erfinv(2 * p(k) - 1) + mu(k);
end


function p = gamcdf(x,a,b);
%GAMCDF Gamma cumulative distribution function.
%   P = GAMCDF(X,A,B) returns the gamma cumulative distribution
%   function with parameters A and B at the values in X.
%
%   The size of P is the common size of the input arguments. A scalar input
%   functions as a constant matrix of the same size as the other inputs.
%
%   Some references refer to the gamma distribution with a single
%   parameter. This corresponds to the default of B = 1.
%
%   GAMMAINC does computational work.

%   References:
%      [1]  L. Devroye, "Non-Uniform Random Variate Generation",
%      Springer-Verlag, 1986. p. 401.
%      [2]  M. Abramowitz and I. A. Stegun, "Handbook of Mathematical
%      Functions", Government Printing Office, 1964, 26.1.32.

%   Was: Revision: 1.2, Date: 1996/07/25 16:23:36

if nargin < 3,
    b = 1;
end

if nargin < 2,
    error('Requires at least two input arguments.');
end

[errorcode x a b] = distchck(3,x,a,b);

if errorcode > 0
    error('Requires non-scalar arguments to match in size.');
end

%   Return NaN if the arguments are outside their respective limits.
k1 = find(a <= 0 | b <= 0);
if any(k1)
    tmp   = NaN;
    p(k1) = tmp(ones(size(k1)));
end

% Initialize P to zero.
p = zeros(size(x));

k = find(x > 0 & ~(a <= 0 | b <= 0));
if any(k),
    p(k) = gammainc(x(k) ./ b(k),a(k));
end

% Make sure that round-off errors never make P greater than 1.
k = find(p > 1);
if any(k)
    p(k) = ones(size(k));
end


function y = gampdf(x,a,b)
%GAMPDF Gamma probability density function.
%   Y = GAMPDF(X,A,B) returns the gamma probability density function
%   with parameters A and B, at the values in X.
%
%   The size of Y is the common size of the input arguments. A scalar input
%   functions as a constant matrix of the same size as the other inputs.
%
%   Some references refer to the gamma distribution with a single
%   parameter. This corresponds to the default of B = 1.

%   References:
%      [1]  L. Devroye, "Non-Uniform Random Variate Generation",
%      Springer-Verlag, 1986, pages 401-402.

%   Was: Revision: 1.2, Date: 1996/07/25 16:23:36

if nargin < 3,
    b = 1;
end

if nargin < 2,
    error('Requires at least two input arguments');
end

[errorcode x a b] = distchck(3,x,a,b);

if errorcode > 0
    error('Requires non-scalar arguments to match in size.');
end

% Initialize Y to zero.
y = zeros(size(x));

%   Return NaN if the arguments are outside their respective limits.
k1 = find(a <= 0 | b <= 0);
if any(k1)
    tmp = NaN;
    y(k1) = tmp(ones(size(k1)));
end

k=find(x > 0 & ~(a <= 0 | b <= 0));
if any(k)
    y(k) = (a(k) - 1) .* log(x(k)) - (x(k) ./ b(k)) - gammaln(a(k)) - a(k) .* log(b(k));
    y(k) = exp(y(k));
end
k1 = find(x == 0 & a < 1);
if any(k1)
    tmp = Inf;
    y(k1) = tmp(ones(size(k1)));
end
k2 = find(x == 0 & a == 1);
if any(k2)
    y(k2) = (1./b(k2));
end

function [errorcode,out1,out2,out3,out4] = distchck(nparms,arg1,arg2,arg3,arg4)
%DISTCHCK Checks the argument list for the probability functions.

%   B.A. Jones  1-22-93
%   Was: Revision: 1.2, Date: 1996/07/25 16:23:36

errorcode = 0;

if nparms == 1
    out1 = arg1;
    return;
end

if nparms == 2
    [r1 c1] = size(arg1);
    [r2 c2] = size(arg2);
    scalararg1 = (prod(size(arg1)) == 1);
    scalararg2 = (prod(size(arg2)) == 1);
    if ~scalararg1 & ~scalararg2
        if r1 ~= r2 | c1 ~= c2
            errorcode = 1;
            return;
        end
    end
    if scalararg1
        out1 = arg1(ones(r2,1),ones(c2,1));
    else
        out1 = arg1;
    end
    if scalararg2
        out2 = arg2(ones(r1,1),ones(c1,1));
    else
        out2 = arg2;
    end
end

if nparms == 3
    [r1 c1] = size(arg1);
    [r2 c2] = size(arg2);
    [r3 c3] = size(arg3);
    scalararg1 = (prod(size(arg1)) == 1);
    scalararg2 = (prod(size(arg2)) == 1);
    scalararg3 = (prod(size(arg3)) == 1);
    
    if ~scalararg1 & ~scalararg2
        if r1 ~= r2 | c1 ~= c2
            errorcode = 1;
            return;
        end
    end
    
    if ~scalararg1 & ~scalararg3
        if r1 ~= r3 | c1 ~= c3
            errorcode = 1;
            return;
        end
    end
    
    if ~scalararg3 & ~scalararg2
        if r3 ~= r2 | c3 ~= c2
            errorcode = 1;
            return;
        end
    end
    
    if ~scalararg1
        out1 = arg1;
    end
    if ~scalararg2
        out2 = arg2;
    end
    if ~scalararg3
        out3 = arg3;
    end
    rows = max([r1 r2 r3]);
    columns = max([c1 c2 c3]);
    
    if scalararg1
        out1 = arg1(ones(rows,1),ones(columns,1));
    end
    if scalararg2
        out2 = arg2(ones(rows,1),ones(columns,1));
    end
    if scalararg3
        out3 = arg3(ones(rows,1),ones(columns,1));
    end
    out4 =[];
    
end

if nparms == 4
    [r1 c1] = size(arg1);
    [r2 c2] = size(arg2);
    [r3 c3] = size(arg3);
    [r4 c4] = size(arg4);
    scalararg1 = (prod(size(arg1)) == 1);
    scalararg2 = (prod(size(arg2)) == 1);
    scalararg3 = (prod(size(arg3)) == 1);
    scalararg4 = (prod(size(arg4)) == 1);
    
    if ~scalararg1 & ~scalararg2
        if r1 ~= r2 | c1 ~= c2
            errorcode = 1;
            return;
        end
    end
    
    if ~scalararg1 & ~scalararg3
        if r1 ~= r3 | c1 ~= c3
            errorcode = 1;
            return;
        end
    end
    
    if ~scalararg1 & ~scalararg4
        if r1 ~= r4 | c1 ~= c4
            errorcode = 1;
            return;
        end
    end
    
    if ~scalararg3 & ~scalararg2
        if r3 ~= r2 | c3 ~= c2
            errorcode = 1;
            return;
        end
    end
    
    if ~scalararg4 & ~scalararg2
        if r4 ~= r2 | c4 ~= c2
            errorcode = 1;
            return;
        end
    end
    
    if ~scalararg3 & ~scalararg4
        if r3 ~= r4 | c3 ~= c4
            errorcode = 1;
            return;
        end
    end
    
    
    if ~scalararg1
        out1 = arg1;
    end
    if ~scalararg2
        out2 = arg2;
    end
    if ~scalararg3
        out3 = arg3;
    end
    if ~scalararg4
        out4 = arg4;
    end
    
    rows = max([r1 r2 r3 r4]);
    columns = max([c1 c2 c3 c4]);
    if scalararg1
        out1 = arg1(ones(rows,1),ones(columns,1));
    end
    if scalararg2
        out2 = arg2(ones(rows,1),ones(columns,1));
    end
    if scalararg3
        out3 = arg3(ones(rows,1),ones(columns,1));
    end
    if scalararg4
        out4 = arg4(ones(rows,1),ones(columns,1));
    end
end

function [FLAG] = filetype(FILENAME)
% the filetype script detects the file
% type. It recognizes binary ('bin')
% and ASCII ('txt') format.
%
% sintax: FLAG = filetype(FILENAME)
%
% e.g. filetype('test.txt')
%
%   Author:
%       name:   David Zuliani
%       e-mail: dzuliani@inogs.it
%       web:    www.crs.inogs.it
%
format long g;
%
% FILE READING
N = 100; % number of Bytes to read
fid = fopen(FILENAME);
BYTES =  fread(fid, N);
fclose(fid);
%
% TEST BINARY FILE
% ASCII FILE usually are made of BYTES: 10, 13, and between 32 and 127
% BIN FILE usually are made of BYTES over  127
NUM_BYTES_ASC = size(find(BYTES<127 & BYTES>32 | BYTES==10 | BYTES==13),1); % ASCII file usually includes bytes between 32 and 127 plus 10 and 13
NUM_BYTES_BIN = size(find(BYTES>127),1); % binary file usually includes bytes outside the 32-127 range
if NUM_BYTES_ASC > NUM_BYTES_BIN;
    FLAG='txt';
else
    FLAG='bin';
end

function [OUT] = rsact(FILENAME)
% the rsact script reads the ASCII sac
% file.
%
% sintax: OUT = rsact(FILENAME)
%
% e.g. rsact('2012035110000.00.ACOM.HHE.asc')
%
%   Author:
%       name:   David Zuliani
%       e-mail: dzuliani@inogs.it
%       web:    www.crs.inogs.it
%
format long g;
%
% FILE READING
SAC_DATA        = textread(FILENAME,...
                        '%f', 'commentstyle','shell');  % reading the data
SAC_HEADER      = textread(FILENAME,...
                        '%s',148,'delimiter','\n');     % reading the header
%
% HEADER INFOS                    
OUT.sta         = getsacpar(SAC_HEADER,'KSTNM');
OUT.comp        = getsacpar(SAC_HEADER,'KCMPNM');
OUT.Tsamp       = str2num(getsacpar(SAC_HEADER,'DELTA'));
YEAR            = str2num(getsacpar(SAC_HEADER,'NZYEAR'));
DOY             = str2num(getsacpar(SAC_HEADER,'NZJDAY'));
FIRSTDOYSTR     = ['1-Jan-',num2str(YEAR)];
FIRSTDOYNUM     = datenum(FIRSTDOYSTR);
CURRENTDOYNUM   = FIRSTDOYNUM+DOY-1;
HOUR            = getsacpar(SAC_HEADER,'NZHOUR');
MINUTE          = getsacpar(SAC_HEADER,'NZMIN');
SECONDS         = getsacpar(SAC_HEADER,'NZSEC');
MSECONDS        = getsacpar(SAC_HEADER,'NZMSEC');
MSECONDS        = num2str(str2num(MSECONDS)/1000);
OUT.time        = [prezeros(HOUR),':',prezeros(MINUTE),':',prezeros(SECONDS),MSECONDS(2:end)];
OUT.date        = datestr(CURRENTDOYNUM,29);
%
% DATA INFOS
TIMEVECT        = (0:OUT.Tsamp:OUT.Tsamp*(size(SAC_DATA(:,1),1)-1))';
OUT.data        = [TIMEVECT,SAC_DATA];
%
% FUNCTIONS
function [VALUE] = getsacpar(TEXT,KEY)
% the getsacpar script gets the VALUE
% pointed by the key KEY inside the
% matrix of chars TEXT
%
% sintax: OUT = getsacpar(TEXT,KEY)
%
% e.g. getsacpar(A,'KSTNM')
%
%   Author:
%       name:   David Zuliani
%       e-mail: dzuliani@inogs.it
%       web:    www.crs.inogs.it
%
KEY = ['| ',KEY,' '];
INDEX       =   strfind(TEXT,KEY);
CELL_INDEX  =   find(cellfun(@isempty,(INDEX))==0);
TEXT_PARTS  =   textscan(TEXT{CELL_INDEX},'%s','delimiter','|');
VALUE       =   strtrim(TEXT_PARTS{1}{1}(2:end));
%
%
function [OUT] = prezeros(IN)
% the prezeros script pads with 0
% the input string IN.
%
% sintax: OUT = prezeros(IN)
%
% e.g. getsacpar('9')
%
%   Author:
%       name:   David Zuliani
%       e-mail: dzuliani@inogs.it
%       web:    www.crs.inogs.it
%
if size(IN,2) < 2
    OUT=['0',IN];
else
    OUT=IN;
end