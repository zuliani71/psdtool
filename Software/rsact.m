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