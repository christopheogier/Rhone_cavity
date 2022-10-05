%Syntethic simulation of Qout at the Rhone lake. We apply a infinitely fast
%drainage of a 5000m3 water pocket (WP) at the glacier snout. The stage/discharge relationship was calculated by the student of the field 
%course in August 2022.

A_lake=313868; %m2
wp_vol=5000;%m3, from GPR measurmeent July 2022 (before lamellas collapse)
hwp=wp_vol/A_lake*100; %in cm, the lake height due to infinitely fast drainage of the WP

%% syntehetic sinusoidal-shape lake kevel 
x=[0:0.1:2*pi]; %time in hour
A=40;%amplitude: 40cm for lake elevation variation
w=1; %angular frequency (w=2*pi/1 day) -> 1h = 0.26
phi=pi/2;
h = hlake(x,A,w,phi);

%% I HAVE TO IMPLEMENT REAL NIGHT Q PLATEAU. because it matters to compare discharge with real setting (14m/s instead of just 9 for instance).



%% synthetic disharge from synthetic lake level
qout_ref = qlake(h);

%% plot
%plot lake level
figure
subplot(1,2,1);
plot(x,h);
title('Lake level (cm)')
xlabel('time (1 day)')
set(gca,'XTickLabel',[]);
ylabel('lake height above spillway (cm)')
xa=2;%x location to plot the dirac from WP outburst
line([xa xa],[hlake(xa,A,w,phi) hlake(xa,A,w,phi)+hwp],'Color','r','LineWidth',1);
text(xa,hlake(xa,A,w,phi)-hwp,'WP outburst','Color','r');
ylim([0 70]);

%plot lake discharge
subplot(1,2,2);
plot(x,qout_ref);
title('Lake discharge (m^{3}s^{-1})')
xlabel('time (1 day)')
set(gca,'XTickLabel',[]);
ylabel('lake outflow discharge (m^{3}s^{-1})')
ylim([0 14])
%rectangle('Position',[3 4 0.36 1],'FaceColor','r'); %units= 1m3/s x 1.38h (=>1.38*2pi/24=0.36)
%text(3,3.5,'WP volume','Color','r');

%% Syntetic lake level function
function h = hlake(x,A,w,phi)
h_night=20; %in cm, level of lake by night
% x is time
% A is amplitude
%w is angular frequency = 2pi/t. Here t is one day
h = A/2*sin(w*x - phi)+A/2 + h_night; %+A/2 vertical shift to prevent negative numbers
end

%% The lake stage/discharge relationship is as follow: 
% Qout = (z_lake-2208.98)/0.044
function qout = qlake(h)
%dh is the lake surface height in cm above the spillway (z_spillwaz=2208.98)
qout = h/100/0.044;
end

