function prtcombine(p)
%PRTCOMBINE   Pretty print PPPCOMBINE results.
%   PRTCOMBINE(PPPCOMB) pretty prints the PPPCOMB structure resulting
%   from a call to PPPCOMBINE.
%
%   Examples:
%       pppstruct = xtrNRCAN('d:\Surfdrive\Iceland\DATAPACK\2_GPS\00_DATA\2019\03_PPP\BLAS\*.sum')
%       pppcomb=pppcombine(pppstruct)
%       prtcombine(pppcomb)
%
%   See also PPPCOMBINE.
%
%   (c) Hans van der Marel, Delft University of Technology, 2024.

%   Created:   31 May 2024 by Hans van der Marel
%   Modified: 

nfiles=numel(p.obsfile);
 
fprintf('Station name:           %s\n',p.name)
fprintf('Observation period:     %s - %s\n',p.daterange{1},p.daterange{2})
fprintf('Observation interval:   %.1f [s]\n',p.interval)
fprintf('Antenna height:         %.4f [m]\n\n',p.antheight)
fprintf('Coordinates (%s):\n',p.syst)
fprintf('  Mean epoch:           %s   (%.3f)\n',datestr(p.datenum),date2dyear(p.datenum))
fprintf('  Cartesian [m]:        %12.4f  %12.4f  %12.4f\n',p.XYZ)
fprintf('  Geodetic [deg/m]:    %14.10f  %14.10f   %8.4f\n',p.plh(1:2)*180/pi,p.plh(3))
fprintf('  Geodetic [dms/m]:  %s\n\n',plh2str(p.plh))

fprintf('Coordinate uncertainties:\n')
fprintf('                         st.dev. in [mm]             Correlations\n')
fprintf('  method\n')
fprintf('                      North    East      Up        N-E    N-U    E-U\n')
fprintf('                     ------  ------  ------     ------ ------ ------\n')
fprintf('  cov-matrix        %7.2f %7.2f %7.2f    %7.2f%7.2f%7.2f\n', p.scorNEU(1:3)*1000,p.scorNEU(4:end))
fprintf('  emperical (rms)   %7.2f %7.2f %7.2f\n',p.rmsNEU/sqrt(nfiles)*1000)
fprintf('  emperical (wrms)  %7.2f %7.2f %7.2f\n\n',p.wrmsNEU/sqrt(nfiles)*1000)

fprintf('                          X       Y       Z        X-Y    X-Z    Y-Z\n')
fprintf('                     ------  ------  ------     ------ ------ ------\n')
fprintf('  cov-matrix        %7.2f %7.2f %7.2f    %7.2f%7.2f%7.2f\n', p.scorXYZ(1:3)*1000,p.scorXYZ(4:end))
fprintf('  emperical (rms)   %7.2f %7.2f %7.2f\n',p.rmsXYZ/sqrt(nfiles)*1000)
fprintf('  emperical (wrms)  %7.2f %7.2f %7.2f\n\n',p.wrmsXYZ/sqrt(nfiles)*1000)

fprintf('Overall Model Test (omt):  %.3f   (2D: %.3f, 1D: %.3f)\n',p.omt,p.omt2d,p.omt1d)

fprintf('\n')
fprintf('obsfile                                     res-N   res-E   res-U    wtst-N wtst-E wtst-U    omt-2D omt-1D  omt-3D  \n')
fprintf('--------------------------------------    ------- ------- -------    ------ ------ ------    ------ ------  ------  \n')
for k=1:nfiles
   fprintf('%-41s%8.1f%8.1f%8.1f   %7.2f%7.2f%7.2f   %7.3f%7.3f %7.3f \n', ...
      p.obsfile{k},p.NEUres(k,:)*1000,p.wtestNEU(k,:),p.omtfile2d(k),p.omtfile1d(k),p.omtfile(k));
end
fprintf('                                          ------- ------- -------    ------ ------ ------    ------ ------  ------  \n')
fprintf('rms, omt                                 %8.2f%8.2f%8.2f   %7.3f%7.3f%7.3f   %7.3f%7.3f %7.3f \n', ...
     p.rmsNEU*1000,p.omtNEU,p.omt2d,p.omt1d,p.omt);
fprintf('wrms                                     %8.2f%8.2f%8.2f\n\n', p.wrmsNEU*1000)

end
