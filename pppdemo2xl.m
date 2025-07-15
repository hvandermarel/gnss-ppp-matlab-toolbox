%% PPPDEMO2XL example script
%
% Demo script to read a whole year of data from NRCAN summary files and 
% combine for every statuion the single day solutions into a single 
% multi-day solution with statistical testing.
%
% Created:   12 April 2020 by Hans van der Marel
% Modified:  14 April 2020 by Hans van der Marel
%             - minor changes
%             - path to 2018 files (in legacy format)
%            26 June 2020 by Hans van der Marel
%             - renamed to pppdemo2xl
%             - merged individual plots into single large plot (hence the XL)
%            28 June 2020 by Hans van der Marel
%             - added code to make subsets (uncomment to make effective)
%             - added code to deal with years with multiple campaigns
%               and having multiple multi-day solutions
%             - added criterion to remove files based on single day OMT
%             - formatting improvements to the ouput
%             8 July 2025 by Hans van der Marel
%             - removed dependency on obsfile name for determining doy in
%               OMT plots (to make the sw robust against non-standard obsfilenames)
%            15 July 2025 by Hans van der Marel
%             - cleanup of code for setting campaign directory
%             - fixed bug in doy computation for removed obsfiles

%% Add toolbox directories to the path

addpath('D:\Surfdrive\Matlab\toolbox\crsutil');
addpath('D:\Surfdrive\Matlab\toolbox\nrcan');

%% Get the directory names with NRCAN summary files
%
% For each year, the solutions for every station is stored in a unique 
% subdirectory for each station.

campaign='2019';

fprintf('Get directory names with NRCAN summary files\n\n');

% Modify/select code to set the campaign directory
% dirroot=fullfile('d:\Iceland\NRCAN\',campaign); filepattern='*.sum';
dirroot=fullfile('d:\Iceland\DATAPACK\2_GPS\00_DATA',campaign,'03_PPP');
filepattern='*.zip';
legacyformat=false;
% End of select

dirnames=dir(dirroot);
dirnames=dirnames([dirnames.isdir]); 
dirnames=dirnames(~cellfun(@(x) strncmp(x,{'.'},1), {dirnames.name}));

% select subset (uncomment next section)
%
% selectstations={ ...
%     'AUSB' 'BF13' 'FM15' 'HRHA' 'KB11' 'KMDC' 'KROV' 'L595' 'L597' 'L598' ...
%     'L599' 'L603' 'L604' 'L671' 'L684' 'L685' 'LV20' 'MYVN' ...
%     'NAMA' 'RAHO' 'RAND' 'THHY' 'TR32' 'TR34'  'VITI' };
% %'L697' 'L699' 'NOME' 'SAMD' 'VIDA'
% dirnames( ~ismember({dirnames.name},selectstations) )=[];

%% Combine single-day solutions into a multi-day solution for each station 
%
% We loop over each directory and combine for each station the single day
% solutions into a multi-day solution. A new multi-day solution is started
% when there is a large gap. In each year we may have multiple multi-day
% solutions

mingap_to_start_new_multiday_solution=3;

% If the OMT exceeds a certain threshold, we try once more without the day 
% with the largest omtfile value. The execution is done within a try-catch 
% construction in order to catch various other errors.
%
% You may tweek these settings to improve the results. In general it
% is a good idea to start a run with large values, e.g.

maxomt_for_reprocessing_multi_day=2;
maxomt_for_reprocessing_single_day=10;

% to see where outright mistakes are, and then refine 

% maxomt_for_reprocessing_multi_day=2;
% maxomt_for_reprocessing_single_day=3;

% It is always a good idea to check if the problem can be resolved 
% in the rinex file, and if possible, resubmit the file for processing.
%
% When the combination is succesfull it is saved in a structure array
% pppsave. A combination is not saved if the OMT is larger than a
% certain threshold or if there was an error (try/catch) from the 
% combination function.

maxomt_for_save=10;

% Setting maxomt_for_save to a large value is a good idea, you can always
% filter later.

% Now we can start the actual combination...

clear pppsave;
clear pppremoved pppskipped;
pppremoved=[];
pppskipped=[];

doylist=[];

kk=0;
for k=1:numel(dirnames)

   fprintf('Processing %s ...\n\n',dirnames(k).name);
   
   % Read the NRCAN summary files
   
   filespec=fullfile(dirroot,dirnames(k).name,filepattern);
   pppstruct = xtrNRCAN(filespec,'legacy',legacyformat);
     
   % Check if the station names in pppstruct match the directory name

   name=unique(pppstruct.name);
   if numel(name) ~=1 || ~strcmpi(dirnames(k).name,char(name)) 
      for l=1:numel(pppstruct.name)
         fprintf('Changed station name in %s from %s to %s\n',pppstruct.obsfile{l},pppstruct.name{l},dirnames(k).name);
         pppstruct.name{l}=dirnames(k).name;
      end
      fprintf('\n')
   end

   % Determine number of multi-day solutions (when there is a significant
   % gap start new multi-day soluttion)
     
   mdaterangeobs=cellfun(@(x) datenum(x),pppstruct.daterange);
   mdateobs=floor(mean(mdaterangeobs,2));
   mdatevec=datevec(mdateobs);
   doy=mdateobs-datenum(mdatevec(:,1),0,0);
   
   segmentIdx=[ 0 ; find(diff(doy) > mingap_to_start_new_multiday_solution) ; numel(doy) ];
   doylist=[doylist;doy]; 
   
   % Combine the single day solutions into one (or more) multi-day solution with statistical testing

   for ks=1:numel(segmentIdx)-1
     
     try

        segment=segmentIdx(ks)+1:segmentIdx(ks+1);
        pppcomb=pppcombine(pppstruct,segment);

        fprintf('Processing %s done (OMT value %.3f)\n',dirnames(k).name,pppcomb.omt)
        fprintf('Observation file       OMT\n')
        for l=1:numel(pppcomb.obsfile)
           fprintf('%20s %8.3f\n',pppcomb.obsfile{l},pppcomb.omtfile(l))
        end
        fprintf('\n\n')
   
        % If OMT > max_OMT, try again, removing the worst day (but only with at least 3 days)
   
        select=1:numel(pppcomb.omtfile);
        clear pppremoved_new;
        pppremoved_new=[];
        while ( pppcomb.omt > maxomt_for_reprocessing_multi_day || max(pppcomb.omtfile) > maxomt_for_reprocessing_single_day ) && numel(pppcomb.omtfile) > 2
 
          [~,i]=max(pppcomb.omtfile);
          doyremoved=doy(segment(select(i)));
          fprintf('*** Removing solution file %s from combination (doy=%d) ***\n\n',pppcomb.obsfile{i},doyremoved)
          select(i)=[];

          %pppremoved_new=[ pppremoved_new ; pppcomb.name pppcomb.obsfile(i) {pppcomb.omtfile(i)}  kk+1 ];
          pppremoved_new=[ pppremoved_new ; pppcomb.name pppcomb.obsfile(i) {pppcomb.omtfile(i)}  kk+1 doyremoved];
       
          pppcomb=pppcombine(pppstruct,segment(select));

          fprintf('Re-processing %s done (OMT value %.3f)\n',dirnames(k).name,pppcomb.omt)
          fprintf('Observation file       OMT\n')
          for l=1:numel(pppcomb.obsfile)
            fprintf('%17s %8.3f\n',pppcomb.obsfile{l},pppcomb.omtfile(l))
          end
          fprintf('\n\n')

        end

        % add array with doy to pppcomb just before saving
        pppcomb.doys=doy(segment(select));

        if pppcomb.omt < maxomt_for_save
          kk=kk+1;
          pppsave(kk)=pppcomb;  
          if ~isempty(pppremoved_new)
             pppremoved=[ pppremoved ; pppremoved_new ];       
          end
        else
          pppskipped=[ pppskipped ; pppcomb.name {pppcomb.obsfile} {pppcomb.omt} {'Max OMT exceeded'} ];       
        end

     catch ME
     
       ME
       warning(['There was an error processing ' dirnames(k).name ])
       pppskipped=[ pppskipped ; dirnames(k).name {pppstruct.obsfile(segment)} { nan } { ME.message } ];       

     end

   end
     
end

%% Summarize the removed data files

nremoved=size(pppremoved,1);
if nremoved > 0
  fprintf('\n\nFiles removed from the combination (%d):\n\n',nremoved)
  fprintf('Name  Obsfile             OMT\n')
  for k=1:nremoved
     fprintf('%s  %s  %10.4g\n',pppremoved{k,1},pppremoved{k,2},pppremoved{k,3})
  end
  fprintf('\n\n')
else
  fprintf('\n\nNo files are removed from the combination (because of outliers)\n\n')
end
 
% Summarize the skipped stations

nskipped=size(pppskipped,1);
if nskipped > 0
  fprintf('Stations which were skipped because of errors (%d):\n\n',nskipped)
  fprintf('Name  #Obsfiles    OMT   Obsfiles       Reason\n')
  for k=1:nskipped
     fprintf('%s %5d  %10.4g  ',pppskipped{k,1},numel(pppskipped{k,2}),pppskipped{k,3});
     for i=1:numel(pppskipped{k,2})
       fprintf(' %s',pppskipped{k,2}{i})
     end
     fprintf('   %s\n',pppskipped{k,4})
  end
  fprintf('\n\n')
else
  fprintf('No stations are skipped (because of errors)\n\n')
end

%% Print station list and results

%fprintf('site,latitude(deg),longitude(deg)\n')
%for k=1:numel(pppsave)
%   fprintf('%4s,%.10f,%.10f\n',pppsave(k).name,pppsave(k).plh(1:2)*180/pi)
%end


fprintf('Combined solution:\n\n')
fprintf('site,dyear,latitude_deg,longitude_deg,height_m,sN_mm,sE_mm,sU_mm,wrmsN_mm,wrmsE_mm,wrmsU_mm,omt,omt2d,omt1d,antheight_m\n')
for k=1:numel(pppsave)
   fprintf('%4s,%8.3f,%14.10f,%14.10f,%9.4f, %4.1f,%4.1f,%4.1f, %4.1f,%4.1f,%4.1f, %4.1f,%4.1f,%4.1f,%7.4f\n',...
       pppsave(k).name,date2dyear(pppsave(k).datenum), ...
       pppsave(k).plh(1:2)*180/pi,pppsave(k).plh(3),...
       pppsave(k).scorNEU(1:3)*1000,pppsave(k).wrmsNEU*1000, ...
       pppsave(k).omt,pppsave(k).omt2d,pppsave(k).omtNEU(3),pppsave(k).antheight)
end

fid=fopen(['PPP_Combination_' campaign '.csv'],'w');
fprintf(fid,'site,dyear,latitude,longitude,height,sN,sE,sU,cNE,cNU,cEU,wrmsN,wrmsE,wrmsU,omt,omt2d,omt1d,antheight\n');
for k=1:numel(pppsave)
   scofNEU=covreformat2(pppsave(k).scorNEU,'scor','scof');
   fprintf(fid,'%4s,%8.3f,%14.10f,%14.10f,%9.4f, %4.1f,%4.1f,%4.1f, %5.2f,%5.2f,%5.2f, %4.1f,%4.1f,%4.1f, %4.1f,%4.1f,%4.1f,%7.4f\n',...
       pppsave(k).name,date2dyear(pppsave(k).datenum), ...
       pppsave(k).plh(1:2)*180/pi,pppsave(k).plh(3),...
       pppsave(k).scorNEU(1:3)*1000,scofNEU(4:6),pppsave(k).wrmsNEU*1000, ...
       pppsave(k).omt,pppsave(k).omt2d,pppsave(k).omtNEU(3),pppsave(k).antheight);
end
fclose(fid);

%% Prepare data for the OMT value plots

% station names (goes on y-axis)

stations={pppsave.name};
numstations=numel(stations);

% day of year (goes on x-axis)

doylist=unique(doylist);
doyind=nan(366,1);

lastdoy=366;
col=0;
for i=1:numel(doylist)
    doy=doylist(i);
    col=col+1;
    % insert some space when there is a gap
    if doy-lastdoy > mingap_to_start_new_multiday_solution
       col=col+mingap_to_start_new_multiday_solution;
    end
    doyind(doy)=col;
    lastdoy=doy;
end
doyidx=zeros(size(doylist));
for i=1:numel(doyind)
   if ~isnan(doyind(i)), doyidx(doyind(i))=i; end
end

    
% make omtarray with the data to plot

omtarray=[];
for k=1:numstations
   %daynum=cellfun(@(x) str2num(x(5:7)),pppsave(k).obsfile);
   daynum=pppsave(k).doys;
   %omtarray=[ omtarray ; repmat(k,size(daynum)) daynum pppsave(k).omtfile pppsave(k).omtfile2d pppsave(k).omtfile1d ];
   omtarray=[ omtarray ; repmat(k,size(daynum)) doyind(daynum) pppsave(k).omtfile pppsave(k).omtfile2d pppsave(k).omtfile1d ];
end

% make remarray with the location to plot crosses for removed files

remarray=[];
nremoved=size(pppremoved,1);
for k=1:nremoved
   %daynum=str2num(pppremoved{k,2}(5:7));
   daynum=pppremoved{k,5};
   %kk=find(ismember(stations,pppremoved{k,1}));
   kk=pppremoved{k,4};
   %if ~isempty(kk)
     %remarray=[ remarray ; kk daynum ];
     remarray=[ remarray ; kk doyind(daynum) ];
   %end
end


%% Plot the OMT values

%figure('Name','Overall Model Test','NumberTitle','off','Position',[ 40 60 600 900])
hf=figure('Name',['Station Quality ' campaign ],'NumberTitle','off','Position',[ 40 60 600*3 900]);

%subplot('Position',[ 0.1 0.1 0.6 .82])
subplot('Position',[ 0.1/3 0.1 0.6/3 .82])

symsize=omtarray(:,3)*25;
symsize(symsize < 5)=5;
scatter(omtarray(:,2),omtarray(:,1),symsize,omtarray(:,3),'s','filled');
if ~isempty(remarray)
hold on
scatter(remarray(:,2),remarray(:,1),35,[1 0 0],'x');
end
hp=gca;
colorbar
colormap(jet)

hp.YTick=1:numstations;
hp.YTickLabel=stations;
hp.YDir='reverse';
ylim([0 numstations+1])

hp.XTick=unique(omtarray(:,2));
%hp.XTickLabel=hp.XTick;
hp.XTickLabel=doyidx(hp.XTick);
hp.XTickLabelRotation=90;
xlim([ min(hp.XTick-1) max(hp.XTick+1)]);

hp.Box='on';
hp.FontSize=9;

year=char(unique(cellfun(@(x) x(1:4),[ pppsave.daterange ],'UniformOutput',false)));
%xlabel(year);

title([ 'Single day OMT (' year ')'])

%subplot('Position',[ 0.78 0.1 0.17 .82])
subplot('Position',[ 0.78/3 0.1 0.17/3 .82])

omt=[pppsave.omt];
barh(omt)
hb=gca;
hb.YTick=1:numstations;
hb.YTickLabel=stations;
hb.YDir='reverse';
ylim([0 numstations+1])

hb.FontSize=9;

title('Multi day OMT')

% Plot 2D- adn 1D-OMT values


%figure('Name','2D/1D Overall Model Test','NumberTitle','off','Position',[ 40 60 600 900])

%subplot('Position',[ 0.1 0.1 0.6 .82])
subplot('Position',[ 1/3+0.1/3 0.1 0.6/3 .82])

symsize=omtarray(:,4)*25;
symsize(symsize < 5)=5;
scatter(omtarray(:,2),omtarray(:,1),symsize,omtarray(:,4),'o','filled');
hold on
symsize=omtarray(:,5)*25;
symsize(symsize < 5)=5;
scatter(omtarray(:,2),omtarray(:,1),symsize,omtarray(:,5),'^');
if ~isempty(remarray)
   scatter(remarray(:,2),remarray(:,1),35,[1 0 0],'x');
end
hp=gca;
colorbar
colormap(jet)

hp.YTick=1:numstations;
hp.YTickLabel=stations;
hp.YDir='reverse';
ylim([0 numstations+1])

hp.XTick=unique(omtarray(:,2));
%hp.XTickLabel=hp.XTick;
hp.XTickLabel=doyidx(hp.XTick);
hp.XTickLabelRotation=90;
xlim([ min(hp.XTick-1) max(hp.XTick+1)]);

hp.Box='on';
hp.FontSize=9;

year=char(unique(cellfun(@(x) x(1:4),[ pppsave.daterange ],'UniformOutput',false)));
%xlabel(year);

title([ 'Single day 2D/1D OMT (' year ')'])

%subplot('Position',[ 0.78 0.1 0.17 .82])
subplot('Position',[ 1/3+0.78/3 0.1 0.17/3 .82])

omt=[[pppsave.omt2d]' [pppsave.omt1d]'];
barh(omt)
hb=gca;
hb.YTick=1:numstations;
hb.YTickLabel=stations;
hb.YDir='reverse';
ylim([0 numstations+1])

hb.FontSize=9;

title('Multi day 2D/1D OMT')


% Plot with the station quality

%figure('Name','Station Quality','NumberTitle','off','Position',[ 40 60 600 900])

%subplot('Position',[ 0.1 0.1 0.22 .82])
subplot('Position',[ 2/3+0.1/3 0.1 0.22/3 .82])

sigma=cell2mat({ pppsave.scorNEU }')*1000;
sigma=sigma(:,1:3);

barh(sigma)
ha=gca;
ha.YTick=1:numstations;
ha.YTickLabel=stations;
ha.YDir='reverse';
ylim([0 numstations+1])
xrange=xlim;
xrange(2)=min(ceil(xrange(2)*1.1),10);
xlim(xrange);

ha.FontSize=9;

xlabel('\sigma_{NEU} [mm]')
legend({'N','E','U'})

title(['\sigma_{NEU} (' year ')'])

%subplot('Position',[ 0.4 0.1 0.22 .82])
subplot('Position',[ 2/3+0.4/3 0.1 0.22/3 .82])


wrms=cell2mat({ pppsave.wrmsNEU }')*1000;
barh(wrms)
hb=gca;
hb.YTick=1:numstations;
hb.YTickLabel=stations;
hb.YDir='reverse';
ylim([0 numstations+1])
xrange=xlim;
xrange(2)=min(ceil(xrange(2)*1.1),15);

hb.FontSize=9;

xlabel('w-rmse [mm]')
legend({'N','E','U'})

title(['W-RMSE (' year ')'])

%subplot('Position',[ 0.7 0.1 0.22 .82])
subplot('Position',[ 2/3+0.7/3 0.1 0.22/3 .82])

omtneu=cell2mat({ pppsave.omtNEU }');
barh(omtneu)
hc=gca;
hc.YTick=1:numstations;
hc.YTickLabel=stations;
hc.YDir='reverse';
ylim([0 numstations+1]);

hc.FontSize=9;

xlabel('OMT [-]')
legend({'N','E','U'})

title(['OMT (' year ')'])

%% Save the graphics to pdf and png

saveas(hf,['PPP_Station_Quality_' campaign '.png']);
exportgraphics(hf,['PPP_Station_Quality_' campaign '.pdf'],'ContentType','vector');


