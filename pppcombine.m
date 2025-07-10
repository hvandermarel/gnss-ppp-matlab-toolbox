function pppcomb=pppcombine(pppstruct,select)
%PPPCOMBINE   Combine single(-day) PPP solutions into a single multi-day estimate.
%   PPPCOMB=PPPCOMBINE(PPPSTRUCT) combines the single(-day) PPP solutions 
%   given by PPPSTRUCT into a single multi-day solution. The input PPPSTRUCT 
%   structure is output from e.g. xtrNRCAN. The combined solution is given
%   in a new output structure PPPCOMB, which contains the Cartesian
%   and geodetic coordinates of the combined solution each with a covariance
%   matrix, as well as residuals, w-test values and OMT (Overall Model Test)
%   values in the Cartesian geocentric system and local NEU system, plus
%   the overall OMT.
%
%   The input solutions in PPPSTRUCT must belong to the same station and
%   have the same antenna height. When this is not the case the function
%   throws an error.
%
%   PPPCOMB=PPPCOMBINE(PPPSTRUCT,SELECT) allows to select solutions
%   from PPPSTRUCT by specifying an index array SELECT.
%
%   Examples:
%       pppstruct = xtrNRCAN('d:\Surfdrive\Iceland\DATAPACK\2_GPS\00_DATA\2019\03_PPP\BLAS\*.sum')
%       pppcomb=pppcombine(pppstruct)
%
%   See also xtrNRCAN.
%
%   (c) Hans van der Marel, Delft University of Technology, 2020.

%   Created:   11 April 2020 by Hans van der Marel
%   Modified:  13 April 2020 by Hans van der Marel
%               - Added wrms (weighted rms) to the output structure
%               - Compute redundancy numbers, output, but not used for
%                 omtfile (omtfile2 used redundancy numbers) 
%              14 April 2020 by Hans van der Marel
%               - Added 2D and 1D test results for the horizontal and
%                 vertical components
%               - Use redundancy numbers in omtfile computation
%               - Improved documentation and comments
%              31 May 2024 by Hans van der Marel
%               - Perform check that all inputs are in the same system
%               - Added syst (system) field to output
%               - Relaxed check on station name, if necessary substitute
%                 with first four characters from filename

%% Check the input arguments

if nargin < 1, error('Function expects one input argument.'); end
if ~isstruct(pppstruct), error('First argument must be a structure.'); end  

if nargin < 2
   select=1:numel(pppstruct.name);     % Default for select is to use every element
end

verbose=0;                             % Verbose=1 produces extra output for debugging

%% Check the input data and store the meta data into the output structure

% Check if the stations are the same 

name=unique(pppstruct.name(select));
if numel(name) ~=1 
   % name is not unique, retry using first four characters from filename
   fprintf('Message PPPCOMBINE: Station names in name field do not match, get name from first 4 charaters of filename instead.\n')
   name=unique(cellfun(@(x) x(1:4),pppstruct.obsfile(select),'UniformOutput',false));
   if numel(name) ~=1 
      error('Selected datasets do not belong to the same station')
   end
end

% Save meta data to output structure

pppcomb.name=char(name);
pppcomb.obsfile=pppstruct.obsfile(select);
%pppcomb.daterange=[ pppstruct.daterange(select(1),1) pppstruct.daterange(select(end),2)];
mdaterangeobs=cellfun(@(x) datenum(x),pppstruct.daterange(select,:));
mdaterange=[ min(mdaterangeobs(:,1)) max(mdaterangeobs(:,2)) ];
pppcomb.daterange= { datestr(mdaterange(1),'yyyy-mm-dd HH:MM:SS') datestr(mdaterange(2),'yyyy-mm-dd HH:MM:SS') };
pppcomb.datenum=mean(mdaterange);

% Check if the antenna heights are the same

pppcomb.antheight=unique(pppstruct.antheight(select));
if numel(pppcomb.antheight) ~=1 
   error('Antenna heights must be the same')
end
pppcomb.interval=unique(pppstruct.interval(select));

% Check if all results are in the same system

if isfield(pppstruct,'syst')
   syst=unique(pppstruct.syst(select));
   if numel(syst) ~=1 
      error('Selected datasets are not in the same coordinate system')
   end
   syst=char(syst);
else
   syst='unknown';
end
pppcomb.syst=syst;

% Check the number of input solutions

m=numel(select);
if m < 2
   error('This function needs at least two solutions to do something.')
end

%% Compute combined solution using Cartesian XYZ coordinates
%
% The combined solution is computed from the Cartesian XYZ coordinates
% using the co-variance matrix given by pppstruct. 
% 
% The co-variance matrix of the solutions, least-squares residuals and 
% co-variance matrix of the least-squares residuals are computed, as well
% as the various error statistics,  such as the overall model test (OMT) 
% and w-test values. The OMT is also computed per day and for each
% coordinate.
%
% The results are saved in pppcomb.

% Store observed XYZ coordinates and covariance matrix in local variables

xyzobs=pppstruct.XYZ(select,:);
scorxyzobs=pppstruct.scorXYZ(select,:);
Qxyzobs=covreformat(scorxyzobs,'scor','qmat');

% Compute the combined solution using weight least squares (BLUE)

N=zeros(3,3);
b=zeros(3,1);
for k=1: m
    Qinv=inv(Qxyzobs(:,:,k));
    N=N+Qinv;
    b=b+Qinv*xyzobs(k,:)';
end

Qxyz=inv(N);
xyz=b'*Qxyz;

scorxyz=covreformat2(Qxyz,'qmat','scor');

% Compute the least-squares residuals and covariance matrix of the residuals. 

% Note that only the block diagonal part of the covariance matrix is stored; 
% the off diagonal blocks are not empty. The off diagonal blocks are 
% equal to -Qxyz .

xyzres=xyzobs-repmat(xyz,[m 1]);
Qxyzres=Qxyzobs-repmat(Qxyz,[1 1 m]);

scorxyzres=covreformat2(Qxyzres,'qmat','scor');

% Compute w-test and overall model test values for the XYZ coordinates

% We can use simplified formula's because of the block diagonal structure
% of the co-variance matrix: there is no correlation between the
% coordinates for different solutions.
%
% For fun, we compute the OMT per coordinate also from the w-test values,
% but this does not yield the same result, as here correlations between
% different solutions do exist.

wtestxyz=xyzres./scorxyzres(:,1:3);

omtxyz=sqrt(sum((xyzres.^2)./(scorxyzobs(:,1:3).^2))./(m-1));
omtxyz_=sqrt(sum(wtestxyz.^2)./m);  

% Compute rms error (standard deviation) and weighted rms error

rmsxyz=std(xyzres);

wrmsxyz=sqrt(sum(wtestxyz.^2)./sum((1./scorxyzres(:,1:3).^2)));
%wrmsxyz1=sqrt(sum((xyzres./scorxyzres(:,1:3)).^2)./sum((1./scorxyzres(:,1:3)).^2));
%wrmsxyz2=sqrt(sum((xyzres./scorxyzobs(:,1:3)).^2)./sum((1./scorxyzobs(:,1:3)).^2));

% Compute redundancy numbers

redxyz=(scorxyzres(:,1:3)./scorxyzobs(:,1:3)).^2;

% Compute overall model test value, including a value for each solution

omtfile=zeros(m,1);
for k=1: m
    Qinv=inv(Qxyzobs(:,:,k));
    omtfile(k)=xyzres(k,:)*Qinv*xyzres(k,:)';
end
omt=sum(omtfile)./(3*m-3);
omtfile=omtfile./sum(redxyz,2); 

% Save XYZ results into the output structure 

pppcomb.XYZ=xyz;
pppcomb.scorXYZ=scorxyz;

pppcomb.XYZobs=xyzobs;
pppcomb.XYZres=xyzres;

pppcomb.scorXYZobs=scorxyzobs;
pppcomb.scorXYZres=scorxyzres;

pppcomb.redXYZ=redxyz;
pppcomb.wtestXYZ=wtestxyz;

pppcomb.omtXYZ=omtxyz;
%pppcomb.omtXYZ_=omtxyz_;
pppcomb.rmsXYZ=rmsxyz;
pppcomb.wrmsXYZ=wrmsxyz;

% omt and omtfile are not saved here, but at the very end of the structure...

%% Transformation into a local North, East, Up (NEU) system
%
% A local North, East, Up system is more useful for GNSS quality analysis 
% than the ECEF XYZ system. Therefore, residuals, co-variance matrix of the 
% observations and residuals, w-test and OMT test are also computed in a 
% local North, East, Up (NEU) coordinate system.
%
% However, first we have to transform our solution into the local system.
% Since the input data contains also the observations as latitude,
% longitude and height, with the co-variance matrix, we check if these
% are the same as the results from our transformation. 

% Convert XYZ residuals into NEU residuals 

[neures,R]=xyz2neu(xyzobs,xyz,'xr');

neudiff=(R*xyzres')'-neures;             % Check that the outcomes are the same
neumaxdiff=max(max(abs(neudiff)));
if verbose, neumaxdiff, end
if neumaxdiff > 1e-6
   neumaxdiff
   error('Hey, there is something wrong with the NEU values or rotation matrix R. This should not happen.')
end

% Convert XYZ covariance information into NEU

Qneuobs=Qxyzobs;
Qneures=Qxyzres;
for k=1: m
    Qneuobs(:,:,k)=R*Qxyzobs(:,:,k)*R';
    Qneures(:,:,k)=R*Qxyzres(:,:,k)*R';
end
Qneu=R*Qxyz*R';

scorneu=covreformat2(Qneu,'qmat','scor');
scorneuobs=covreformat2(Qneuobs,'qmat','scor');
scorneures=covreformat2(Qneures,'qmat','scor');

% Convert latitude and longitude from input structure into decimal degrees.

    function d=dms2deg(x)
    % Internal function for conversion of dms to decimal degrees
    y=str2num(x);
    d=sign(y(1))*abs(y)*[1 ; 1/60 ; 1/3600];
    end

latlon=cellfun(@(x) dms2deg(x), pppstruct.latlon(select,:));
plhobs = [ latlon*pi/180 pppstruct.height(select) ];

% Compute latitude, longitude and height from adjusted XYZ coordinates, it
% is important to use the 'GRS80' ellipsoid (not the default 'WGS84').
% Note: legacy NRCAN PPP results use WGS84, but even then there remains
% a systemetic offsett in the latitude coordinates ...

plh=xyz2plh(xyz,'GRS80');

% Compare NEU values computed from the ellipsoidal coordinates with 
% NEU computed from the XYZ coordinates. The results will be slightly 
% different due to round off errors.

neuplh=plh2neu(plhobs,plh);
neumaxdiff=max(abs(neures-neuplh));
if any(neumaxdiff > 0.0002)
  neures
  neures-neuplh
  neumaxdiff
  warning('Hey, the difference in NEU is too big. This warrants a further investigation.')
end
if verbose
  neures
  neures-neuplh
  neumaxdiff
end

% Compare NEU standard deviations and correlation from the input structure 
% with the NEU standard deviutions and correlations from the XYZ
% coordinates.

scorneudiff=scorneuobs-pppstruct.scorNEU(select,:);
if any(abs(scorneudiff(1:3)) > 0.0002) || any(abs(scorneudiff(4:6)) > 0.05)
  scorneuobs
  pppstruct.scorNEU(select,:)
  scorneuobs-pppstruct.scorNEU(select,:)
  warning('Hey, the difference in scorNEU is too big. This warrants a further investigation.')
end
if verbose
  scorneuobs
  pppstruct.scorNEU(select,:)
  scorneuobs-pppstruct.scorNEU(select,:)
end

%% Do testing and quality analysis in the North, East and Up direction
%
% Now we compute the quality information in the local system and
% save the results in the output structure.
%
% What makes the NEU system special is that we can do the testing
% also separately for the vertical and horizontal components. This
% results in a 1D OMT for the vertical and 2D OMT for the horizontal
% components.

% Compute w-test and overall model test values for NEU coordinates

wtestneu=neures./scorneures(:,1:3);

omtneu=sqrt(sum((neures.^2)./(scorneuobs(:,1:3).^2))./(m-1));

% Compute rms error (standard deviation) and weighted rms error

rmsneu=std(neures);

wrmsneu=sqrt(sum(wtestneu.^2)./sum((1./scorneures(:,1:3).^2)));
%wrmsneu1=sqrt(sum((neures./scorneures(:,1:3)).^2)./sum((1./scorneures(:,1:3)).^2));
%wrmsneu2=sqrt(sum((neures./scorneuobs(:,1:3)).^2)./sum((1./scorneuobs(:,1:3)).^2));

% Compute redundancy numbers

redneu=(scorneures(:,1:3)./scorneuobs(:,1:3)).^2;

% Compute overall model test value again, just as a check, to see if it
% gives the same result. At the same time compute OMT for horizontal (2D) 
% and vertical component (1D).

omtfile3d=zeros(m,1);
omtfile2d=zeros(m,1);
omtfile1d=zeros(m,1);
for k=1: m
    Qinv=inv(Qneuobs(:,:,k));
    omtfile3d(k)=neures(k,:)*Qinv*neures(k,:)';
    omtfile2d(k)=neures(k,1:2)*Qinv(1:2,1:2)*neures(k,1:2)';
    omtfile1d(k)=neures(k,3)*Qinv(3,3)*neures(k,3)';
end
omt3d=sum(omtfile3d)./(3*m-3);               % should be the same as the omt computed from xyz residuals
omt2d=sum(omtfile2d)./sum(sum(redneu(:,1:2),2));
omt1d=sum(omtfile1d)./sum(redneu(:,3));

omtfile3d=omtfile3d./sum(redneu,2);          % should be the same as omtfile (computed from xyz residuals)
omtfile2d=omtfile2d./sum(redneu(:,1:2),2); 
omtfile1d=omtfile1d./redneu(:,3);            % should be the same as w-test squared for the up component 

omtdiff=omt-omt3d;
if omt < 50 && abs(omtdiff/(max(omt,.2))) > 0.01  
   omtdiff
   warning('Hey, the OMT difference between XYZ and NEU processing chains is too big. This should not happen.')
end
if verbose
  sum(sum(redneu(:,1:2),2))
  sum(redneu(:,3))
  sum(redneu(:,1:2),2) 
  redneu(:,3)
end

% Save NEU results into the output structure

pppcomb.plh=plh;
pppcomb.scorNEU=scorneu;

pppcomb.NEUres=neures;

pppcomb.scorNEUobs=scorneuobs;
pppcomb.scorNEUres=scorneures;

pppcomb.redNEU=redneu;
pppcomb.wtestNEU=wtestneu;

pppcomb.omtNEU=omtneu;
pppcomb.rmsNEU=rmsneu;
pppcomb.wrmsNEU=wrmsneu;

pppcomb.omtfile3d=omtfile3d;    
pppcomb.omtfile2d=omtfile2d;
pppcomb.omtfile1d=omtfile1d;    % should be the same as wtestneu(:3).^2 
pppcomb.omt3d=omt3d;            
pppcomb.omt2d=omt2d;
pppcomb.omt1d=omt1d;

%% Save OMTs from XYZ processing into the output structure
%
% The omt and omtfile can be used to decide if a further iteration is
% needed for the solution. A good strategy is to first check it the
% omt exceeds a certain threshold (expected value is 1), and if so,
% use the input parameter select to exclude the file with the largest 
% value in omtfile. However, this only works for three or more files.

pppcomb.omtfile=omtfile;        % should be the same as omtfile3d (omtfile is computed from xyz residuals)
pppcomb.omt=omt;                % should be the same as omt3d (omt is computed from xyz residuals)

end
