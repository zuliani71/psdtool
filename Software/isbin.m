%FILE = '/Users/dzuliani/VBOX.SHARE/Projects/Seismology/2012.TESTCAVO.BB_DRENCHIA/2012.02.23_DATISAC_TEST_PSDTOOL/dati_cuginetti/2012035110000.00.ACOM.HHE';
FILE = '/Users/dzuliani/VBOX.SHARE/Projects/Seismology/2012.TESTCAVO.BB_DRENCHIA/2012.02.23_DATISAC_TEST_PSDTOOL/dati_cuginetti/2012035110000.00.ACOM.HHE.asc';
fid = fopen(FILE);
    BYTES_FILE =  fread(fid, 100);
fclose(fid);
%
% TEST BINARY FILE
% ASCII FILE usually are made of BYTES: 10, 13, and between 32 and 127
% BIN FILE usually are made of BYTES over  127
NUM_BYTES = size(BYTES_FILE,1);
NUM_BYTES_ASC = size(find(BYTES_FILE<127 & BYTES_FILE>32 | BYTES_FILE==10 | BYTES_FILE==13),1);
NUM_BYTES_BIN = size(find(BYTES_FILE>127),1);
if NUM_BYTES_ASC > NUM_BYTES_BIN
    'file is ascii'
else
    'file is bin'
end