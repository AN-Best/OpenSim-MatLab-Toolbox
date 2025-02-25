function TrialData = O3_RunIK(TrialData,OSFolder,OSIMmodel,Setting)
%This function runs inverse kinematics using opensim and adds the
%data to the TrialData structure
%   TrialData = Trial data structure to save the results to
%   OSFolder = folder where all the opensim data is saved
%   Model = name of the .osim file for the scaled walking model
%   Setting = generic settings for running IK in opensim

%Originally Written By: Aaron N. Best (Apr 2023)
%Update Record:

%% Access OpenSim

import org.opensim.modeling.*

%% Import and setup the model data

%Bring in IK tool
ikTool = InverseKinematicsTool(convertStringsToChars(strcat(OSFolder,'\',Setting)));

%Grab the model
model = Model(fullfile(convertStringsToChars(OSFolder),OSIMmodel));
model.initSystem();

%Add model to IK tool
ikTool.setModel(model);

%Bring in the marker data
trialname = TrialData.CollectionName;

markerData = MarkerData(convertStringsToChars(strcat(OSFolder,'\',trialname,'.trc')));
%% Setup the IK tool for the trial

initial_time = markerData.getStartFrameTime();
final_time = markerData.getLastFrameTime();

ikTool.setName(trialname);
ikTool.setMarkerDataFileName(convertStringsToChars(strcat(OSFolder,'\',trialname,'.trc')));
ikTool.setStartTime(initial_time);
ikTool.setEndTime(final_time);
ikTool.setOutputMotionFileName(convertStringsToChars(strcat(OSFolder,'\',trialname,'_IK.mot')));
ikTool.print(convertStringsToChars(strcat(OSFolder,'\','Setup_IK_',trialname,'.xml')));

%% Call and run the IK tool

fprintf('Beginning IK on %s\n',trialname);
ikTool.run();
fprintf('Finished IK on %s\n',trialname);

%% Save the marker error and move the marker error file to the OSFolder

errorfile = strcat(trialname,'_ik_marker_errors.sto');

errorID = fopen(convertStringsToChars(errorfile));
%Pull out the information header info from the file
HeaderRow = [];
for i = 1:20
    tline = fgetl(errorID);
    if strfind(tline,'time') == 1 %headers line
        HeaderRow = i;
    end
    if ~isempty(HeaderRow)
        break
    end
end

errorheaders = strsplit(tline,'\t');
errordata = dlmread(convertStringsToChars(errorfile),...
    '\t',HeaderRow+1,0);

for i = 1:length(errorheaders)
    TrialData.InverseKinematics.Error.(errorheaders{i}) = errordata(:,i);
end

fclose(errorID);

%Move the file
[status,message] = movefile(errorfile,OSFolder);

if status == 0
    warning("Marker marker error file could not be moved.");
end

%% Open up the IK file and Bring in the Required Information

fileID = fopen(convertStringsToChars(strcat(OSFolder,'\',trialname,'_IK.mot')));
%Pull out the information header info from the file
HeaderRow = [];
for i = 1:20
    tline = fgetl(fileID);
    if strfind(tline,'nRows') == 1 %nRows line
        nRows = str2double(erase(tline,'nRows'));
    elseif strfind(tline,'nColumns') == 1 %nColumns line
        nColumns = str2double(erase(tline,'nColumns'));
    elseif strfind(tline,'time') == 1 %headers line
        HeaderRow = i;
    end
    if ~isempty(HeaderRow)
        break
    end
end

if isempty(HeaderRow)
    error('Headers not found');
end

AngData = dlmread(convertStringsToChars(strcat(OSFolder,'\',trialname,'_IK.mot')),...
    '\t',HeaderRow,0);
headers = strsplit(tline,'\t');

for i = 1:length(headers)
    TrialData.InverseKinematics.(headers{i}) = AngData(:,i);
end

fclose(fileID);

end