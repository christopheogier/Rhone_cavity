%% function to compute cavity geometry (roof thickness, cavity height, volume...)

function [xcav,ycav,zsurf,zcav,th,xq,yq,roof,cavity,h,v,v_err] = cavity3D(gprdata, BED,corr,inc)

%% gpr data is a text file output from gprglaz
%BED is the ditributed bed map elevation from Grab et al 2020
% corr is the height correction factor between direct bed elevation measurement and distributed bed elevation map from Grab et 2020.
%inc is the spacinf for interpolation in gridata

[prof, xcav, ycav, zsurf, zcav, th] = textread(gprdata,'%f %f %f %f %f %f','headerlines',1);
th = th-1; %correction from the height of the gpr -> not done so far!!
[xq,yq] = meshgrid(min(xcav):inc:max(xcav),min(ycav):inc:max(ycav));
roof = griddata(xcav,ycav,th,xq,yq); %roof thickness
%project GPR profile over the bedrock to get bedrock exact elevation.
n=length(xcav);%not mandatory to specify?
[d,zbed,xbed,ybed] = demprofile(BED,n,xcav,ycav);
zbed=zbed+corr;
h=zsurf-zbed-th;%cavity height:
cavity = griddata(xcav,ycav,h,xq,yq);
c = cavity(~isnan(cavity)); %c is a vector with all value of cavity height 
v = round((sum(c)*inc*inc)/10)*10; %calculate volume in m3 and round by tens

%% Uncertainty on volume (due to GPR data and bedrock uncertainties):
%the approach is very conservative: we apply the maximun std deviation for
%each profile (so the uncertainties is 100% correlated).

%the different uncertainties (in m) are:

if contains(gprdata,'20220728')
    freq=50e6;
elseif contains(gprdata,'20220811')
    freq=100e6;
elseif contains(gprdata,'20220824') || contains(gprdata,'20221007')
    freq=250e6;
else 
    error('No GPR aquisition for this date')
end
err_gpr= 0.167e9/freq/2 ; %depend of frequency, a conservative estimate consider the error to be half of the wavelength (here in ice)
err_bed=1;%due to water presence at the time of point-scale measurement
err_height = err_gpr + err_bed;
%propagation of ice thickness uncertainties on roof gridd:
cavity_max= griddata(xcav,ycav,h+err_height,xq,yq);
v_max = inc*inc*sum(cavity_max(~isnan(cavity_max))); 
v_err = round((v_max-v)/10)*10;%standard uncertainties based on the average between v_max and v_min on volume in m3 (we don't calculate v_min because this is symetric)

end