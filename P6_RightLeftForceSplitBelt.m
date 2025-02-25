function TrialData = P6_RightLeftForceSplitBelt(TrialData,Plates,Fthres,pltflag)
%This function splits the force into right and left foot data
%   TrialData = data structure for processing, must include processed
%   forces
%   Plates = 1 x 2 array with the index of the plate for the right and left
%   foot respectively
%   Fthres = force threshold
%   pltflag = optional plot flag

%Originally Written By: Aaron N. Best (July 2023)
%Update Record:

%% Check if plot flag is provided

if nargin == 2
    pltflag = 0;
end

%% Seperate the Data into Right and Left

plate_names = fieldnames(TrialData.ForceData);


TrialData.ForceData.RightFoot.Force = TrialData.ForceData.(plate_names{Plates(1)}).Force;
TrialData.ForceData.RightFoot.Moment = TrialData.ForceData.(plate_names{Plates(1)}).Moment;
TrialData.ForceData.RightFoot.CoP = TrialData.ForceData.(plate_names{Plates(1)}).CoP;

TrialData.ForceData.LeftFoot.Force = TrialData.ForceData.(plate_names{Plates(2)}).Force;
TrialData.ForceData.LeftFoot.Moment = TrialData.ForceData.(plate_names{Plates(2)}).Moment;
TrialData.ForceData.LeftFoot.CoP = TrialData.ForceData.(plate_names{Plates(2)}).CoP;

%% Make zero when not in contact

RF = TrialData.ForceData.(plate_names{Plates(1)}).Force(:,2);
LF = TrialData.ForceData.(plate_names{Plates(2)}).Force(:,2);

for i = 1:length(RF)
    if RF(i,1)<Fthres
        TrialData.ForceData.RightFoot.Force(i,:) = [0 0 0];
        TrialData.ForceData.RightFoot.Moment(i,:) = [0 0 0];
        TrialData.ForceData.RightFoot.CoP(i,:) = [0 0 0];
    end
    if LF(i,1)<Fthres
        TrialData.ForceData.LeftFoot.Force(i,:) = [0 0 0];
        TrialData.ForceData.LeftFoot.Moment(i,:) = [0 0 0];
        TrialData.ForceData.LeftFoot.CoP(i,:) = [0 0 0];
    end
end

%% Optional Plotting

if pltflag == 1

    figure;
    
    subplot(3,1,1);
    hold on;
    plot(TrialData.ForceData.RightFoot.Force(:,1),'r');
    plot(TrialData.ForceData.RightFoot.Force(:,2),'g');
    plot(TrialData.ForceData.RightFoot.Force(:,3),'b');
    title('Right Foot Force');
    hold off;

    subplot(3,1,2);
    hold on;
    plot(TrialData.ForceData.RightFoot.Moment(:,1),'r');
    plot(TrialData.ForceData.RightFoot.Moment(:,2),'g');
    plot(TrialData.ForceData.RightFoot.Moment(:,3),'b');
    title('Right Foot Moment');
    hold off;

    subplot(3,1,3);
    hold on;
    plot(TrialData.ForceData.RightFoot.CoP(:,1),'r');
    plot(TrialData.ForceData.RightFoot.CoP(:,2),'g');
    plot(TrialData.ForceData.RightFoot.CoP(:,3),'b');
    title('Right Foot CoP');
    hold off;



    figure;
    
    subplot(3,1,1);
    hold on;
    plot(TrialData.ForceData.LeftFoot.Force(:,1),'r');
    plot(TrialData.ForceData.LeftFoot.Force(:,2),'g');
    plot(TrialData.ForceData.LeftFoot.Force(:,3),'b');
    title('Left Foot Force');
    hold off;

    subplot(3,1,2);
    hold on;
    plot(TrialData.ForceData.LeftFoot.Moment(:,1),'r');
    plot(TrialData.ForceData.LeftFoot.Moment(:,2),'g');
    plot(TrialData.ForceData.LeftFoot.Moment(:,3),'b');
    title('Left Foot Moment');
    hold off;

    subplot(3,1,3);
    hold on;
    plot(TrialData.ForceData.LeftFoot.CoP(:,1),'r');
    plot(TrialData.ForceData.LeftFoot.CoP(:,2),'g');
    plot(TrialData.ForceData.LeftFoot.CoP(:,3),'b');
    title('Left Foot CoP');
    hold off;
end
end