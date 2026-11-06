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
copyfile(fullfile(fileparts(mfilename('fullpath')),'README.md'), ...
    fullfile(outputdir,'README.md'));

%% Compare the four surveys with common axes and colour scales.
survey_dates = datetime([2022 2022 2022 2022],[7 8 8 10],[28 11 24 7]);
survey_dates.Format = 'dd.MM.yyyy';
X = {xq1,xq2,xq3,xq4}; Y = {yq1,yq2,yq3,yq4};
heights = {cavity1,cavity2,cavity3,cavity4};
roofs = {roof1,roof2,roof3,roof4};
px = {xcav1,xcav2,xcav3,xcav4}; py = {ycav1,ycav2,ycav3,ycav4};
pz = {zcav1,zcav2,zcav3,zcav4};
volumes = [v1 v2 v3 v4]; errors = [v_err1 v_err2 v_err3 v_err4];
roof_elev = cell(1,4);
for k = 1:4
    roof_elev{k} = griddata(px{k},py{k},pz{k},X{k},Y{k});
end
roof_elev3 = roof_elev{3}; % retain the existing saved variable
save(fullfile(outputdir,'cavity_model.mat'),'roof_elev','roof_elev3','survey_dates','-append');

plot_surveys(X,Y,heights,px,py,survey_dates,volumes,errors, ...
    'Height above bedrock (m)',false,plotdir,'cavity_height_maps');
plot_surveys(X,Y,roofs,px,py,survey_dates,[],[], ...
    'Ice-roof thickness (m)',false,plotdir,'roof_thickness_maps');
plot_surveys(X,Y,heights,px,py,survey_dates,volumes,errors, ...
    'Height above bedrock (m)',true,plotdir,'cavity_height_3D');
%% Plot the same quantity for all acquisition dates.
function plot_surveys(X,Y,Z,px,py,dates,volumes,errors,label,is3d,plotdir,name)
fig = figure('Color','w','Position',[100 100 1400 1000]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
values = cellfun(@(z) z(isfinite(z)),Z,'UniformOutput',false);
limits = [min(vertcat(values{:})),max(vertcat(values{:}))];
if limits(1)==limits(2), limits(2)=limits(1)+1; end
xlimits = [min(cellfun(@(x) min(x(:)),X)),max(cellfun(@(x) max(x(:)),X))];
ylimits = [min(cellfun(@(y) min(y(:)),Y)),max(cellfun(@(y) max(y(:)),Y))];
for k = 1:4
    ax = nexttile(layout);
    if is3d
        surf(ax,X{k},Y{k},Z{k},'EdgeColor','none');
        view(ax,40,30);
        zlabel(ax,label);
        zlim(ax,limits);
    else
        imagesc(ax,X{k}(1,:),Y{k}(:,1),Z{k},'AlphaData',isfinite(Z{k}));
        set(ax,'YDir','normal');
        hold(ax,'on');
        scatter(ax,px{k},py{k},4,'k','filled');
        axis(ax,'equal');
    end
    xlim(ax,xlimits); ylim(ax,ylimits);
    clim(ax,limits); colormap(ax,viridis(100));
    grid(ax,'on'); box(ax,'on');
    xlabel(ax,'Easting (m)'); ylabel(ax,'Northing (m)');
    ax.FontSize = 11;
    if isempty(volumes)
        title(ax,char(dates(k)),'FontSize',14);
    else
        title(ax,{char(dates(k)),sprintf('Volume: %.0f %s %.0f m^{3}', ...
            volumes(k),char(177),errors(k))},'FontSize',14);
    end
end
cb = colorbar(ax); cb.Layout.Tile = 'east'; cb.Label.String = label;
title(layout,label,'FontSize',18);
exportgraphics(fig,fullfile(plotdir,[name,'.png']),'Resolution',180);
end
