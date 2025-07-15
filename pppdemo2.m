%% PPPDEMO2 example script
%
% Demo script to read a whole year of data from NRCAN summary files and 
% combine for every statuion the single day solutions into a single 
% multi-day solution with statistical testing.
%
% Created:   12 April 2020 by Hans van der Marel
% Modified:  14 April 2020 by Hans van der Marel
%             - minor changes
%             - path to 2018 files (in legacy format)
%            15 July 2025 by Hans van der Marel
%             - backported some changes from pppdemoxl back to pppdemo2

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


%% Combine single-day solutions into a multi-day solution for each station 
%
% We loop over each directory and combine for each station the single day
% solutions into a multi-day solution. 
%
% If the OMT exceeds a certain threshold, we try once more without the day 
% with the largest omtfile value. The execution is done within a try-catch 
% construction in order to catch various other errors.
% 
% When the combination is succesfull it is saved in a structure array

maxomt_for_reprocessing=2;
maxomt_for_save=10;

clear pppsave;
clear pppremoved pppskipped;
pppremoved=[];
pppskipped=[];

kk=0;
for k=1:numel(dirnames)

   fprintf('Processing %s ...\n\n',dirnames(k).name);
   
   try

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

     % Compute doy numbers 

     mdaterangeobs=cellfun(@(x) datenum(x),pppstruct.daterange);
     mdateobs=floor(mean(mdaterangeobs,2));
     mdatevec=datevec(mdateobs);
     doy=mdateobs-datenum(mdatevec(:,1),0,0);

     % Combine the single day solutions into one multi-day solution with statistical testing

     pppcomb=pppcombine(pppstruct);

     fprintf('Processing %s done (OMT value %.3f)\n',dirnames(k).name,pppcomb.omt)
     fprintf('Observation file       OMT\n')
     for l=1:numel(pppcomb.obsfile)
       fprintf('%20s %8.3f\n',pppcomb.obsfile{l},pppcomb.omtfile(l))
     end
     fprintf('\n\n')
   
     % If OMT > max_OMT, try again, removing the worst day (but only with at least 3 days)
   
     select=1:numel(pppcomb.omtfile);
     while pppcomb.omt > maxomt_for_reprocessing && numel(pppcomb.omtfile) > 2
 
       [~,i]=max(pppcomb.omtfile);
       doyremoved=doy(select(i));
       fprintf('*** Removing solution file %s from combination (doy=%d) ***\n\n',pppcomb.obsfile{i},doyremoved)
       select(i)=[];

       %pppremoved=[ pppremoved ; pppcomb.name pppcomb.obsfile(i) {pppcomb.omtfile(i)} ];
       pppremoved=[ pppremoved ; pppcomb.name pppcomb.obsfile(i) {pppcomb.omtfile(i)}  kk+1 doyremoved];
       pppcomb=pppcombine(pppstruct,select);

       fprintf('Re-processing %s done (OMT value %.3f)\n',dirnames(k).name,pppcomb.omt)
       fprintf('Observation file       OMT\n')
       for l=1:numel(pppcomb.obsfile)
         fprintf('%17s %8.3f\n',pppcomb.obsfile{l},pppcomb.omtfile(l))
       end
       fprintf('\n\n')

     end

     % add array with doy to pppcomb just before saving
     pppcomb.doys=doy(select);

     if pppcomb.omt < maxomt_for_save
       kk=kk+1;
       pppsave(kk)=pppcomb;
     else
       pppskipped=[ pppskipped ; pppcomb.name {pppcomb.obsfile} {pppcomb.omt} {'Max OMT exceeded'} ];       
     end
     
   catch ME
     
     ME
     warning(['There was an error processing ' dirnames(k).name ])
     pppskipped=[ pppskipped ; dirnames(k).name {pppstruct.obsfile(segment)} { nan } { ME.message } ];       
   end
   
end

% Summarize the removed data files

nremoved=size(pppremoved,1);
if nremoved > 0
  fprintf('\n\nFiles removed from the combination (%d):\n\n',nremoved)
  fprintf('Name  Obsfile     OMT\n')
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

%% Plot the OMT values

stations={pppsave.name};
numstations=numel(stations);

omtarray=[];
for k=1:numstations
   %daynum=cellfun(@(x) str2num(x(5:7)),pppsave(k).obsfile);
   daynum=pppsave(k).doys;
   omtarray=[ omtarray ; repmat(k,size(daynum)) daynum pppsave(k).omtfile pppsave(k).omtfile2d pppsave(k).omtfile1d ];
end

remarray=[];
nremoved=size(pppremoved,1);
for k=1:nremoved
   %daynum=str2num(pppremoved{k,2}(5:7));
   daynum=pppremoved{k,5};
   %kk=find(ismember(stations,pppremoved{k,1}));
   kk=pppremoved{k,4};
   %if ~isempty(kk)
   remarray=[ remarray ; kk daynum ];
   %end
end

figure('Name','Overall Model Test','NumberTitle','off','Position',[ 40 60 600 900])

subplot('Position',[ 0.1 0.1 0.6 .82])

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
hp.XTickLabel=hp.XTick;
hp.XTickLabelRotation=90;
xlim([ min(hp.XTick-1) max(hp.XTick+1)]);

hp.Box='on';
hp.FontSize=9;

year=char(unique(cellfun(@(x) x(1:4),[ pppsave.daterange ],'UniformOutput',false)));
%xlabel(year);

title([ 'Single day OMT (' year ')'])

subplot('Position',[ 0.78 0.1 0.17 .82])

omt=[pppsave.omt];
barh(omt)
hb=gca;
hb.YTick=1:numstations;
hb.YTickLabel=stations;
hb.YDir='reverse';
ylim([0 numstations+1])

hb.FontSize=9;

title('Multi day OMT')

%% Plot 2D- adn 1D-OMT values


figure('Name','2D/1D Overall Model Test','NumberTitle','off','Position',[ 40 60 600 900])

subplot('Position',[ 0.1 0.1 0.6 .82])

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
hp.XTickLabel=hp.XTick;
hp.XTickLabelRotation=90;
xlim([ min(hp.XTick-1) max(hp.XTick+1)]);

hp.Box='on';
hp.FontSize=9;

year=char(unique(cellfun(@(x) x(1:4),[ pppsave.daterange ],'UniformOutput',false)));
%xlabel(year);

title([ 'Single day 2D/1D OMT (' year ')'])

subplot('Position',[ 0.78 0.1 0.17 .82])

omt=[[pppsave.omt2d]' [pppsave.omt1d]'];
barh(omt)
hb=gca;
hb.YTick=1:numstations;
hb.YTickLabel=stations;
hb.YDir='reverse';
ylim([0 numstations+1])

hb.FontSize=9;

title('Multi day OMT')


%% Plot with the station quality

figure('Name','Station Quality','NumberTitle','off','Position',[ 40 60 600 900])

subplot('Position',[ 0.1 0.1 0.22 .82])

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

subplot('Position',[ 0.4 0.1 0.22 .82])


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

subplot('Position',[ 0.7 0.1 0.22 .82])

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

%%

figure('Name','Weighted RMS','NumberTitle','off','Position',[ 40 60 600 900])

subplot('Position',[ 0.1 0.1 0.22 .82])

wrms=cell2mat({ pppsave.wrmsNEU }')*1000;
barh(wrms)
ha=gca;
ha.YTick=1:numstations;
ha.YTickLabel=stations;
ha.YDir='reverse';
ylim([0 numstations+1])
xlim([0 15]);

ha.FontSize=9;

xlabel('w-rmse [mm]')
legend({'N','E','U'})

title(['W-RMSE (' year ')'])

subplot('Position',[ 0.4 0.1 0.22 .82])

rms=cell2mat({ pppsave.rmsNEU }')*1000;
barh(rms)

hb=gca;
hb.YTick=1:numstations;
hb.YTickLabel=stations;
hb.YDir='reverse';
ylim([0 numstations+1])
xlim([0 20]);

hb.FontSize=9;

xlabel('rmse [mm]')
legend({'N','E','U'})

title(['RMSE (' year ')'])

subplot('Position',[ 0.7 0.1 0.22 .82])

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

%% Print sitelist

fprintf('site,latitude(deg),longitude(deg)\n')
for k=1:numel(pppsave)
   fprintf('%4s,%.10f,%.10f\n',pppsave(k).name,pppsave(k).plh(1:2)*180/pi)
end

