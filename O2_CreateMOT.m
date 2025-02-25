function O2_CreateMOT(TrialData,filepath)
%Export right and left split force data to .mot
%   TrialData = structure containing left and right split force data
%   filepath = path to save file to (default is pwd)

%Originally Written By: Aaron N. Best (Apr 2023)
%Update Record:

%% Check if filepath is specified

if nargin == 1
    filepath = pwd;
end

%% Pull out the force and CoP data

FrameRate = TrialData.ForceData.Plate1.FrameRate;
Frames = TrialData.ForceData.Plate1.Frames;

RF = TrialData.ForceData.RightFoot.Force;
LF = TrialData.ForceData.LeftFoot.Force;

RCoP = TrialData.ForceData.RightFoot.CoP;
LCoP = TrialData.ForceData.LeftFoot.CoP;

RM = TrialData.ForceData.RightFoot.Moment;
LM = TrialData.ForceData.LeftFoot.Moment;

time = linspace(0,Frames/FrameRate,Frames)';

%% Write to a big array

BigArray = [time,RF,RCoP,RM,LF,LCoP,LM];

ArrayTitles = ['time','\t',...
    'ground_force_vx','\t','ground_force_vy','\t','ground_force_vz','\t',...
    'ground_force_px','\t','ground_force_py','\t','ground_force_pz','\t',...
    'ground_torque_x','\t','ground_torque_y','\t','ground_torque_z','\t',...
    '1_ground_force_vx','\t','1_ground_force_vy','\t','1_ground_force_vz','\t',...
    '1_ground_force_px','\t','1_ground_force_py','\t','1_ground_force_pz','\t',...
    '1_ground_torque_x','\t','1_ground_torque_y','\t','1_ground_torque_z','\t','\n'];

[nRows, nColumns] = size(BigArray);

ForceString = regexprep(mat2str(BigArray),{'[',']',' ',';'},{'','','\t','\n'});

%% Create File to Write To

filename = TrialData.CollectionName;
path_n_filename = strcat(filepath,'\',filename,'.mot');

fileID = fopen(path_n_filename,'w');

%% Write to the file

fprintf(fileID,'%s.mot\n',filename);
fprintf(fileID,'version=1\n');
fprintf(fileID,'nRows=%i\n',nRows);
fprintf(fileID,'nColumns=%i\n',nColumns);
fprintf(fileID,'inDegrees=no\n');
fprintf(fileID,'endheader\n');
fprintf(fileID,ArrayTitles);
fprintf(fileID,ForceString);

fclose(fileID);

fprintf('%s has been created \n',path_n_filename);

end