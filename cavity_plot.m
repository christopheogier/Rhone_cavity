%% Determine Cavity height and calculate 3D volume from GPR picking
%Christophe Ogier 1 september 2022
clear all

%% Path for data

%initPar = read_init();
%defaultdir = initPar.lastSgyFile; %inspired by segy processing (that is why segy is still mentionned here)
%[fname,pname]=uigetfile({'*picks.txt'},'Choose txt file, ...',defaultdir,'MultiSelect','off'); %add 'pwd' instead of defaultdir if troubles
path='/scratch-3/cogier/data/Rhone/GPR/';
outputdir='/scratch-3/cogier/data/Rhone/cavity/';
plotdir=fullfile(outputdir,'plot');
if ~isfolder(plotdir), mkdir(plotdir); end
addpath(genpath('/scratch-3/cogier/topotoolbox3/toolbox'));
addpath('/scratch-3/cogier/gprglaz_co/gprglaz_co/gpr_supplement'); % viridis colormap

 

%% load bedrock map
%zbed=2210; %direct observations from borhole and within the uncertainties range of bedrock map of grab et al 2020
%read DEM of bedrock elevation from Grab et al 2010
DEMfile = '/scratch-3/cogier/data/Rhone/bed/B43-03_GlacierBed.tif';
BED = GRIDobj(DEMfile);  %think to add topotoolbox in matlab path
corr=7; %bed elevation correction: the bedrock is underestimated by 10m at the boregole (direct measurement at the center of the cavity), we thus assume that this underestimation is uniform in the vicinity and apply a majoration of 10m
%note on the bedrock map: the slope gradient might be respected witzh this
%technique (5m elevation difference betwwen entrance and exit of the cavity)
inc=0.5;

%% TXT reading and gridd creation for roof thickness and cavity height (corrected from bed elevation)
% 28 July
[xcav1,ycav1,zsurf1,zcav1,th1,xq1,yq1,roof1,cavity1,h1,v1,v_err1] = cavity3D([path,'20220728_rhone/L2/20220728_Rhone_picks.txt'], BED,corr,inc);
% 11 August
[xcav2,ycav2,zsurf2,zcav2,th2,xq2,yq2,roof2,cavity2,h2,v2,v_err2] = cavity3D([path,'20220811_rhone/L2/20220811_Rhone_picks.txt'], BED,corr,inc);
% 24 August
[xcav3,ycav3,zsurf3,zcav3,th3,xq3,yq3,roof3,cavity3,h3,v3,v_err3] = cavity3D([path,'20220824_rhone/L2/20220824_rhone_picks.txt'], BED,corr,inc);
% 7 October
[xcav4,ycav4,zsurf4,zcav4,th4,xq4,yq4,roof4,cavity4,h4,v4,v_err4] = cavity3D([path,'20221007_rhone/L2/20221007_rhone_picks.txt'], BED,corr,inc);

% Save all four survey grids, picks, volumes and uncertainties before plotting.
% xq*/yq* are mesh coordinates; cavity* is height and roof* is ice thickness.
save(fullfile(outputdir,'cavity_model.mat'));

%% plot parameters
subtitle_size=15;

%% plot subplots Roof thickness and Cavity height

%not yet coded: plot BH measurement with roof thickness map

%plot_cavity('20220728');
%plot_cavity('20220811');
%plot_cavity('20220824');
plot_cavity('20221007',plotdir);


%% 3D plot cavity 
%% 20220824 
figure()
m = mesh(xq3,yq3,cavity3,'FaceAlpha','1');
m.FaceColor = 'flat';
hold on
p=plot3(xcav3,ycav3,h3,'o','MarkerSize',1);
p.Color='black'
colorbar
title('Cavity Height (m)')
xlabel('Easting (m)')
ylabel('Northing (m)')

saveas(gcf,fullfile(plotdir,'20220824_cavity_height.png'));

%% Roof elevation gridd:

roof_elev3 = griddata(xcav3,ycav3,zcav3,xq3,yq3);
m = mesh(xq3,yq3,roof_elev3,'FaceAlpha','1');
m.FaceColor = 'flat';
hold on
p=plot3(xcav3,ycav3,zcav3,'o','MarkerSize',1);


saveas(gcf,fullfile(plotdir,'20220824_roof_elevation.png'));
save(fullfile(outputdir,'cavity_model.mat'),'roof_elev3','-append');

%% Plot volume times series

v=[v1,v2,v3,v4];
x=[datetime(2022,07,28),datetime(2022,08,11),datetime(2022,08,24),datetime(2022,10,7)];
v_err=[v_err1 v_err2 v_err3 v_err4];
figure();
fig = errorbar(x,v,v_err,'LineStyle','--');
xlim([datetime(2022,07,15) datetime(2022,10,10)])
xlabel('Time');
ylabel('Cavity volume (m^{3})')
title('Cavity volume time series')
fname='cavity volume time series';
saveas(fig,fullfile(plotdir,fname),'png')

%% Plot subsidence

subsidencefile='/scratch-3/cogier/data/Rhone/stakes_subsidence_2022.txt';
if isfile(subsidencefile)
T =readcell(subsidencefile,'NumHeaderLines',1);

t_visit = [datetime(2022,06,20),datetime(2022,7,4),datetime(2022,7,14),datetime(2022,7,28),datetime(2022,8,11),datetime(2022,8,27),datetime(2022,9,9),datetime(2022,10,7)];
s0 = cell2mat(T(1,2:end)); %1 colomn is a header (stake number)
s0(8) = -3.1; %Stake so was lost but surface lower by 3.6m (dGPS measurement). Melt was about 40 to 60cm since the last measurement. So let's say -3.1 +- 0.2 (0.2 is the uncertainties on the melt
s1 = cell2mat(T(2,2:end));
s2 = cell2mat(T(3,2:end));
s3 = cell2mat(T(4,2:end));
s4 = cell2mat(T(5,2:end));
s5 = cell2mat(T(6,2:end));
s6 = cell2mat(T(7,2:end));

fig = errorbar(t_visit,cumsum(s0),[0 0 0 0 0 0 0 0.2],'Marker','o');
hold on
plot(t_visit,cumsum(s1),'Marker','o');
hold on
plot(t_visit,cumsum(s2),'Marker','o');
hold on
plot(t_visit,cumsum(s3),'Marker','o');
hold on
plot(t_visit,cumsum(s4),'Marker','o');
hold on
plot(t_visit,cumsum(s5),'Marker','o');
hold on
plot(t_visit,cumsum(s6),'Marker','o');
legend({'s0','s1','s2','s3','s4','s5','s6'},'location','southwest')
xlim([datetime(2022,6,15) datetime(2022,10,15)])
xlabel('Time');
ylabel('Cumulative vertical stake displacement (m)')
title('Vertical surface displacement (m)')
fname='Vertical surface displacement';
saveas(fig,fullfile(plotdir,fname),'png')

else
    warning('Skipping subsidence plot: missing %s',subsidencefile);
end

%% Function


function plot_cavity(gprdate,plotdir)

%gprdate is a string with the date of the aquisition, ex: '20220824'

path='/scratch-3/cogier/data/Rhone/GPR/';
%plot background orthophoto
path_photo='/scratch-3/cogier/data/Rhone/20220824_rhone_collapse_dop_cogier.tif';


%read DEM of bedrock elevation from Grab et al 2010
DEMfile = '/scratch-3/cogier/data/Rhone/bed/B43-03_GlacierBed.tif';
BED = GRIDobj(DEMfile);
corr=7; %bed elevation correction: the bedrock is underestimated by 10m at the boregole (direct measurement at the center of the cavity), we thus assume that this underestimation is uniform in the vicinity and apply a majoration of 10m
%note on the bedrock map: the slope gradient might be respected witzh this
%technique (5m elevation difference betwwen entrance and exit of the cavity)
inc=0.5;

if gprdate=='20220728'
    [xcav,ycav,zsurf,zcav,th,xq,yq,roof,cavity,h,v,v_err] = cavity3D([path,'20220728_rhone/L2/20220728_Rhone_picks.txt'], BED,corr,inc);
elseif gprdate=='20220811'
    [xcav,ycav,zsurf,zcav,th,xq,yq,roof,cavity,h,v,v_err] = cavity3D([path,'20220811_rhone/L2/20220811_Rhone_picks.txt'], BED,corr,inc);
elseif gprdate=='20220824'
    [xcav,ycav,zsurf,zcav,th,xq,yq,roof,cavity,h,v,v_err] = cavity3D([path,'20220824_rhone/L2/20220824_rhone_picks.txt'], BED,corr,inc);
elseif gprdate=='20221007'
    [xcav,ycav,zsurf,zcav,th,xq,yq,roof,cavity,h,v,v_err] = cavity3D([path,'20221007_rhone/L2/20221007_rhone_picks.txt'], BED,corr,inc);
else 
    error('No GPR aquisition for this date')
end

    function plot_backgroundphoto(path)
    %plot background orthophoto
    if ~isfile(path)
        warning('Skipping orthophoto background: missing %s',path);
        axis equal
        hold on
        return
    end
    [Xp, cmapp, refmat, ~]=geotiffread(path);
      if size(Xp,3)==4
            %get rid of X(:,:,4), otherwise mapshow will not work
            Xp=Xp(:,:,1:3);
        end
    mapshow(Xp,cmapp,refmat);
    axis equal
    hold on
    end

%plot
fig=figure('units','normalized','outerposition',[0 0 1 1]);%full screen figure for subplots
subtitle_size=15;

subplot(1,2,1);
plot_backgroundphoto(path_photo)
im = imagesc(xq(1,:),yq(:,1),roof,'AlphaData',~isnan(roof));axis equal;colorbar;
set(gca,'YDir','normal')
h = title(['Ice-roof thickness ',gprdate]);
set(h,'Fontsize',subtitle_size);
colormap(gca,flipud(viridis(100)))
h1 = colorbar;
%freezeColors
hh1 = get(h1,'title');
set(hh1,'string',['(m)'],'Fontsize',subtitle_size);
hold on
caxis([1 23]);
% gpr traces
scatter(xcav,ycav,1,th,'filled','MarkerEdgeColor','black')
% plot minimum thickness
[a,b] = find(roof==min(min(roof)));
scatter(xq(1,b),yq(a,1),'filled','MarkerEdgeColor','red');
format short g %to remove useless decimals 0 in the following
text(2672785,1159585,['Min. thickness= ',num2str(round(min(min(roof)),2)),' m'],'BackgroundColor','w')
xlim([2672750 2672850]);
ylim([1159580 1159660]);

subplot(1,2,2);
plot_backgroundphoto(path_photo)
im = imagesc(xq(1,:),yq(:,1),cavity,'AlphaData',~isnan(cavity));axis equal;colorbar;
set(gca,'YDir','normal')
h = title(['Cavity height ',gprdate]);
set(h,'Fontsize',subtitle_size);
h = colorbar;
hh = get(h,'title');
set(hh,'string',['(m)'],'Fontsize',subtitle_size);
colormap(gca,viridis(100))
hold on
caxis([0 15]);
% gpr traces
scatter(xcav,ycav,1,'filled','MarkerEdgeColor','black')
text(2672785,1159585,['Cavity vol.= ',num2str(v),' ',char(177),' ',num2str(v_err),' m^3'],'BackgroundColor','w')
xlim([2672750 2672850]);
ylim([1159580 1159660]);

sgtitle(gprdate) 
saveas(fig,fullfile(plotdir,gprdate),'png')
end
