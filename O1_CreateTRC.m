function O1_CreateTRC(TrialData,filepath)
%Creates .trc for opensim using the marker data from the TrialData
%structure
%   TrialData = structure with marker data
%   filepath = path to save .trc (default is pwd)

%Originally Written By: Aaron N. Best (Apr 2023)
%Update Record:

%% Check file path input
if nargin == 1
    filepath = pwd;
end

%% Arrange the Data into a big array

labels = fieldnames(TrialData.MarkerData.Trajectories);
frames = TrialData.MarkerData.Frames;
fs = TrialData.MarkerData.FrameRate;

MarkerArray = NaN(frames,3*length(labels));
%Add the marker data
for i = 1:length(labels)
    MarkerArray(:,3*i-2:3*i) = TrialData.MarkerData.Trajectories.(labels{i});
end
%Add columns for frame and time
MarkerArray = [(1:1:frames)',(0:frames-1)'./fs,MarkerArray];
MarkerString = regexprep(mat2str(MarkerArray),{'[',']',' ',';'},{'','','\t','\n'});

%% Fill Supporting Info

Info_Names = ['DataRate','\t',...
    'CameraRate','\t',...
    'NumFrames','\t',...
    'NumMarkers','\t',...
    'Units','\t',...
    'OrigDataRate','\t',...
    'OrigDataStartFrame','\t',...
    'OrigNumFrames','\n'];

Info_Vals = [num2str(fs),'\t',...
    num2str(fs),'\t',...
    num2str(frames),'\t',...
    num2str(length(labels)),'\t',...
    'm','\t',...
    num2str(fs),'\t',...
    num2str(1),'\t',...
    num2str(frames),'\n'];

%% Marker Headings

Headings = ['Frame#','\t','Time','\t'];

for i = 1:length(labels)
    if  i < length(labels)
        Headings = [Headings,labels{i},'\t\t\t'];
    else
        Headings = [Headings,labels{i},'\n'];
    end  
end

%% Direction Heading

DirectionHeadings = ['\t','\t',];
for i = 1:length(labels)
    if i < length(labels)
        DirectionHeadings = [DirectionHeadings,strcat('X',num2str(i)),'\t',...
            strcat('Y',num2str(i)),'\t',...
            strcat('Z',num2str(i)),'\t'];
    else
        DirectionHeadings = [DirectionHeadings,strcat('X',num2str(i)),'\t',...
            strcat('Y',num2str(i)),'\t',...
            strcat('Z',num2str(i)),'\n\n'];
    end
end

%% Create File to Write To

filename = TrialData.CollectionName;
path_n_filename = strcat(filepath,'\',filename,'.trc');

fileID = fopen(path_n_filename,'w');

%% Print Headings to the file

fprintf(fileID,'PathFileType\t4\t(X/Y/Z)\t%s.trc\n',filename);
fprintf(fileID,Info_Names);
fprintf(fileID,Info_Vals);
fprintf(fileID,Headings);
fprintf(fileID,DirectionHeadings);
fprintf(fileID,'\n');
fprintf(fileID,MarkerString);

fclose(fileID);

fprintf('%s has been created \n',path_n_filename);


end