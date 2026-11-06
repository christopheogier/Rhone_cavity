# Rhone subglacial cavity — 2022 surveys

This folder contains the original Grab et al. bed raster, four dated 3D cavity-height plots, and `cavity_geometry.mat` for 28 July, 11 August, 24 August and 7 October 2022. Each plot also records its generation date. The four plots use common spatial, height and colour limits.

## Files and use

- `B43-03_GlacierBed.tif`: original bed raster, copied without modification. The model adds **7 m** to sampled bed elevations; this correction is not applied to the TIFF itself.
- `YYYYMMDD_cavity_3D.png`: interpolated cavity height above the corrected local bed, in metres. The plotted vertical coordinate is cavity height, not absolute elevation.
- `cavity_geometry.mat`: load in MATLAB with `load('cavity_geometry.mat')`. Contains `geometry(1:4)` and `metadata`.

For each survey, `geometry` contains:

| Field | Meaning |
| --- | --- |
| `date` | Acquisition date |
| `easting_m`, `northing_m` | Matching 2D mesh coordinate arrays, Swiss LV95 / CH1903+ (EPSG:2056) |
| `height_above_bedrock_m` | Cavity height, in metres |
| `bed_elevation_m` | Interpolated corrected bed elevation, in metres |
| `cavity_roof_elevation_m` | Bed elevation + cavity height; upper cavity surface |
| `ice_roof_thickness_m` | Interpolated ice thickness above the cavity |
| `valid` | Mask of finite cavity heights; NaN outside the interpolated survey footprint |
| `volume_m3`, `volume_uncertainty_m3` | Original code's rounded volume and conservative uncertainty |

For example:

```matlab
load('cavity_geometry.mat');
g = geometry(1);
surf(g.easting_m,g.northing_m,g.cavity_roof_elevation_m);
hold on;
surf(g.easting_m,g.northing_m,g.bed_elevation_m);
```

The arrays describe gridded upper and lower surfaces, not a closed triangular solid. Verify the source vertical datum before combining elevations with other products; no vertical datum conversion was performed.

## Method and limitations

Produced by `cavity_plot.m` and the unchanged `cavity3D.m` in the Rhone_cavity repository. Inputs are GPR picking text files under `data/Rhone/GPR` and the bed raster under `data/Rhone/bed`.

The original method uses a 0.5 m grid, linear `griddata` interpolation, a 1 m GPR antenna-height correction to picked thickness, and a +7 m bed correction. The original comments mention 10 m, but the executable parameter is 7 m and was preserved. Bed surfaces here interpolate the same corrected bed samples used by the cavity-height calculation. Roof elevation is constructed as bed + height, preserving that calculation; it is not the raw picked `zcav` elevation.

Duplicate pick coordinates are averaged by MATLAB interpolation. NaNs are retained and heights are not clipped to zero. Volume and uncertainty follow the original code, including its correlated-error assumptions and rounding to tens of cubic metres. These are model outputs, not independently validated measurements. Orthophoto and stake-subsidence data were unavailable and are not needed for this handoff.
