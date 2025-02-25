function TrialData = O5_RunID(TrialData,OSFolder,OSIMmodel,ID_Setting,EX_Setting)
%This function runs inverse dynamics using OpenSim and then adds it to the
%TrialData structure
%   TrialData = data structure for saving the results
%   OSFolder = folder where all the opensim data is saved
%   Model = name of the .osim file for the scaled walking model
%   ID_Setting = generic settings for running ID in opensim
%   EX_Setting = generic setting for adding external loads in opensim

%Originally Written By: Aaron N. Best (Apr 2023)
%Update Record:

%% Access OpenSim

import org.opensim.modeling.*


%% Access the external loads tool and update the force file

trialname = TrialData.CollectionName;
extloadfile = convertStringsToChars(strcat(OSFolder,'/',trialname,'.mot'));

ext_xml = xmlread(strcat(OSFolder,'/',EX_Setting));
ext_xml.getElementsByTagName('datafile').item(0).setTextContent(extloadfile);
ext_xml.getElementsByTagName('data_source_name').item(0).setTextContent(extloadfile);

xmlwrite(fullfile(OSFolder,strcat('Setup_ExternalLoad_',trialname,'.xml')),ext_xml);

%% Import and adjust the ID settings

ID_xml = xmlread(strcat(OSFolder,'/',ID_Setting));

modelfile = convertStringsToChars(strcat(OSFolder,'/',OSIMmodel));
extloadxml = convertStringsToChars(fullfile(OSFolder,strcat('Setup_ExternalLoad_',trialname,'.xml')));
timerange = [num2str(TrialData.InverseKinematics.time(1,1))," ",num2str(TrialData.InverseKinematics.time(end,1))];
timetype = convertStringsToChars(strcat(timerange(1),timerange(2),timerange(3)));
IKfile = convertStringsToChars(strcat(OSFolder,'/',trialname,'_IK.mot'));
IDfilename = convertStringsToChars(strcat(OSFolder,'/',trialname,'_ID.sto'));


ID_xml.getElementsByTagName('InverseDynamicsTool').item(0).setAttribute('name',trialname);
ID_xml.getElementsByTagName('results_directory').item(0).setTextContent(convertStringsToChars(OSFolder));
ID_xml.getElementsByTagName('model_file').item(0).setTextContent(modelfile);
ID_xml.getElementsByTagName('time_range').item(0).setTextContent(timetype);
ID_xml.getElementsByTagName('external_loads_file').item(0).setTextContent(extloadxml);
ID_xml.getElementsByTagName('coordinates_file').item(0).setTextContent(IKfile);
ID_xml.getElementsByTagName('output_gen_force_file').item(0).setTextContent(IDfilename);

xmlwrite(fullfile(OSFolder,strcat('Setup_ID_',trialname,'.xml')),ID_xml);

%% Run the inverse dynamics tool

idTool = InverseDynamicsTool(fullfile(OSFolder,strcat('Setup_ID_',trialname,'.xml')));

fprintf("Beginning ID on %s \n",trialname);
idTool.run();
fprintf("Finished ID on %s \n",trialname);

%% Pull in the data file from the saved .sto

IDfile = fopen(strcat(OSFolder,'/',trialname,'_ID.sto'));

HeaderRow = [];
ind = 1;
for i = 1:50 
    tline = fgetl(IDfile);
    if strfind(tline,'time') == 1
        HeaderRow = ind;
    end
    if ~isempty(HeaderRow)
        break;
    end
    ind = ind + 1;
end

headers = strsplit(tline,'\t');
Tdata = dlmread(convertStringsToChars(strcat(OSFolder,'/',trialname,'_ID.sto')),...
    '\t',HeaderRow,0);

for i = 1:length(headers)
    TrialData.InverseDynamics.(headers{i}) = Tdata(:,i);
end

fclose(IDfile);


end