# Rhone subglacial cavity

These are unpublished data presented in Hosli et al., 2025. Subglacial cavity collapses on Swiss glaciers: Spatiotemporal distribution and mass loss contribution. Journal of Glaciology.

GPR acquisition dates over the cavity: 28.07.2022, 11.08.2022, 24.08.2022 and 07.10.2022.

Run `cavity_plot.m` in MATLAB. Outputs are saved in `/scratch-3/cogier/data/Rhone/cavity/`(change path). 

- `results/cavity_model.mat` (repository copy): grids, picks, cavity heights, roof thicknesses and volumes for all four surveys.
- `plot/cavity_height_3D.png`: four 3D views of height above bedrock.
- `plot/cavity_height_maps.png`: four height maps viewed from above.
- `plot/roof_thickness_maps.png`: four ice-roof thickness maps.

Coordinates are Swiss LV95; lengths are in metres. The model uses a 0.5 m grid and a +7 m bed correction to match borehole measurements.

GPR data are found in S:\glazio\projects\88018-VAW_Rhone_collapse_feature\03_data\9_GPR. Bedrock elevation map is found in Grab et al., 2021. 



## MAT-file variables

Suffixes `1`–`4` refer to 28.07.2022, 11.08.2022, 24.08.2022 and 07.10.2022, respectively.

- `xq*`, `yq*`: grid coordinates; `cavity*`: height above bedrock; `roof*`: ice-roof thickness (all in metres).
- `roof_elev{1:4}`: interpolated picked cavity-roof elevations.
- `xcav*`, `ycav*`, `zsurf*`, `zcav*`: pick coordinates and surface/cavity-roof elevations; `th*`, `h*`: corrected thickness and cavity height at picks.
- `v*`, `v_err*`: volume and uncertainty (m³). `survey_dates`, `inc` and `corr`: dates, grid spacing and bed correction.

Example: `load('results/cavity_model.mat'); surf(xq1,yq1,cavity1)` plots the first survey's cavity height.
