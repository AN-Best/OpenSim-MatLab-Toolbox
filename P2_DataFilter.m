function TrialData = P2_DataFilter(TrialData,fc_marker,fc_force,order,pltflag)
%Filter for the forces and markers in the .QTM file
%   TrialData = structure from QTMmatDataExtrcat
%   fc_marker = cutoff frequency for markers (set to 0 to skip filtering)
%   fc_force = cutoff frequency for force (set to 0 to skip filtering)
%   order = order of the filter 
%   pltflag = flag for plotting data (default is 0)

%Originally Written By: Aaron N. Best (Apr 2023)
%Update Record:
% Aug 2023 - added option to skip filtering a trajectory if there is a NaN
% present (Aaron N. Best)

%% Check for plot flag

if nargin < 4
    pltflag = 0;
end

%% Filter Marker Data

if fc_marker ~= 0

   % Create Filter
    fs_marker =  TrialData.MarkerData.FrameRate;
    wn = (fc_marker/0.802)/(fs_marker/2);
    [b,a] = butter(order,wn);

    %Pull data out, filter, and put back
    labels = fieldnames(TrialData.MarkerData.Trajectories);
    for i = 1:length(labels)
        traj = TrialData.MarkerData.Trajectories.(labels{i});

        if pltflag == 1 && i == length(labels)
            figure;
            hold on;
            plot(traj(:,1));
        end

        %Check if the data is all there, if it is filter
        if isnan(mean(traj))
            fprintf("%s: %s not filtered, missing frames \n",TrialData.CollectionName,labels{i});
        else
            traj = filtfilt(b,a,traj);
        end

        if pltflag == 1 && i == length(labels)
            plot(traj(:,1));
            legend('Raw','Filtered');
            title('Marker Filtering');
            hold off;
        end

        TrialData.MarkerData.Trajectories.(labels{i}) = traj;
    end
end

%% Filter Force Data

if fc_force ~= 0

    plates = fieldnames(TrialData.ForceData);
    for i = 1:length(plates)
        
        fs_force = TrialData.ForceData.(plates{i}).FrameRate;
        wn = (fc_force/0.802)/(fs_force/2);
        [b,a] = butter(order,wn);

        %Filter force
        Force = TrialData.ForceData.(plates{i}).Force;
        if pltflag == 1 && i == 1
            figure;
            hold on;
            plot(Force(:,3));
        end
        Force = filtfilt(b,a,Force);
        if pltflag == 1 && i == 1
            plot(Force(:,3));
            legend('Raw','Filterd');
            title('Force Filtering');
            hold off;
        end
        TrialData.ForceData.(plates{i}).Force = Force;
        %Filter Moment
        TrialData.ForceData.(plates{i}).Moment = filtfilt(b,a,TrialData.ForceData.(plates{i}).Moment);
        %Filter CoP
        TrialData.ForceData.(plates{i}).CoP = filtfilt(b,a,TrialData.ForceData.(plates{i}).CoP);
    end
end
end