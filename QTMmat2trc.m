function QTMmat2trc(matfile,rotdata,filepath,pltflag)
%Converts the .mat files from QTM to .trc for OpenSim
%   matfile = matfile directly exported from qtm
%   rotdata = rotation order for going into opensim (order = [AP VT ML],
%   for the HMRL treadmill use [3 1 2], default is [1 2 3])
%   filepath = path to save .trc (default is pwd)
%   pltflag = switch for plotting (0 for no plots, defult is 0)


%Originally Written By: Aaron N. Best (Apr 2023)
%Update Record:

%% Fill default for optional inputs

if nargin == 1
    rotdata = [1 2 3];
    filepath = pwd;
    pltflag = 0;

elseif nargin == 2
    filepath = pwd;
    pltflag = 0;

elseif nargin == 3
    pltflag = 0;
end


%% Pull out the markers and their names
labels = matfile.Trajectories.Labeled.Labels;
for i = 1:length(labels)
    marker_data.(labels{i}) = squeeze(matfile.Trajectories.Labeled.Data(i,1:3,:)./1000)';
end

fs = matfile.FrameRate; %collection frequency
frames = matfile.Frames; %number of frames

%% Rotate Marker Data

if pltflag == 1

    figure;
    
    subplot(1,2,1);
    hold on;
    axis equal;
    title('Original Axes');
    view(180,0);
    
    quiver3(0,0,0,1,0,0,'r');
    quiver3(0,0,0,0,1,0,'g');
    quiver3(0,0,0,0,0,1,'b');
    
    for i = 1:length(labels)
        plot3(marker_data.(labels{i})(1,1),marker_data.(labels{i})(1,2),marker_data.(labels{i})(1,3),'.');
    end
    
    hold off;

end

for i = 1:length(labels)

    temp = NaN(frames,3);
    for j = 1:3
        temp(:,rotdata(j)) = marker_data.(labels{i})(:,j);
    end
    marker_data.(labels{i}) = temp;
end

if pltflag == 1

    subplot(1,2,2);
    hold on;
    axis equal;
    title('Rotated Axes');
    view(-90,90);

    quiver3(0,0,0,1,0,0,'r');
    quiver3(0,0,0,0,1,0,'g');
    quiver3(0,0,0,0,0,1,'b');
    
    for i = 1:length(labels)
        plot3(marker_data.(labels{i})(1,1),marker_data.(labels{i})(1,2),marker_data.(labels{i})(1,3),'.');
    end
    
    hold off;
end


%% Arrange the Data into a big array

MarkerArray = NaN(frames,3*length(labels));
%Add the marker data
for i = 1:length(labels)
    MarkerArray(:,3*i-2:3*i) = marker_data.(labels{i});
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

original_path = convertCharsToStrings(matfile.File);
original_path = split(original_path,'\');

filename = original_path(end,1);
filename = erase(filename,".qtm");
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
