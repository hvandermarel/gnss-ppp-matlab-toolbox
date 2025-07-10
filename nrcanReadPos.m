function pos=nrcanReadPos(posfile)
%nrcanReadPos  Read NRCAN position file.
%  POS=nrcanReadPos(POSFILE) reads the NRCAN position file POSFILE and
%  returns the results in the structure POS.
%
%  (c) Hans van der Marel, TU Delft, 2019

% Created:  28 Apr 2019 by Hans van der Marel
% Modified:

if nargin < 1, error('Name of NRCAN position file missing'); end

% Example and format of NRCAN position file:
%
% HDR GRP CANADIAN GEODETIC SURVEY, SURVEYOR GENERAL BRANCH, NATURAL RESOURCES CANADA
% HDR ADR GOVERNMENT OF CANADA, 588 BOOTH STREET ROOM 334, OTTAWA ONTARIO K1A 0Y7
% HDR TEL 343-292-6617
% HDR EMA nrcan.geodeticinformationservices.rncan@canada.ca
% NOTE: Estimated positions are at the epoch of data
% DIR FRAME  STN   DAYofYEAR YEAR-MM-DD HR:MN:SS.SS NSV GDOP RMSC(m) RMSP(m)       DLAT(m)       DLON(m)       DHGT(m)          CLK(ns)  TZD(m) SDLAT(95%) SDLON(95%) SDHGT(95%) SDCLK(95%) SDTZD(95%) LATDD LATMN    LATSS LONDD LONMN    LONSS     HGT(m) UTMZONE    UTM_EASTING   UTM_NORTHING UTM_SCLPNT UTM_SCLCBN
% BWD IGS14 0133   97.482928 2019-04-07 11:35:25.00   9  5.1   1.003  0.0034        0.1784       -0.1479        0.3671     -384465.7034  2.4608     0.0711     0.1436     0.1655     0.6083     0.0044    39    18  5.34117    -9    20 43.49667    94.8547      29    470217.1545   4350290.2802   0.999611   0.999596
% BWD IGS14 0133   97.482940 2019-04-07 11:35:26.00  10  2.1   0.798  0.0021        0.3005       -0.3312        0.7624     -384522.6374  2.4568     0.0374     0.0377     0.0671     0.2144     0.0044    39    18  5.34513    -9    20 43.50432    95.2500      29    470216.9717   4350290.4030   0.999611   0.999596
% BWD IGS14 0133   97.482951 2019-04-07 11:35:27.00  12  1.5   0.656  0.0012        0.3625       -0.3257        0.9736     -384579.6865  2.4568     0.0312     0.0308     0.0584     0.1894     0.0044    39    18  5.34714    -9    20 43.50409    95.4612      29    470216.9775   4350290.4649   0.999611   0.999596
% BWD IGS14 0133   97.482963 2019-04-07 11:35:28.00  13  1.5   0.584  0.0015        0.3369       -0.3485        0.9422     -384636.7891  2.4568     0.0309     0.0296     0.0569     0.1851     0.0044    39    18  5.34631    -9    20 43.50504    95.4298      29    470216.9546   4350290.4394   0.999611   0.999596 
% ...
%
% DIR            Processing Direction: 
%                    FWD : Forward 
%                    BWD : Backward smoothed 
%                    SCA : final estimated position with scaled sigmas (Only for Static mode)
% FRAME          Reference Frame
% STN            Station name 
% DAYofYEAR      DAY of YEAR
% YEAR-MM-DD     Observation Date
% HR:MN:SS.SS    Observation Time
% NSV            Number of satellite
% GDOP           Geometric Dilution of Precision
% RMSC(m)        stds/RMS of Carrier Phase residuals 
% RMSP(m)        stds/RMS of Pseudo-Range residuals 
% DLAT(m)        Difference between estimated and a priori positions- North dir.
% DLON(m)        Difference between estimated and a priori positions- East dir.
% DHGT(m)        Difference between estimated and a priori positions- Up dir.
% CLK(ns)        Clock offset
% TZD(m)         Estimated Total Zenith Delay for each epoch
% SDLAT(95%)     Standard deviation(95%) of estimated  positions - North dir.
% SDLON(95%)     Standard deviation(95%) of estimated  positions - East dir.
% SDHGT(95%)     Standard deviation(95%) of estimated  positions - UP dir.
% SDCLK(95%)     Standard deviation(95%) of clock offset
% SDTZD(95%)     Formal uncertainty (sigma 95%) of the estimated Total Zenith Delay 
% LATDD          Estimated Position - Latitude Degrees
% LATMN          Estimated Position - Latitude Minutes
% LATSS          Estimated Position - Latitude Seconds
% LONDD          Estimated Position - Longitude Degrees
% LONMN          Estimated Position - Longitude Minutes
% LONSS          Estimated Position - Longitude Seconds
% HGT(m)         Estimated Position - Ellipsoidal Height
% UTMZONE*       Estimated Position - UTM Zone
% UTM_EASTING*   Estimated Position - UTM Easting
% UTM_NORTHING*  Estimated Position - UTM Northing
% UTM_SCLPNT*    Estimated Position - UTM Scale
% UTM_SCLCBN*    Estimated Position - UTM Combined Scale
% MTMZONE**      Estimated Position - MTM Zone
% MTM_EASTING**  Estimated Position - MTM Easting 
% MTM_NORTHING** Estimated Position - MTM Northing
% MTM_SCLPNT**   Estimated Position - MTM Scale
% MTM_SCLCBN**   Estimated Position - MTM Combined Scale
% ORTHGT(m)***   Estimated orthometric Height 
% 
% (*) Only for Kinematic mode
% (**) Only for Kinematic if user selects NAD83(CSRS) as the reference frame and all positions is in Canada
% (***) Only for Kinematic if all positions within the Geoid model

fid=fopen(posfile);
while ~feof(fid)
  posline=fgetl(fid);
  %fprintf('%s\n',posline);
  switch posline(1:3)
      case {'HDR','NOT'}
         continue;
      case 'DIR'
         break;
  end
end
c=textscan(fid,'%s %s %s %f %s %s %d %f %f %f %f %f %f %f %f %f %f %f %f %f %d %d %f %d %d %f %f %*[^\n]');
fclose(fid);

pos.stn=unique(c{3});
pos.frame=unique(c{2});
pos.dir=unique(c{1});
pos.epoch=datenum(c{5})+rem(datenum(c{6}),1);
pos.nsv=c{7};
pos.gdop=c{8};
pos.rmsc=c{9};
pos.rmsp=c{10};
pos.dneu=[c{11} c{12} c{13} ];
pos.clk=c{14};
pos.tzd=c{15};
pos.sdneu=[c{16} c{17} c{18} ];
pos.sdclk=c{19};
pos.sdztd=c{20};
pos.llh=[ double(c{21})+double(c{22})./60+c{23}./3600 double(c{24})+double(c{25})./60+c{26}./3600  c{27} ];


end
