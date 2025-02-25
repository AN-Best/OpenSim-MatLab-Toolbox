function L = P_FindLegLength(TrialData,HipNames,HeelName,VT)
%This function find the leg length of a subject as the vertical distance
%the heel to the hip joint center for the right leg
%Requires the markers to be extracted using P1_QTMmatDataExtract
%Hip joint centre is found using the equation in Chapter 2 of Research
%Methods in Biomechanics 2nd Edition by Gordon Robertson et al. (pg 40)

%   TrialData = structure for a static trial containing marker data
%   HipNames = 1x4 array with the names of the hip markers, order is RASIS,
%   LASIS, RPSIS, LPSIS
%   HeelName = name of the heel marker
%   VT = number from 1-3 identidying which axis is the vertical axis

%Originally Written By: Aaron N. Best (Aug 2023)
%Update Record:

%% Pull out and average marker locations

RASIS = mean(TrialData.MarkerData.Trajectories.(HipNames(1)));
LASIS = mean(TrialData.MarkerData.Trajectories.(HipNames(2)));
RPSIS = mean(TrialData.MarkerData.Trajectories.(HipNames(3)));
LPSIS = mean(TrialData.MarkerData.Trajectories.(HipNames(4)));

RH = mean(TrialData.MarkerData.Trajectories.(HeelName));

%% Create Local Coordinate System for the Pelvis

O = 0.5*(RASIS + LASIS);

x = RASIS - O;
v = O - 0.5*(RPSIS + LPSIS);
z = cross(x,v);
y = cross(z,x);

x = x./norm(x);
y = y./norm(y);
z = z./norm(z);

T = [x' y' z' O';0 0 0 1];

%% Determine the location of the HJC in the local coordinate system

HJC_local = [0.36*norm(RASIS-LASIS);...
            -0.19*norm(RASIS-LASIS);...
            -0.30*norm(RASIS-LASIS)];

%% Tranform into the global coordinate system

HJC_global = T*[HJC_local;1];
HJC_global = HJC_global(1:3,1)';

% figure;
% hold on;
% axis equal;
% 
% plot3(RASIS(1),RASIS(2),RASIS(3),'.r');
% plot3(LASIS(1),LASIS(2),LASIS(3),'.r');
% plot3(RPSIS(1),RPSIS(2),RPSIS(3),'.r');
% plot3(LPSIS(1),LPSIS(2),LASIS(3),'.r');
% 
% plot3(RH(1),RH(2),RH(3),'.r');
% 
% plot3(HJC_global(1),HJC_global(2),HJC_global(3),'.g');
% hold off;

%% Calculate the leg length

L = HJC_global(1,VT) - RH(1,VT);


end