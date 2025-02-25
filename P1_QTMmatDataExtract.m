function TrialData = P1_QTMmatDataExtract(matfile,marker_import,force_import,analog_import)
%Converts the .mat files from QTM to .trc for OpenSim
%   matfile = matfile directly exported from qtm
%   marker_import = binary flag to import marker data
%   force_import = binary flag to import force data
%   analog_import = binary flaf to import analog data


%Originally Written By: Aaron N. Best (Apr 2023)
%Update Record:

%% Pull out the data collection info from the file

original_path = convertCharsToStrings(matfile.File);
original_path = split(original_path,'\');

filename = original_path(end,1);
filename = erase(filename,".qtm");

TrialData.CollectionName = filename;

%% Import Marker Data

if marker_import == 1
    labels = matfile.Trajectories.Labeled.Labels;
    for i = 1:length(labels)
        TrialData.MarkerData.Trajectories.(labels{i}) = squeeze(matfile.Trajectories.Labeled.Data(i,1:3,:)./1000)';
    end
    TrialData.MarkerData.FrameRate = matfile.FrameRate;
    TrialData.MarkerData.Frames = matfile.Frames;
end

%% Import Force Data

if force_import == 1
    NforcePlates = size(matfile.Force);
    NforcePlates = NforcePlates(1,2);

    for i = 1:NforcePlates
        plate = strcat('Plate',num2str(i));
        
        TrialData.ForceData.(plate).PlateName = matfile.Force(i).ForcePlateName;
        TrialData.ForceData.(plate).FrameRate = matfile.Force(i).Frequency;
        TrialData.ForceData.(plate).Frames = matfile.Force(i).NrOfSamples;
        TrialData.ForceData.(plate).PlateCorners = matfile.Force(i).ForcePlateLocation./1000;
        TrialData.ForceData.(plate).Force = matfile.Force(i).Force';
        TrialData.ForceData.(plate).Moment = matfile.Force(i).Moment';
        TrialData.ForceData.(plate).CoP = matfile.Force(i).COP';
    end
end

%% Import Analog Data

if analog_import == 1
    TrialData.AnalogData.Labels = matfile.Analog.Labels;
    TrialData.AnalogData.FrameRate = matfile.Analog.Frequency;
    TrialData.AnalogData.Frames = matfile.Analog.NrOfFrames;
    TrialData.AnalogData.Data = matfile.Analog.Data';
end




end