%% PPPDEMO1 example script
%
% Demo script to read data from NRCAN summary files and combine the single
% day solutions into a single multi-day solution with statistical testing.
%
% This is the example that is also given in the help of the pppcombine
% function.
%
% Created:   12 April 2020 by Hans van der Marel
% Modified:  31 May 2024 by Hans van der Marel
%             - added print functions to the demo
%             - added zip file example to the demo

%% Add NRCAN and CRSUTIL toolbox to path

addpath('D:\Surfdrive\Matlab\toolbox\nrcan');
addpath('D:\Surfdrive\Matlab\toolbox\crsutil');

%% Specify sum or zip files with NRCAN results

filespec = 'd:\Iceland\DATAPACK\2_GPS\00_DATA\2019\03_PPP\BLAS\*.zip';
%filespec = 'd:\Iceland\DATAPACK_OTHER\2_GPS\00_DATA\2019\03_PPP\BLAS\*.sum';

%% Read NRCAN solution files and extract the relevant information

fprintf('\nRead NRCAN solution files and save the results in pppstruct\n\n');

pppstruct = xtrNRCAN(filespec);
prtNRCAN(pppstruct)

%% Combine the single day solutions into one multi-day solution with statistical testing

fprintf('\nCombine the single day solutions into one multiday solution\n\n');

pppcomb=pppcombine(pppstruct);
prtcombine(pppcomb)

%% Repeat the combination, but without the last day (which has a high OMT value)

fprintf('Repeat the combination without the last day\n\n');

pppcomb=pppcombine(pppstruct,[ 1 2 3  ]);
prtcombine(pppcomb)
