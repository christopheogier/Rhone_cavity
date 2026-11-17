
%% Rhone collapse paper figure: one script, four panels.
% Inspired by Hosli et al. (2025), doi:10.1017/jog.2025.33, Figs 2, 9, 11.
% Campaign dates follow the GPR filenames; confirm the article's 1-day
% discrepancies for the last two campaigns before submission.
% Input preparation and source notes: data/Rhone/stakes/README.txt.
% Run from any folder. Only this script is needed in addition to the inputs.
clearvars
repo = fileparts(mfilename('fullpath'));

%% Inputs and display settings.
data_root = '/scratch-3/cogier/data/Rhone';
model_file = fullfile(repo,'results','cavity_model.mat');
stake_file = fullfile(data_root,'stakes','stake_positions.csv');
t0_file = fullfile(data_root,'stakes','t0_vertical_motion.csv');
glacier_outline_file = fullfile(data_root,'maps','rhone_sgi2016.shp');
% Georeferenced RGB GeoTIFFs in Swiss LV95 (EPSG:2056); empty = blank map.
overview_photo = fullfile(data_root,'orthophoto','20220824_rhone_collapse_dop.tif');
overview_photo_date = '24.08.2022';
survey_photo = fullfile(data_root,'orthophoto','20220824_rhone_collapse_dop.tif');
survey_photo_date = '24.08.2022';
collapse_photo = fullfile(data_root,'orthophoto','20230705_Rhone_tongue_5cm_dop.tif');
collapse_photo_date = '05.07.2023';
stake_map_date = datetime(2022,8,24); % choose the closest stake visit date
map_alpha = 0.65;
axis_label_font = 18*0.85;                % 15% smaller than the enlarged labels
axis_tick_font = 10;
annotation_font = 10;
outline_smoothing_points = 5;        % display only; about 1 m of boundary
output_png = fullfile(repo,'plot','paper_figure.png');
output_pdf = fullfile(repo,'plot','paper_figure.pdf');
output_data = fullfile(repo,'results','paper_figure_data.mat');

%% Load the existing model without changing cavity3D or the original results.
M = load(model_file,'xcav*','ycav*','th*','h*','v*','inc','corr','survey_dates');
dates = M.survey_dates;
dates.Format = 'dd.MM.yyyy';
volumes = [M.v1 M.v2 M.v3 M.v4];
volume_errors = [M.v_err1 M.v_err2 M.v_err3 M.v_err4];
pick_files = {
    '20220728_rhone/L2/20220728_Rhone_picks.txt'
    '20220811_rhone/L2/20220811_Rhone_picks.txt'
    '20220824_rhone/L2/20220824_rhone_picks.txt'
    '20221007_rhone/L2/20221007_rhone_picks.txt'};
track_dirs = {
    '20220728_rhone/GPS/profiles_shape'
    '20220811_rhone/GPS/profiles_shape'
    '20220824_rhone/GPS/profiles_shape'
    '20221007_rhone/GPS/profiles_shape'};

%% Cavity heights on one fixed grid, within each campaign's sampled hull.
% No extrapolation or artificial zero-valued padding at survey boundaries.
px = cell(1,4); py = cell(1,4);
for k = 1:4
    px{k} = M.(sprintf('xcav%d',k));
    py{k} = M.(sprintf('ycav%d',k));
end
xx = vertcat(px{:}); yy = vertcat(py{:});
[X,Y] = meshgrid(floor(min(xx)/M.inc)*M.inc:M.inc:ceil(max(xx)/M.inc)*M.inc, ...
    floor(min(yy)/M.inc)*M.inc:M.inc:ceil(max(yy)/M.inc)*M.inc);
cavity_height = nan([size(X),4]);
for k = 1:4
    cavity_height(:,:,k) = griddata(px{k},py{k},M.(sprintf('h%d',k)),X,Y,'linear');
end
snapshot_index = 3; % 24.08.2022
snapshot_height = cavity_height(:,:,snapshot_index);
% Footprint boundaries, including survey-limited edges. These are not
% measured h=0 contours. Padding the binary mask closes each outline.
extent_outlines = cell(1,4); raw_extent_outlines = cell(1,4);
footprint_masks = isfinite(cavity_height) & cavity_height>0;
outline_x = [X(1,1)-M.inc, X(1,:), X(1,end)+M.inc];
outline_y = [Y(1,1)-M.inc; Y(:,1); Y(end,1)+M.inc];
for k = 1:4
    mask = false(size(X)+2);
    mask(2:end-1,2:end-1) = footprint_masks(:,:,k);
    C = contourc(outline_x,outline_y,double(mask),[0.5 0.5]);
    raw_extent_outlines{k} = C;
    % Circular moving average removes grid stair steps, without changing any
    % cavity heights or masks. Preserve each closed ring and its point count.
    j = 1; half_window = floor(outline_smoothing_points/2);
    while j<size(C,2)
        count = C(2,j); ids = j+(1:count);
        if count>outline_smoothing_points && norm(C(:,ids(1))-C(:,ids(end)))<1e-8
            xy = C(:,ids(1:end-1));
            wrapped = [xy(:,end-half_window+1:end),xy,xy(:,1:half_window)];
            averaged = movmean(wrapped,outline_smoothing_points,2);
            xy = averaged(:,half_window+(1:size(xy,2)));
            C(:,ids) = [xy,xy(:,1)];
        end
        j = j+count+1;
    end
    extent_outlines{k} = C;
end

%% Published t0 data: stop at the first missing motion increment.
T = readtable(t0_file,'TextType','string');
T.date = datetime(T.date,'InputFormat','yyyy-MM-dd');
stop = find(~isfinite(T.dz_m),1);
if ~isempty(stop), T = T(1:stop-1,:); end
assert(issorted(T.date) && T.dz_m(1)==0,'Check t0 baseline and date order.');
t0_dates = T.date; t0_displacement = cumsum(T.dz_m);
% dz is vertical ice motion from the published analysis, NOT raw surface dz.
% t0/t0b are linked in that analysis. Do not bridge the missing October value.
S = readtable(stake_file,'TextType','string');
S.date = datetime(S.date,'InputFormat','yyyy-MM-dd');
% Keep only t0, using its nearest 2022 visit to the August orthophoto.
% Exclude retired stakes and, on replacement dates, choose the latest reading.
S = S(S.stake_total_length_m>0,:);
S.observed_at = datetime(string(S.date,'yyyy-MM-dd')+" "+S.time, ...
    'InputFormat','yyyy-MM-dd HH:mm');
S.label = regexprep(S.id,'^\d{2}(t\d+).*','$1');
S = S(S.label=="t0",:);
labels = unique(S.label,'stable'); positions = S([],:);
for k = 1:numel(labels)
    rows = find(S.label==labels(k));
    if ~isempty(rows)
        distance = abs(days(S.date(rows)-stake_map_date));
        rows = rows(distance==min(distance));
        [~,j] = max(S.observed_at(rows));
        positions = [positions; S(rows(j),:)]; %#ok<AGROW>
    end
end

%% Figure layout and map extents in Swiss LV95 coordinates.
origin = [0,0];                      % display full LV95 coordinates
map_extent = [min(xx)-8,max(xx)+8,min(yy)-8,max(yy)+8];
overview_extent = map_extent+[-30 30 -30 30]; % panels a/b: another 20 m in per side
blue = [0.08 0.32 0.66]; orange = [0.85 0.36 0.08];
extent_colors = [0.12 0.32 0.78; 0.30 0.67 0.88; 0.96 0.62 0.26; 0.80 0.10 0.12];
fig = figure('Color','w','Units','centimeters','Position',[2 2 36 26]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
layout.Units = 'normalized';
layout.OuterPosition = [0.07 0.08 0.87 0.90]; % room for large labels and dates
ax = gobjects(1,4);
photos = {overview_photo,collapse_photo,survey_photo};
photo_dates = {overview_photo_date,collapse_photo_date,survey_photo_date};
for panel = 1:3
    ax(panel) = nexttile(layout,panel); hold(ax(panel),'on');
    extent = map_extent;
    if panel<=2, extent = overview_extent; end
    if ~isempty(photos{panel})
        assert(isfile(photos{panel}),'Orthophoto does not exist: %s',photos{panel});
        assert(~isempty(photo_dates{panel}),'Set the orthophoto acquisition date.');
        % Read only a cropped, downsampled TIFF window, including for large images.
        info = georasterinfo(photos{panel}); R = info.RasterReference;
        assert(~isempty(info.CoordinateReferenceSystem) && ...
            contains(info.CoordinateReferenceSystem.Name,'CH1903+'), ...
            'Reproject the orthophoto to Swiss LV95 (EPSG:2056) first.');
        assert(isa(R,'map.rasterref.MapCellsReference'), ...
            'Use a north-up projected RGB GeoTIFF in LV95.');
        [col,row] = worldToIntrinsic(R,extent([1 2]),extent([3 4]));
        col = [max(1,floor(min(col))),min(R.RasterSize(2),ceil(max(col)))];
        row = [max(1,floor(min(row))),min(R.RasterSize(1),ceil(max(row)))];
        assert(col(1)<=col(2) && row(1)<=row(2),'Orthophoto does not cover this map.');
        stride = max(1,ceil(max([diff(col),diff(row)])/1800));
        rgb = imread(photos{panel},'PixelRegion',{[row(1) stride row(2)], ...
            [col(1) stride col(2)]});
        assert(size(rgb,3)>=3,'Use an RGB orthophoto.');
        [east,north] = intrinsicToWorld(R, ...
            [col(1),col(1)+(size(rgb,2)-1)*stride], ...
            [row(1),row(1)+(size(rgb,1)-1)*stride]);
        image(ax(panel),'XData',east-origin(1),'YData',north-origin(2), ...
            'CData',rgb(:,:,1:3));
        photo_note = ['Orthophoto: ',photo_dates{panel}];
    else
        photo_note = 'Orthophoto pending';
    end
    if panel==3
        imagesc(ax(panel),X(1,:)-origin(1),Y(:,1)-origin(2),snapshot_height, ...
            'AlphaData',map_alpha*isfinite(snapshot_height));
        clim(ax(panel),[0 max(snapshot_height(:),[],'omitnan')]);
        colormap(ax(panel),parula(256));
        cb = colorbar(ax(panel),'eastoutside');
        cb.Label.String = 'Cavity height above bedrock (m)';
        cb.FontSize = axis_tick_font; cb.Label.FontSize = axis_label_font;
        % Read each profile separately: combined files are multipoints and
        % connecting their vertices would create false inter-profile lines.
        for k = snapshot_index
            track_dir = fullfile(data_root,'GPR',track_dirs{k});
            files = dir(fullfile(track_dir,'*.shp'));
            if ~isempty(files)
                for f = 1:numel(files)
                    tracks = shaperead(fullfile(files(f).folder,files(f).name));
                    for j = 1:numel(tracks)
                        tx = tracks(j).X(:); ty = tracks(j).Y(:);
                        % Break large GPS jumps; do not invent connecting paths.
                        gaps = [false; hypot(diff(tx),diff(ty))>5];
                        tx(gaps) = NaN; ty(gaps) = NaN;
                        plot(ax(panel),tx-origin(1),ty-origin(2), ...
                            '-','Color',[0.12 0.12 0.12],'LineWidth',0.7);
                    end
                end
            else
                warning('Full tracks missing; plotting picked segments: %s',track_dir);
                picks = readmatrix(fullfile(data_root,'GPR',pick_files{k}), ...
                    'NumHeaderLines',1);
                breaks = [0;find(diff(picks(:,1))~=0);size(picks,1)];
                for j = 1:numel(breaks)-1
                    ids = breaks(j)+1:breaks(j+1);
                    plot(ax(panel),picks(ids,2)-origin(1),picks(ids,3)-origin(2), ...
                        'k-','LineWidth',0.7);
                end
            end
        end
        text(ax(panel),0.97,0.04,char(dates(snapshot_index)), ...
            'Units','normalized','HorizontalAlignment','right', ...
            'FontSize',annotation_font,'BackgroundColor','w');
        % Explicit opaque key: the white rectangle covers line AND text.
        key_width = 0.48*diff(extent(1:2));
        key_height = 0.065*diff(extent(3:4));
        key_x = extent(1)-origin(1)+0.03*diff(extent(1:2));
        key_y = extent(3)-origin(2)+0.025*diff(extent(3:4));
        rectangle(ax(panel),'Position',[key_x,key_y,key_width,key_height], ...
            'FaceColor','w','EdgeColor','w');
        key_mid_y = key_y+key_height/2;
        plot(ax(panel),key_x+[0.04 0.25]*key_width,[key_mid_y key_mid_y], ...
            'k-','LineWidth',1.6);
        text(ax(panel),key_x+0.30*key_width,key_mid_y,'GPR profiles', ...
            'FontSize',annotation_font,'Color','k','VerticalAlignment','middle');

    end
    % t0 is a fixed 2022 reference location on every orthophoto, including
    % July 2023: the stake had already been lost, so this is not a 2023 fix.
    scatter(ax(panel),positions.easting_m-origin(1),positions.northing_m-origin(2), ...
        35,'r','filled','MarkerEdgeColor','w');
    text(ax(panel),positions.easting_m-origin(1)-2,positions.northing_m-origin(2), ...
        't0','HorizontalAlignment','right','FontSize',annotation_font+1, ...
        'BackgroundColor','w','Margin',1);
    if panel<3
        text(ax(panel),0.03,0.96,photo_note,'Units','normalized', ...
            'VerticalAlignment','top','FontSize',annotation_font,'BackgroundColor','w');
    else
        text(ax(panel),0.97,0.04,photo_note,'Units','normalized', ...
            'HorizontalAlignment','right','FontSize',annotation_font,'BackgroundColor','w');
    end
    set(ax(panel),'YDir','normal','Color',[0.96 0.96 0.96],'FontSize',axis_tick_font);
    axis(ax(panel),'equal'); box(ax(panel),'on');
    xlim(ax(panel),extent(1:2)-origin(1)); ylim(ax(panel),extent(3:4)-origin(2));
    xlabel(ax(panel),'Easting (m)');
    ylabel(ax(panel),'Northing (m)');
    ax(panel).XAxis.Exponent = 0; ax(panel).YAxis.Exponent = 0;
    xtickformat(ax(panel),'%.0f'); ytickformat(ax(panel),'%.0f');
    % A few full-coordinate ticks avoid crowded seven-digit labels.
    xstep = max(10,ceil(diff(extent(1:2))/30)*10);
    ystep = max(10,ceil(diff(extent(3:4))/30)*10);
    xticks(ax(panel),ceil(extent(1)/xstep)*xstep:xstep:extent(2));
    yticks(ax(panel),ceil(extent(3)/ystep)*ystep:ystep:extent(4));
    % Metre scale bar; north is up for these projected map axes.
    xbar = extent(1)-origin(1)+0.07*diff(extent(1:2));
    ybar = extent(4)-origin(2)-0.17*diff(extent(3:4));
    plot(ax(panel),[xbar xbar+10],[ybar ybar],'k-','LineWidth',2);
    text(ax(panel),xbar+5,ybar-3.5,'10 m','HorizontalAlignment','center','FontSize',annotation_font);

end

%% Optional former cavity-extent panel (disabled).
% Kept for reuse: uncomment this block to draw the four extents over panel b.
% Change ax(2) below if a different panel should host this view.
%{
        % Coloured sampled extents, with holes preserved and black boundaries.
        extent_keys = gobjects(1,4);
        for k = 1:4
            C = extent_outlines{k}; j = 1; footprint = polyshape();
            while j<size(C,2)
                count = C(2,j);
                ids = j+(1:count);
                ring = polyshape(C(1,ids)-origin(1),C(2,ids)-origin(2), ...
                    'Simplify',false);
                footprint = xor(footprint,ring);
                j = j+count+1;
            end
            extent_keys(k) = plot(ax(2),footprint,'FaceColor',extent_colors(k,:), ...
                'FaceAlpha',0.22,'EdgeColor','k','LineWidth',1.5);
        end
        % Redraw all boundaries above the transparent fills so they stay black.
        for k = 1:4
            C = extent_outlines{k}; j = 1;
            while j<size(C,2)
                count = C(2,j); ids = j+(1:count);
                plot(ax(2),C(1,ids)-origin(1),C(2,ids)-origin(2), ...
                    'k-','LineWidth',1.5);
                j = j+count+1;
            end
        end
        legend(ax(2),extent_keys,cellstr(string(dates)), ...
            'Location','northwest','FontSize',annotation_font, ...
            'Color','w','EdgeColor','w','Box','on','AutoUpdate','off');
%}

%% (d) Cumulative t0 vertical displacement and the four GPR cavity volumes.
ax(4) = nexttile(layout,4); hold(ax(4),'on');
yyaxis(ax(4),'left');
p0 = plot(ax(4),t0_dates,t0_displacement,'o-','Color',blue, ...
    'MarkerFaceColor',blue,'MarkerSize',4,'LineWidth',1.3);
ylabel(ax(4),'Cumulative t0 vertical displacement (m)');
ax(4).YAxis(1).Color = blue;
yyaxis(ax(4),'right');
pv = errorbar(ax(4),dates,volumes/1000,volume_errors/1000,'s--', ...
    'Color',orange,'MarkerFaceColor',orange,'MarkerSize',4,'LineWidth',1.2);
ylabel(ax(4),'Cavity volume (10^{3} m^{3})');
ax(4).YAxis(2).Color = orange;
% Highlight the 24 August measurement (and its uncertainty) shown in panel c.
highlight_date = dates(snapshot_index);
highlight_volume = volumes(snapshot_index)/1000;
highlight_half_height = volume_errors(snapshot_index)/1000+0.5;
box_dates = highlight_date+days([-4 4 4 -4 -4]);
box_values = highlight_volume+highlight_half_height*[-1 -1 1 1 -1];
plot(ax(4),box_dates,box_values,'k-','LineWidth',1.2,'HandleVisibility','off');
text(ax(4),highlight_date+days(5),highlight_volume+highlight_half_height,'a, c', ...
    'Color','k','FontSize',15,'FontWeight','bold', ...
    'HorizontalAlignment','left','VerticalAlignment','bottom');
time_limits = [t0_dates(1)-days(3),dates(end)+days(5)];
xlim(ax(4),time_limits);
month_starts = dateshift(time_limits(1),'start','month'):calmonths(1): ...
    dateshift(time_limits(2),'start','month');
label_ticks = sort([month_starts,month_starts+days(14)]);
label_ticks = label_ticks(label_ticks>=time_limits(1) & label_ticks<=time_limits(2));
xticks(ax(4),label_ticks); xtickformat(ax(4),'d.MM');
ax(4).XMinorTick = 'on';
ax(4).XAxis.MinorTickValues = dateshift(time_limits(1),'start','day'):days(1): ...
    dateshift(time_limits(2),'start','day');
xtickangle(ax(4),0); grid(ax(4),'on'); box(ax(4),'on');
set(ax(4),'FontSize',axis_tick_font);
yyaxis(ax(4),'left'); ylim(ax(4),[min(t0_displacement)-0.6,0.4]);
text(ax(4),t0_dates(end)+days(2),t0_displacement(end)-0.25,'stake lost', ...
    'Color',blue,'FontSize',annotation_font, ...
    'HorizontalAlignment','left','VerticalAlignment','middle');

%% Larger axis labels, with compact spacing outside the tick numbers.
for panel = 1:4
    ax(panel).XLabel.FontSize = axis_label_font;
    ax(panel).XAxis.TickLabelGapOffset = -2;
    for side = 1:numel(ax(panel).YAxis)
        ax(panel).YAxis(side).Label.FontSize = axis_label_font;
    end
end
drawnow
% Keep large labels outside the full-coordinate tick values.
for panel = 1:3
    ax(panel).YLabel.Units = 'normalized';
    ax(panel).YLabel.Position = [-0.18 0.5 0];
end
ax(4).YAxis(1).Label.Units = 'normalized';
ax(4).YAxis(1).Label.Position = [-0.075 0.5 0];
ax(4).YAxis(2).Label.Units = 'normalized';
ax(4).YAxis(2).Label.Position = [1.055 0.5 0];

%% Glacier-location inset inside panel (a), without a basemap.
% SGI2016 is context only: do not imply it is a 2022/2023 outline.
glacier = shaperead(glacier_outline_file);
feature_xy = [positions.easting_m(positions.label=="t0"), ...
    positions.northing_m(positions.label=="t0")];
assert(size(feature_xy,1)==1,'Need one t0 position for the location inset.');
% Draw directly in panel (a)'s map coordinates: fixed lower-left placement.
xl = ax(1).XLim; yl = ax(1).YLim;
inset_box = [xl(1)+0.035*diff(xl),yl(1)+0.035*diff(yl), ...
    0.28*diff(xl),0.40*diff(yl)];
rectangle(ax(1),'Position',inset_box,'FaceColor','w', ...
    'EdgeColor',[0.25 0.25 0.25],'LineWidth',0.7);
all_x = [glacier.X]; all_y = [glacier.Y];
gx = [min(all_x,[],'omitnan'),max(all_x,[],'omitnan')];
gy = [min(all_y,[],'omitnan'),max(all_y,[],'omitnan')];
padding = 0.06*inset_box(3); header = 0.12*inset_box(4);
scale = min((inset_box(3)-2*padding)/diff(gx), ...
    (inset_box(4)-2*padding-header)/diff(gy));
offset = [inset_box(1)+(inset_box(3)-scale*diff(gx))/2, ...
    inset_box(2)+padding];
for k = 1:numel(glacier)
    glacier_polygon = polyshape((glacier(k).X-gx(1))*scale+offset(1), ...
        (glacier(k).Y-gy(1))*scale+offset(2));
    plot(ax(1),glacier_polygon,'FaceColor',[0.88 0.93 0.97], ...
        'EdgeColor',[0.25 0.25 0.25],'LineWidth',0.7);
end
marker = (feature_xy-[gx(1),gy(1)])*scale+offset;
scatter(ax(1),marker(1),marker(2),112,'r','filled','MarkerEdgeColor','w');
text(ax(1),inset_box(1)+inset_box(3)/2, ...
    inset_box(2)+inset_box(4)-0.03*inset_box(4),'Rhonegletscher', ...
    'FontSize',8.5,'HorizontalAlignment','center','VerticalAlignment','top');

% Panel identifiers only, without descriptive titles.
for panel = 1:4
    title(ax(panel),char('a'+panel-1),'FontSize',15,'FontWeight','bold');
    ax(panel).TitleHorizontalAlignment = 'left';
end

%% Export figure and plotted data; leave all original model files unchanged.
if ~isfolder(fileparts(output_png)), mkdir(fileparts(output_png)); end
exportgraphics(fig,output_png,'Resolution',300);
exportgraphics(fig,output_pdf,'ContentType','vector');
save(output_data,'dates','X','Y','cavity_height','snapshot_index','snapshot_height', ...
    'extent_outlines','raw_extent_outlines','outline_smoothing_points', ...
    'footprint_masks','volumes','volume_errors','t0_dates', ...
    't0_displacement','positions','origin','M','overview_photo','survey_photo', ...
    'overview_photo_date','survey_photo_date','collapse_photo','collapse_photo_date', ...
    'stake_map_date', ...
    'glacier_outline_file','feature_xy');
fprintf('Final measured t0 displacement: %.2f m on %s\n', ...
    t0_displacement(end),char(string(t0_dates(end),'dd.MM.yyyy')));
fprintf('Figure saved: %s\n',output_png);
