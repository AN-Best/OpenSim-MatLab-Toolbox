function TrialData = FixTrunkAngles(TrialData)
%This is a bad code to fix te trunk angles when a subject is walking
%downhill (i.e. facing backwards on the treadmill) OpenSim glitches at
%angle greater than 180 or less than -180, this code is to flip the
%transform to pretend that the trunk is facing forwards, try to avoid using
%this code and only use it for backwards trials
%   TrialData = data structure with the outputted trunk angle from the
%   analyze tool

%% Initiate a for loop to run through each frame

for i = 1:length(TrialData.Analyze.Position.time)

%% Reconstruct the rotation matrix of the trunk from the euler angles
%Note this is using body-fixed X-Y-Z tranformation

Ox = (pi/180)*TrialData.Analyze.Position.torso_Ox(i,1);
Oy = (pi/180)*TrialData.Analyze.Position.torso_Oy(i,1);
Oz = (pi/180)*TrialData.Analyze.Position.torso_Oz(i,1);

eul = [Ox Oy Oz];

Rtrunk = eul2rotm(eul,"XYZ");

%% Flip 180 deg about global y

R_180y = [-1 0 0;...
        0 1 0;...
        0 0 -1];

Rflip = (R_180y^-1)*Rtrunk;

%% Decompose back into euler angles

eul = rotm2eul(Rflip,'XYZ');


TrialData.Analyze.Position.torso_Ox(i,1) = (180/pi)*eul(1);
TrialData.Analyze.Position.torso_Oy(i,1) = (180/pi)*eul(2);
TrialData.Analyze.Position.torso_Oz(i,1) = (180/pi)*eul(3);
end