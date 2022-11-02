%Syntethic simulation of Qout at the Rhone lake. We apply a infinitely fast
%drainage of a 5000m3 water pocket (WP) at the glacier snout. The stage/discharge relationship was calculated by the student of the field 
%course in August 2022.
clear all

A_lake=313868; %m2
wp_vol=5000;%m3, from GPR measurmeent July 2022 (before lamellas collapse)
hwp=wp_vol/A_lake*100; %in cm, the lake height due to infinitely fast drainage of the WP

%% syntehetic sinusoidal-shape lake kevel 
day=24*3600; %in s
inc = 1; %time increment in s
t=[0:inc:day]; %time in hour
A=40;%amplitude: 40cm for lake elevation variation
w=2*pi/day; %angular frequency (w=2*pi/1 day) 
phi=pi/2;
h0=20; %level in cm during night
h = hlake(t,A,w,phi,h0);

%% syntehetic sinusoidal-shape Qin
day=24*3600; %in s
inc = 1; %time increment in s
t=[0:inc:day]; %time in hour
A=10;%amplitude: 10m3/s at the daily peak
w=2*pi/day; %angular frequency (w=2*pi/1 day) 
phi=pi/2;
q0=5; %level in cm during night
v_wp = 5000; %volume of the water pocket, in m3
t0 = 10*3600; %time of outburst, in s
% Qin with WP outburst infinitely fast
qin1 = q_input(t,A,w,phi,q0,t0,v_wp,1);
% Qin with WP outburst infinitely fast
qin2 = q_input(t,A,w,phi,q0,t0,v_wp,3600);
% Qin without outburst
qin_ref = q_input(t,A,w,phi,q0,t0,0,0);

%% Qout computation
qout1 = q_output(t,qin1,A);
qout2 = q_output(t,qin2,A);
qout_ref = q_output(t,qin_ref,A); %Qout without WP outburst


%% Drainage volume inferred by area between qout_ref and qout (this should be v_wp)

V = inc*trapz(qout2-qout_ref); %integration by default is with units. We multiply by inc to have a volume


%% plot

%plot Qin
figure
subplot(1,2,1);
plot(t,qin_ref)
hold on
plot(t,qin1);
hold on
plot(t,qin2);
x2 = [t, fliplr(t)];
inBetween = [qin_ref, fliplr(qin2)];
fill(x2, inBetween, 'r');
title('Lake inflow (m^{3}.s^{-1})')
xlabel('time (1 day)')
set(gca,'XTickLabel',[]);
ylabel('Q_{in} (m^{3}.s^{-1})')
xlim([0 day])
ylim([0 20]);

% plot Qout
subplot(1,2,2);
plot(t,qout_ref);
hold on;
plot(t,qout1);
hold on
plot(t,qout2);
x2 = [t, fliplr(t)];
inBetween = [qout_ref, fliplr(qout2)];
fill(x2, inBetween, 'r');
title('Lake outflow (m^{3}s^{-1})')
xlabel('time (1 day)')
set(gca,'XTickLabel',[]);
ylabel('Q_{out} (m^{3}s^{-1})')
ylim([0 50])
xlim([0 day])



%% Syntetic lake level function
function h = hlake(t,A,w,phi,h0)
%h0 (cm) is the level of lake by night
% x is time
% A is amplitude
%w is angular frequency = 2pi/day. Here t is one day
h = A/2*sin(w*t - phi)+A/2 + h0; %+A/2 vertical shift to prevent negative numbers
end

%% Syntetic Qin function (sinusoidal)
function qin = q_input(t,A,w,phi,q0,t0,v_wp,tho)
%q0 (cm) is the input discharge by night
% x is time
% A is amplitude
%w is angular frequency = 2pi/day. Here t is one day
%to is the time where the outburst occur (in s) 
%v_wp is the water pocket volume
%tho is the duration of the WP drainage, in s
qin = A/2*sin(w*t - phi)+A/2 + q0; %+A/2 vertical shift to prevent negative numbers
% we now add the outburst contribution. if tho=1 then the drainage in infinitely fast
for i = 1:length(t)
if t(i) >= t0 && t(i) < t0+tho
    qin(i)= qin(i) + v_wp/tho; % HERE the drainage in infinitively fast. We can later introduce a second sinusoid that consider a smotther drainage (with Qmax inferred by Walder and Costa (1996) empirical formula, for instance) 
end
end
end

%% Qout as a function of Qin and h

function qout = q_output(t,qin,A)
% t is the time series
% qin in the input discharge (including outburst) over t
% A is the lake area, in m2
hi = 0.2; % Initialization of lake level above spillway at t0, in m
vi = A*hi; % Initialization of lake volume at t0, in m3
dt = length(t)-t(end); % increment in time, here 1s
qout = hi/0.044; %Qout_0
% loop over time
for i = 2:length(t)
    q = hi/0.044; % linear relation ship determined by salt dilution experiment ( Qout = (z_lake-2208.98)/0.044 with z_spillwaz=2208.98)
    vi = vi + qin(i)*dt - q*dt;
    hi = vi^(1/3)/A;
    qout = [qout, q]; % increment qout
end
end



%% The lake stage/discharge relationship is as follow: 
% Qout = (z_lake-2208.98)/0.044
function qout = qlake(h)
%dh is the lake surface height in cm above the spillway (z_spillwaz=2208.98)
qout = h/100/0.044;  %h is in cm

%here a dh/dt term is missing. This would refer to the buffering role of
%the lake (or the "lag"). As it is now, there is no dependance on the discharge to the
%speed of lake level decay. Normaly the fastest the lake level comes back
%to normal, the higher the discharge peak (volume conservation). I need a
%term for volume conservation. -> key work = flood routing hydrology

end

%% exponential decay of lake level after the cavity outburst
function h_burst = hlake_burst(h_lake,t,t0,tho,delta_h)
% h_lake is the lake level time serie
% t is the time series
% t0 is the time when the cavity outburst start
% tho is half life time  (i.e. the time required for a quantity to reduce to half of
%its initial value)
% delta_h is the lake level variation to consider, here delta_h = hwp calculated above
h_burst = h_lake; % h_burst is identical to h_lake at the beginning
for i = 1:length(t)
    if t(i) >= t0
        h_burst(i) = h_lake(i) + + delta_h*exp(-(t(i)-t0)/tho); %%here volume-disharge need to be implemented
        

        % update volume = v + (qin-qout)*delta t %qin if outburst is over a time frame
    end
end

end
