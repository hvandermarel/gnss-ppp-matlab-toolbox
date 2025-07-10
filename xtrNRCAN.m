function [pppstruct,pppdata]=xtrNRCAN(filespec,varargin)
%xtrNRCAN    Read NRCAN summary files and extract PPP data.
%   PPPSTRUCT=xtrNRCAN(FILESPEC) reads NRCAN summary files specified by
%   FILESPEC and extracts the PPP results into the PPPSTRUCT structure. 
%
%   [PPPSTRUCT,PPPDATA]=xtrNRCAN(FILESPEC) also returns the original
%   print output of the underlying Perl script in PPPDATA. The NRCAN
%   summary files are actually read by a Perl script and the results
%   are printed on the command line, PPPDATA is the output of the Perl 
%   script, PPPSTRUCT is a structure that is generated from PPPDATA.
%
%   The files specified by FILESPEC can either be NRCAN summary files
%   or zip-files (with summary files); in case a zip file(s) is specified
%   the contents are extracted to a temporary directory before reading.
%   The temporary directory is deleted after files have been read.
%
%   Examples:
%       pppstruct = xtrNRCAN('NRCAN/*.sum');
%       pppstruct = xtrNRCAN(fullfile('03_PROCESSED','NRCAN','*.sum');
%       pppstruct = xtrNRCAN('d:\Iceland\DATAPACK\2_GPS\00_DATA\2019\03_PPP\BLAS\*.zip')
%       prtNRCAN(pppstruct)
%
%   See also prtNRCAN and pppcombine 
%
%   (c) Hans van der Marel, Delft University of Technology, 2018-2020.

%   Created:   23 June 2018 by Hans van der Marel
%   Modified:  11 April 2020 by Hans van der Marel
%               - converted original script into function
%               6 Jul 2020 by Hans van der Marel
%               - added IAR, antenna and receiver type fields
%               3 Jun 2024 by Hans van der Marel
%               - moved code to unzip files from demos to this function
%               - added product field              

% The actual work is done by the xtrNRCAN.pl Perl script, using the Perl
% interpreter that comes with Matlab. The xtrNRCAN.pl Perl script must
% be in the same directory as the xtrNRCAN.m file.

% Check input arguments

if nargin < 1, error('Function expects one input argument.'); end
if ~ischar(filespec) && ~isstring(filespec), error('File specifier function agrument must be a character string.'); end

% Process the options

opt.legacy=false;
for k=1:2:length(varargin)
   if any(strcmp(fieldnames(opt),varargin{k}))
     opt.(varargin{k})=varargin{k+1}; 
   else
     warning(['Invalid option/element ' varargin{k} ])
   end
end

% Get the path to the Perl script that does all the work

mfilename;
thisfile=which(mfilename);
[thisdir,thisname]=fileparts(thisfile);
perlscript=fullfile(thisdir,[thisname '.pl']);

% Check the file specifier and if necessary unzip to temporary directory

iszip=false;
if strcmpi(filespec(end-3:end),'.zip')
   iszip=true;
   zipfiles = dir(filespec);
   tmpdir = tempname();
   try
      mkdir(tmpdir)
      for k=1:numel(zipfiles)
         unzip(fullfile(zipfiles(k).folder,zipfiles(k).name),tmpdir)
      end
      filespec=fullfile(tmpdir,'*.sum');
   catch
      % Remove tmpdir
      rmdir(tmpdir,'s')
   end
end

% Run the Perl script on the file specifier. 

if opt.legacy 
   [pppdata,status]=perl(perlscript,'-l',filespec);
else
   [pppdata,status]=perl(perlscript,filespec);
end
% Remove tmpdir (only in case of zipfiles)
if iszip      
   rmdir(tmpdir,'s')
end
if status ~= 0
  status
  pppdata
  error([ 'Error ' mfilename ', aborting'])
end

% Parse the print output of the Perl script and store the results in a structure

try
    
  c=textscan(pppdata,'%s %s %s %s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %s %s %f %f %s %s %s %s %f %f %f %f %f %f %f %s','Delimiter',',','HeaderLines',1,'collectoutput',true);

  pppstruct.name=c{1}(:,1);
  pppstruct.obsfile=c{1}(:,2);
  pppstruct.latlon=c{1}(:,3:4);
  pppstruct.height=c{2}(:,1);
  pppstruct.scorNEU=[ c{2}(:,2:4)./2 c{2}(:,5:7)];
  pppstruct.XYZ=c{2}(:,8:10);
  pppstruct.scorXYZ=[c{2}(:,11:13)./2 c{2}(:,14:16)];
  pppstruct.daterange=c{3};
  pppstruct.interval=c{4}(:,1);
  pppstruct.antheight=c{4}(:,2);
  pppstruct.anttype=c{5}(:,1);
  pppstruct.rectype=c{5}(:,2);
  pppstruct.syst=c{5}(:,3);
  pppstruct.prod=c{5}(:,4);
  pppstruct.iar=c{6}(:,1);
  pppstruct.nepochs=c{6}(:,2:4);
  pppstruct.nobs=c{6}(:,5:7);
  pppstruct.version=c{7}(:,1);

catch
    
  warning('Error parsing PPPDATA, return empty structure.');
  pppstruct=[];    

end

end