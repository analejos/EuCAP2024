
clear all; close all; clc

%--- shift 0º - MLOG + UPH -- by Planar NF
M = 200;
fich = 's21_planar_10.s1p';
aux = load(fich);

%--- shift 0º - MLOG -- by Spherial FF
fich0 = 'shift_m10_SFF.s1p';
a0 = load(fich0);
S21mag_1 = a0;    
S21norm_1 = S21mag_1-max(S21mag_1); 

%-- common variables
freq = 27.5e9;
grad = linspace(-90,90,200);

%-- complex measured fields
% complex_ex = 10.^(aux(:,1)/20).*exp(1i.*deg2rad(aux(:,2)));
complex_ex = 10.^(aux(:,1)/20).*exp(1i.*unwrap(deg2rad(aux(:,2))));

z0 = 0.06;      %Scanned plane in m for AUT
dxy = 1e-3;     %Sampling spacing set by Nyquist sampling criteria in m
a = 0.2;        %Length of scanned area in x dir in m
b = 0;          %Length of scanned area in y dir in m

M = round(a/dxy)    % Amount of samples in x dir
MI = 1*M;           % to increase resolution of the plane wave, in case
                    % of low M; use with zero padding in complex_ex
mi = -MI/2:1:MI/2-1;

% Scanning axes
x=[-a/2:a/(MI-1):a/2];
y=[-b/2:b/(MI-1):b/2];

% Wave numbers definition (in m^-1)
freq = 27.5e9;
c=3e8;
lambda = c/27.5e9;
k = 2*pi/lambda;
kx = 2*pi*mi/(MI*dxy);
ky = 2*pi*mi/(MI*dxy);
kz = sqrt(k^2-(kx.^2+ky.^2)); 

%Obtain plane wave spectrum functions
%IFFT
A_x = fftshift(ifft(ifftshift(complex_ex)));

%Plots
figure
plot(kx,20*log10(abs(A_x)))
xlim([min(kx) max(kx)])
title('|A_{x}|')
xlabel('k_{x} [m^{-1}]')
ylabel('dB')
shading flat
grid on
hidden off

% Far Field obtention
phi = atan(kx);
theta = acos(kz/k);

sp = sin(phi);
cp = cos(phi);
ct = cos(theta);

E_theta = A_x.*cp;% + A_y.*sp;
E_phi = A_x'.*ct.*sp;% + A_y.*ct.*cp;
E_cop = E_theta'.*sp + E_phi.*cp; 
E_cross = E_theta'.*cp - E_phi.*sp;
Ecopmax = max(max(E_cop));
E_cop_norm = E_cop/Ecopmax;
E_cross_norm = E_cross/Ecopmax;

%Cut phi=90 YZ-Plane (E-PLANE) respectively      
phi90 = pi/2-pi/180;
theta = -pi/2:(pi/(MI-1)):pi/2; %variable

sp = sin(phi90);
cp = cos(phi90);
ct = cos(theta);

E_theta_90 = A_x.*cp;% + A_y.*sp;
E_phi_90 = A_x'.*ct.*sp;% + A_y.*ct.*cp;
E_cop_90 = E_theta_90'.*sp + E_phi_90.*cp; 
E_cross_90 = E_theta_90'.*cp - E_phi_90.*sp;
Ecop_90_max = max(max(E_cop_90));
E_cop_90_norm = E_cop_90./Ecop_90_max;
E_cross_90_norm = E_cross_90./Ecop_90_max;

%-- artificial axis in degree; goal: to expand the resulting E fields;
%-- alternative: interpolate kx and recalculate Ax and fields
%-- (oversampling)
grad2 = linspace(-360,360,200);

s21_ff = E_cop_90;

figure();
plot(linspace(-90,90,181),S21norm_1,'linewidth',3);
hold on
plot(grad2,20.*log10(abs(s21_ff))-max(20.*log10(abs(s21_ff))),'linewidth',3);
grid on
xlabel('\theta (°))');
ylabel('dB');
ylim([-50,0]);
xlim([-100,100]);

xline(-73,'b-.','-\alpha_c','linewidth',2,'LabelHorizontalAlignment','left','LabelOrientation','horizontal');
xline(73,'b-.','\alpha_c','linewidth',2,'LabelHorizontalAlignment','right','LabelOrientation','horizontal');
legend('E-plane by SFF','E-plane by Planar NF');
