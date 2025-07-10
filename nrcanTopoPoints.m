%% Compute Topo Points from NRCAN Kinematic PPP results 
%
% In this script topo points are computed from NRCAN kinematic PPP results.
% For each topo point, the weighted average of the kinematic PPP solution
% is computed over the interval of occupation. The start and stop time
% of each occupation, and the point identifier, are read from a Trimble 
% job jxl file. The NRCAN PPP results are read from the NRCAN position
% file.
%
% (c) Hans van der Marel, TU Delft
%
% Created:  28 Apr 2019 by Hans van der Marel
% Modified:

%% Define the file names

tscfile='lourinha.jxl';

d=dir('*.pos');
posfiles={d.name};

%% Read TSC job control file (must be in jxl format)

tsc=tscread(tscfile);

tsc.check=false(size(tsc.pntid));
tsc.llh=nan([size(tsc.pntid,1),3]);
tsc.dneu=tsc.llh;
tsc.sdneu=tsc.llh;
tsc.rmsneu=tsc.llh;
tsc.numepochs=zeros(size(tsc.pntid));


%% Loop over position files and process

for p=1:numel(posfiles)
    
    % Read the posfile

    posfile=posfiles{p};
    pos=nrcanReadPos(posfile);
    posdate=datestr(pos.epoch(1),'yyyy-mm-dd');

    % Find topo points with the pos file
    
    idx=find(tsc.datenum >= pos.epoch(1) & tsc.datenum <= pos.epoch(end));
    if isempty(idx)
        fprintf('File %s (%d epochs) does not contains any topo points, skip this file...\n',posfile,numel(pos.epoch))
        continue;
    end
    
    tsc.check(idx)=true;
    
    % Compute (weighted) average and statistics (==> weighted lsq not yet
    % implemented, just taking a simple average as shortcut ...)
    
    for k=1:numel(idx) 
        kk=idx(k);
        pntid=tsc.pntid{kk};    
        % Find pos file epochs for this topo point
        x1=tsc.datenum(kk);
        x2=x1+tsc.duration(kk)/86400;
        idxpos=find( pos.epoch >= x1 & pos.epoch <= x2);
        dneu=mean(pos.dneu(idxpos,:));
        sdneu=mean(pos.sdneu(idxpos,:));
        rmsneu=std(pos.dneu(idxpos,:));
        tsc.llh(kk,:)=mean(pos.llh(idxpos,:));
        tsc.dneu(kk,:)=dneu;
        tsc.sdneu(kk,:)=sdneu;
        tsc.rmsneu(kk,:)=rmsneu;
        tsc.numepochs(kk)=numel(idxpos);
        tsc.posfile{kk}=posfile;
    end
    
    % Plot the kinematic solution with topo point interval(s)
    
    figure('outerposition',[ 10  40  1900 1000]);
    subplot(3,1,1)
    plot(pos.epoch,pos.dneu)
    datetick('x')
    ylabel('\Delta Position [m]')
    legend('dLat','dLon','dHgt')
    title([ posfile ' (' posdate ')'])

    for k=1:numel(idx) 
        x1=tsc.datenum(idx(k));
        x2=x1+tsc.duration(idx(k))/86400;
        yy=ylim';
        patch([x1 ; x1 ;x2 ; x2 ],[ yy(1) ; yy(2) ; yy(2) ; yy(1) ],'cyan','FaceAlpha',0.2);
        %line([ x1 ; x1 ], yy ,'linestyle','-'); 
        %line([ x2 ; x2 ], yy ,'linestyle',':'); 
        text(x1,yy(2)-(yy(2)-yy(1))/10,[' ' tsc.pntid{idx(k)}])    
    end

    subplot(3,1,2)
    plot(pos.epoch,pos.sdneu)
    datetick('x')
    ylabel('\sigma (95%) Position [m]')
    legend('sdLat','sdLon','sdHgt')

    for k=1:numel(idx) 
        x1=tsc.datenum(idx(k));
        x2=x1+tsc.duration(idx(k))/86400;
        yy=ylim';
        patch([x1 ; x1 ;x2 ; x2 ],[ yy(1) ; yy(2) ; yy(2) ; yy(1) ],'cyan','FaceAlpha',0.2);
        %line([ x1 ; x1 ], yy ,'linestyle','-'); 
        %line([ x2 ; x2 ], yy ,'linestyle',':'); 
        text(x1,yy(2)-(yy(2)-yy(1))/10,[ ' ' tsc.pntid{idx(k)}])    
    end

    subplot(3,1,3)
    plot(pos.epoch,pos.rmsp,'r-')
    datetick('x')
    ylabel('rms phase [m]')
    legend('rmsP')

    for k=1:numel(idx) 
        x1=tsc.datenum(idx(k));
        x2=x1+tsc.duration(idx(k))/86400;
        yy=ylim';
        patch([x1 ; x1 ;x2 ; x2 ],[ yy(1) ; yy(2) ; yy(2) ; yy(1) ],'cyan','FaceAlpha',0.2);
        %line([ x1 ; x1 ], yy ,'linestyle','-'); 
        %line([ x2 ; x2 ], yy ,'linestyle',':'); 
        text(x1,yy(2)-(yy(2)-yy(1))/10,[ ' ' tsc.pntid{idx(k)} ])    
    end

end

%% Check

if all(tsc.check)
    fprintf('All topo points found, ok\n')
else
    fprintf('Some topo points missing ...\n')
    tsc.pntid(~tsc.check)
end

%% Print results

fprintf('\n\n Pnt.Id.    Lat [deg]    Lon [deg]  Hgt [m]   sN[m]  sE[m]  sU[m]  sdN[m] sdE[m] sdU[m]   nepo  min ns pdop antHgt    code \n\n')
for k=1:numel(tsc.pntid)
   f=sqrt(60/tsc.numepochs(k))/2;
   fprintf('%8s %12.8f %12.8f %8.3f  %6.3f %6.3f %6.3f  %6.3f %6.3f %6.3f  %5d %4.1f %2d %4.1f %6.3f%8s %s %s\n', ...
       tsc.pntid{k},tsc.llh(k,:),tsc.sdneu(k,:)*f,tsc.rmsneu(k,:), ...
       tsc.numepochs(k),tsc.duration(k)/60,tsc.numsat(k),tsc.pdop(k),tsc.anthgt(k), ...
       tsc.code{k},tsc.posfile{k},tsc.datestr(k,:))  
end
    
