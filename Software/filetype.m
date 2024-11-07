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
