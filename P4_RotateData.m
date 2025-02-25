function TrialData = P4_RotateData(TrialData,rotdata,marker_flag,force_flag)
%This function rotates the coordinate system of the marker and force data
%   TrialData = structure with force and moment data
%   rotdata = rotation order for going into opensim (order = [AP VT ML],
%   for the HMRL and Selinger treadmills use [3 1 2], default is [1 2 3])
%   marker_flag = binary switch to rotate marker data
%   force_flag = binary switch to rotate force data

%Originally Written By: Aaron N. Best (Apr 2023)
%Update Record:

%% Rotate Marker Data

if marker_flag == 1
    labels = fieldnames(TrialData.MarkerData.Trajectories);
    frames = TrialData.MarkerData.Frames;
    for i = 1:length(labels)
        tempF = NaN(frames,3);
        for j = 1:3
            tempF(:,rotdata(j)) = TrialData.MarkerData.Trajectories.(labels{i})(:,j);
        end
        TrialData.MarkerData.Trajectories.(labels{i}) = tempF;
    end
end

%% Rotate the force data

if force_flag == 1
    plates = fieldnames(TrialData.ForceData);
    for i = 1:length(plates)
        frames = TrialData.ForceData.(plates{i}).Frames;
        tempF = NaN(frames,3);
        tempM = NaN(frames,3);
        tempC = NaN(frames,3);
        tempCorn = NaN(4,3);
        for j = 1:3
            tempF(:,rotdata(j)) = TrialData.ForceData.(plates{i}).Force(:,j);
            tempM(:,rotdata(j)) = TrialData.ForceData.(plates{i}).Moment(:,j);
            tempC(:,rotdata(j)) = TrialData.ForceData.(plates{i}).CoP(:,j);
            tempCorn(:,rotdata(j)) = TrialData.ForceData.(plates{i}).PlateCorners(:,j);
        end
        TrialData.ForceData.(plates{i}).Force = tempF;
        TrialData.ForceData.(plates{i}).Moment = tempM;
        TrialData.ForceData.(plates{i}).CoP = tempC;
        TrialData.ForceData.(plates{i}).PlateCorners = tempCorn;
    end
end

%% Rotate the CS if necessary

if isfield(TrialData,'GroundPlane')

    T = TrialData.GroundPlane;
    O = TrialData.GroundPlane(1:3,4);
    T_new = NaN(4,4);
    for i = 1:3
        T_new(:,i) = T(:,rotdata(i));
        T_new(i,4) = O(rotdata(i),1);
    end
    T_new(4,4) = 1;

    TrialData.GroundPlane = T_new;
end