function TrialData = O4_RunAnalyze(TrialData,OSFolder,Setting,Model)
%This function runs the analyze tool in OpenSim and adds the data to the
%TrialData structure, note that this only works for adding the
%BodyKinematics option for the Analyze Tool, you also must have previously
%run IK on the trial
%   TrialData = trial data structure for saving the data
%   OSFolder = opensim folder where the data is saved
%   Setting = generic settings from opensim for the analyze tool

%Originally Written By: Aaron N. Best (Apr 2023)
%Update Record:

%% Access OpenSim
import org.opensim.modeling.*

%% Import the Analyze Settings
xmlSet = xmlread(fullfile(OSFolder,Setting));

%% Setup attributed of the .xml

trialname = TrialData.CollectionName;

modelfile = convertStringsToChars(strcat(OSFolder,'/',Model));
IKfile = convertStringsToChars(strcat(OSFolder,'/',trialname,'_IK.mot'));

xmlSet.getElementsByTagName('AnalyzeTool').item(0).setAttribute('name',trialname);
xmlSet.getElementsByTagName('model_file').item(0).setTextContent(modelfile);
xmlSet.getElementsByTagName('coordinates_file').item(0).setTextContent(IKfile);

xmlwrite(fullfile(OSFolder,Setting),xmlSet);

%% Bring in the analyze tool

anTool = AnalyzeTool(fullfile(OSFolder,Setting));
anTool.setResultsDir(convertStringsToChars(OSFolder));
anTool.setInitialTime(TrialData.InverseKinematics.time(1,1));
anTool.setFinalTime(TrialData.InverseKinematics.time(end,1));
anTool.print(convertStringsToChars(strcat(OSFolder,'\','Setup_Analyze_',trialname,'.xml')));

%% Run the analyze tool

fprintf('Starting Analyze tool for %s \n',trialname);
anTool.run();
fprintf('Finished Analyze tool for %s \n',trialname);

%% Pull in the data from the saved .sto

%Position
posfile = strcat(OSFolder,'\',trialname,'_BodyKinematics_pos_global.sto');
posID = fopen(convertStringsToChars(posfile));

HeaderRow = [];
for i = 1:30
    tline = fgetl(posID);
    if strfind(tline,'time') == 1
        HeaderRow = i;
    end
    if ~isempty(HeaderRow)
        break
    end
end

posheaders = strsplit(tline,'\t');
posData = dlmread(convertStringsToChars(posfile),'\t',HeaderRow,0);

for i = 1:length(posheaders)
    TrialData.Analyze.Position.(posheaders{i}) = posData(:,i);
end

fclose(posID);

%Velocity
velfile = strcat(OSFolder,'\',trialname,'_BodyKinematics_vel_global.sto');
velID = fopen(convertStringsToChars(velfile));

HeaderRow = [];
for i = 1:30
    tline = fgetl(velID);
    if strfind(tline,'time') == 1
        HeaderRow = i;
    end
    if ~isempty(HeaderRow)
        break
    end
end

velheaders = strsplit(tline,'\t');
velData = dlmread(convertStringsToChars(velfile),'\t',HeaderRow,0);

for i = 1:length(velheaders)
    TrialData.Analyze.Velocity.(velheaders{i}) = velData(:,i);
end

fclose(velID);

%Acceleration
accfile = strcat(OSFolder,'\',trialname,'_BodyKinematics_acc_global.sto');
accID = fopen(convertStringsToChars(accfile));

HeaderRow = [];
for i = 1:30
    tline = fgetl(accID);
    if strfind(tline,'time') == 1
        HeaderRow = i;
    end
    if ~isempty(HeaderRow)
        break
    end
end

accheaders = strsplit(tline,'\t');
accData = dlmread(convertStringsToChars(accfile),'\t',HeaderRow,0);

for i = 1:length(accheaders)
    TrialData.Analyze.Acceleration.(accheaders{i}) = accData(:,i);
end

fclose(accID);

end