
%% Program setup
clear
clc
close all
start_time=tic; %Timer

%% Setup
%Declare global variables needed in EoM.m code
global cdo_wpn
global clo_wpn
global cmo_wpn
global cmqao_wpn
global cd2_wpn
global cl2_wpn
global cm2_wpn
global cmqa2_wpn
global std_atm
global d
global It
global m
global R

%Declare global variables needed in EoM.m code.
global gravity
gravity=9.81; %gravity in metric units (m/s^2)

%Standard Measurements
R=6371220; %Radius of earth in meters

%read standard atmosphere tables
std_atm=readmatrix('std_atm.csv','Range','A2:k43');
    
%Weapon charicteristics - These are the properties of the submunissions.
%These weapons charicteristics are from McCoy, 1998.  See citation above.
d=119.56/1000; %diameter in m
Ip=0.02335; %Axial moment of inertia kg*m^2
It=0.23187; %Transverse moment of inertia kg*m^2
m=13.585; %mass in kg

%Read subminition charicteristics from excel file.  %These weapon 
%charicteristics are from McCoy, 1998.  See citation above.  
cdo_wpn=xlsread('Aerodynamic_Char_120mm_Mortar.xlsx','A5:B11');
cd2_wpn=xlsread('Aerodynamic_Char_120mm_Mortar.xlsx','A15:B22');
clo_wpn=xlsread('Aerodynamic_Char_120mm_Mortar.xlsx','A26:B30');
cl2_wpn=xlsread('Aerodynamic_Char_120mm_Mortar.xlsx','A34:B41');
cmo_wpn=xlsread('Aerodynamic_Char_120mm_Mortar.xlsx','A45:B51');
cm2_wpn=xlsread('Aerodynamic_Char_120mm_Mortar.xlsx','A55:B63');
cmqao_wpn=xlsread('Aerodynamic_Char_120mm_Mortar.xlsx','A67:B72');
cmqa2_wpn=xlsread('Aerodynamic_Char_120mm_Mortar.xlsx','A76:B83');


%% Intial conditions
Vo_set = 100; %initial vel at muzzle exit in m/s
phi_0_set = 45; %vertical angle of departure in deg (pos up)
theta_0_set = 10;  %horizontal angle of departure in deg(pos to right)

w_z0_set=0; %initial pitch rate in rad/s (pos nose up)
w_y0_set=0; %initial transverse yaw rate in rad/s (pos for left yaw)

alpha_0_set = -5; %Pitch angle at muzzle exit in deg
beta_0_set= 10; %initial yaw angle at muzzle exit in deg

%initial position of munition center of gravity (CG) wrt intertial frame
x_0 = 0; % x-axis (m) - range direction
y_0 = 0; % y-axis (m) - altitude
z_0 = 0; % z-axis (m) - cross-range direction



%% Run program
% Read and set initial conditions
t_max = 300; %max time in seconds

Vo = Vo_set; %initial vel at muzzle exit in m/s
phi_0 = phi_0_set; %vertical angle of departure in deg (pos up)
theta_0 = theta_0_set; %horizontal angle of departure in deg(pos to right)

w_z0 = w_z0_set; %initial pitch rate in rad/s (pos nose up)
w_y0 = w_y0_set; %initial transverse yaw rate in rad/s (pos for left yaw)

alpha_0 = alpha_0_set; %Pitch angle at muzzle exit in deg
beta_0 = beta_0_set; %initial yaw angle at muzzle exit in deg

p = 0; %initial spin rate in rad/s

%% Intermediate Calcs
%Calculate initial orientation of x-vector (vector along primary
%axis).  This is the orientation of the body fame relative to the
%inertial frame.
X1o=cosd(phi_0+alpha_0)*cosd(theta_0+beta_0);
X2o=sind(phi_0+alpha_0)*cosd(theta_0+beta_0);
X3o=sind(theta_0+beta_0);

%Caclulate initial rate of change of x-vector.  This is the initial
%velocity in each x,y,and z direction.  The Q variable is an
%intermediate variable.
Q=((sind(theta_0+beta_0))^2)+((cosd(theta_0+beta_0))^2)*...
    ((cosd(phi_0+alpha_0))^2);
dx_1o=(1/sqrt(Q))*(-w_z0*((cosd(theta_0+beta_0))^2)*...
    sind(phi_0+alpha_0)*cosd(phi_0+alpha_0)+w_y0*...
    sind(theta_0+beta_0));
dx_2o=(1/sqrt(Q))*(w_z0*((cosd(theta_0+beta_0))^2)*...
    ((cosd(phi_0+alpha_0))^2)+w_z0*((sind(theta_0+beta_0))^2));
dx_3o=(1/sqrt(Q))*((-w_z0*sind(theta_0+beta_0)*...
    cosd(theta_0+beta_0)*sind(phi_0+alpha_0))-...
    (w_y0*cosd(theta_0+beta_0)*cosd(phi_0+alpha_0)));

%Equations of motion:
%x(1) = x-velocity with respect (wrt) intertial frame (m/s).
%x(2) = y-velocity wrt intertial frame (m/s).
%x(3) = z-velocity wrt intertial frame (m/s).
%x(4) = roll rate wrt intertial frame (rad/s).
%x(5) = pitch rate wrt intertial frame (m/s).
%x(6) = yaw rate wrt intertial frame (m/s).
%x(7) = x component of projectile unit vector wrt intertial frame
%x(8) = y component of projectile unit vector wrt intertial frame
%x(9) = z component of projectile unit vector wrt intertial frame
%x(10) = position of munition center of gravity (CG) wrt intertial
    %frame x-axis (m).  This is the range.
%x(11) = position of munition CG wrt intertial frame y-axis (m). This is 
    %the altitude.
%x(12) = position of munition CG wrt intertial frame z-axis (m). This is 
    %the cross-range.

%Set initial velocities
x0(1)=Vo*cosd(phi_0)*cosd(theta_0);
x0(2)=Vo*sind(phi_0)*cosd(theta_0);
x0(3)=Vo*sind(theta_0);

%Set initial angular rates
x0(4)=((Ip*p)/It)*X1o+X2o*dx_3o-X3o*dx_2o;
x0(5)=((Ip*p)/It)*X2o+X1o*dx_3o+X3o*dx_1o;
x0(6)=((Ip*p)/It)*X3o+X1o*dx_2o+X2o*dx_1o;

%Set initial orientation pointing vector
x0(7)=X1o;
x0(8)=X2o;
x0(9)=X3o;

%Set initial position
x0(10)=x_0; % initial position in range direction (m)
x0(11)=y_0; % intial position in altitude (m)
x0(12)=z_0; % initial position in cross-range direction (m)

%Run the ODE solver to propigate the submunissions through the air.
%Evaluate system of differential equations.
tspan=[0 t_max]; %Time span of simulation in sec
Opt = odeset('Events', @myEvent);
[t,x]=ode45(@EoM,tspan,x0,Opt); %Run the ODE solver

%Calcualte orientation angles
alpha=acosd(x(:,2)./((x(:,1).^2+x(:,2).^2+x(:,3).^2).^0.5));
beta=acosd(x(:,3)./((x(:,1).^2+x(:,2).^2+x(:,3).^2).^0.5));
%Angle1 is the angle of the munition in the x-y plane.
%Angle 2 is the angle in x-z plane.
angle1=atand(x(:,2)./x(:,1));
angle2=atand(x(:,3)./x(:,1));

%Find the appogee of the munition's flight.
[max_ht,I]=max(x(:,11));

%Find the time of impact by interpolating the time when the altitude is 
%zero (after appogee) 
impact_time=interp1(x(I:end,11),t(I:end),0);

%Find the range when the munitions impacts.(distance along
%interial frame x-axis when the munition impacts the ground)
range=interp1(x(I:end,11),x(I:end,10),0);

%Find the crossrange when the munitions impacts.  (distance
%along interial frame z-axis when the munition impacts the ground)
cross_range=interp1(x(I:end,11),x(I:end,12),0);

%Determine the orientation of the munition. Find 3D vector of impact
%direction and use dot product with vertical vector. First, find alpha and
%beta angles at impact. Alpha is angle of munition in x-y plane (vertical
%plane) and beta is the angle of the munition in the x-z plane (horizontal
%or ground plane).
impact_alpha = interp1(x(I:end,11),alpha(I:end),0);
impact_beta = interp1(x(I:end,11),beta(I:end),0);

%Create 3D vector of impact direction
impactVect_x_coord = cos(impact_beta)*cos(impact_alpha);
impactVect_y_coord = sin(impact_beta)*cos(impact_alpha);
impactVect_z_coord = sin(impact_alpha);
impactVect = [impactVect_x_coord, impactVect_y_coord, impactVect_z_coord];

vert = [0,1,0]; %vertical vector pointing down

%Find total 3D impact angle in degrees using dot product
impact_angle = acosd(dot(vert,impactVect));

%Find the impact valocity in all three axises and then
%combine to get total impact velocity.
vel_x_imp=interp1(x(I:end,11),x(I:end,1),0);
vel_y_imp=interp1(x(I:end,11),x(I:end,2),0);
vel_z_imp=interp1(x(I:end,11),x(I:end,3),0);
impact_vel=sqrt(vel_x_imp^2+vel_y_imp^2+vel_z_imp^2);

%Total distance vector along the x-z plane (ground plane). This takes
%into account distance in the range (x-direction) and cross-range
%(z-direction).
total_dis = sqrt(x(:,10).^2 + x(:,12).^2);

%Plots
figure()
subplot(1,3,1)
plot3(x(1:end,10),x(1:end,12),x(1:end,11))
grid on
xlabel('range (m)')
ylabel('cross-range (m)')
zlabel('altitude (m)')
axis tight

subplot(1,3,2)
plot(total_dis(1:end),x(1:end,11))
grid on
xlabel('total distance (m)')
ylabel('altitude (m)')

subplot(1,3,3)
plot(x(1:end,10),x(1:end,12))
grid on
xlabel('range (m)')
ylabel('cross-range(m)')

%% Termination function for ODE. 
%Terminate when altitude is less than 0 meaning that the munition impacted
%the ground.
function [value, isterminal, direction] = myEvent(t, y)
    value      = (y(11) < 0);
    isterminal = 1;   % Stop the integration
    direction  = 0;
end

    
    