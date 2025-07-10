function prtNRCAN(p)
%PRTNRCAN   Pretty print xtrNRCAN results.
%   PRTNRCAN(PPPSTRUCT) pretty prints the PPPSTRUCT structure resulting
%   from a call to XTRNRCAN.
%
%   Examples:
%       pppstruct = xtrNRCAN('d:\Surfdrive\Iceland\DATAPACK\2_GPS\00_DATA\2019\03_PPP\BLAS\*.sum')
%       prtNRCAN(pppstruct)
%
%   See also xtrNRCAN.
%
%   (c) Hans van der Marel, Delft University of Technology, 2024.

%   Created:   23 June 2023 by Hans van der Marel
%   Modified:  31 May 2024 by Hans van der Marel
%               - Modified observation percentatages in warning flag
%               - Added documentation
%   Modified:   3 Jun 2024 by Hans van der Marel
%               - added product field

fprintf('name                     first                 last  receiver type         antenna type           anthgt    %%epo   %%used    %%obs    %%iar  nsat  #rej  prod\n')
fprintf('---------  -------------------  -------------------  --------------------  --------------------  -------  ------  ------  ------  ------  ----  ----  ----\n')

for k=1:numel(p.name)
  pepo=p.nepochs(k,1)/p.nepochs(k,2)*100;
  pobs=p.nobs(k,1)/(p.nobs(k,1)+p.nobs(k,2))*100;
  nsat=p.nobs(k,1)/p.nepochs(k,1);
  if pepo < 60 || pobs < 40
    warn='****';
  elseif pepo < 80 || pobs < 50
    warn='***';
  elseif pepo < 90 || pobs < 75
    warn='**';
  elseif pepo < 97 || pobs < 85
    warn='*';
  else
    warn='';
  end
  if isfield(p,'iar')
      iar=p.iar(k);
  else
      iar=0;
  end
  fprintf('%-9s  %19s  %19s  %-20s  %-20s  %7.4f  %5.1f%%  %5.1f%%  %5.1f%%  %5.1f%%  %4.1f%6d%6s  %s\n', ...
      p.name{k},p.daterange{k,1}(1:end-3),p.daterange{k,2}(1:end-3),p.rectype{k},p.anttype{k},p.antheight(k),p.nepochs(k,2)/p.nepochs(k,3)*100,pepo,pobs,iar,nsat,p.nobs(k,3),p.prod{k},warn);
end

end