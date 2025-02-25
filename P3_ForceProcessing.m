function TrialData = P3_ForceProcessing(TrialData,Fthres,PlateOrigin,pltflag)
%This function takes the force data from the local coordinate system into
%the global coordinate system
%   TrialData = data processing structure
%   Fthres = force threshold for calculating the CoP
%   PlateOrigin = 1x2 array with the corner number that the origin of the
%   plate is located, use zero if the origin is at the center of the plate
%   pltflag = flag for plotting
%   Note the moment added to the trial data is the free moment acting on
%   the foot, not the moment measured by the force plate 
%   FreeMoment = Mz - Fy*CoPx + Fx*CoPx

%Originally Written By: Aaron N. Best (Apr 2023)
%Update Record:

%% Check if pltflag is specified

if nargin == 3
    pltflag = 0;
end

%% Iterate through the number of plates
plates = fieldnames(TrialData.ForceData);

for i = 1:length(plates)

   %% Compute the origin of the plate coordinate system
    corners = TrialData.ForceData.(plates{i}).PlateCorners;
    
    curr_corner = PlateOrigin(i);
    
    %center of the plate
    if curr_corner == 0
        Oplate = mean(corners);
    else
        Oplate = corners(curr_corner,:);
    end
    %% Pull out force and moment data
    %need to flop the y direction to make right handed

    Force = TrialData.ForceData.(plates{i}).Force;
    Force = [Force(:,1),-1*Force(:,2),Force(:,3)];

    Moment = TrialData.ForceData.(plates{i}).Moment;
    Moment = [Moment(:,1),-1*Moment(:,2),Moment(:,3)];

    %% Recompute CoP
    CoP = NaN(size(Force));
    for j = 1:length(CoP(:,1))
        if Force(j,3) > Fthres
            CoP(j,1) = -Moment(j,2)/Force(j,3);
            CoP(j,2) = Moment(j,1)/Force(j,3);
            CoP(j,3) = 0;
        elseif Force(j,3) <= Fthres
            CoP(j,:) = [0 0 0];
        end
    end

    %% Calculate the free moment acting on the foot
    
    FreeMoment = zeros(size(Moment));
    FreeMoment(:,3) = Moment(:,3) - Force(:,2).*CoP(:,1) + Force(:,1).*CoP(:,2);

    %% Translate the CoP into the global system

    CoP(:,1) = CoP(:,1) + Oplate(:,1);
    CoP(:,2) = CoP(:,2) + Oplate(:,2);

    %% Rewrite all the data to TrialData
    
    TrialData.ForceData.(plates{i}).Force = Force;
    TrialData.ForceData.(plates{i}).Moment = FreeMoment;
    TrialData.ForceData.(plates{i}).CoP = CoP;
   
end

if pltflag == 1

    figure;

    subplot(2,4,[1 2]);
    hold on;
    for i = 1:length(plates)
        plot(TrialData.ForceData.(plates{i}).Force(:,3))
    end
    title('Vertical GRF Force');
    xlabel('Frame');
    ylabel('Force (N)');
    hold off;

    subplot(2,4,[5 6]);
    hold on;
    for i = 1:length(plates)
        plot(TrialData.ForceData.(plates{i}).Moment(:,3))
    end
    title('Free Momemt');
    xlabel('Frame');
    ylabel('Moment (Nm)');
    hold off;
    
    subplot(2,4,[3 4 7 8]);
    hold on;
    axis equal;
    for i = 1:length(plates)
        if i == 1
        plot3(TrialData.ForceData.(plates{i}).CoP(:,1),TrialData.ForceData.(plates{i}).CoP(:,2),...
            TrialData.ForceData.(plates{i}).CoP(:,3),'.r');
        else
            plot3(TrialData.ForceData.(plates{i}).CoP(:,1),TrialData.ForceData.(plates{i}).CoP(:,2),...
            TrialData.ForceData.(plates{i}).CoP(:,3),'.b');
        end

        
        plot3(TrialData.ForceData.(plates{i}).PlateCorners(:,1),TrialData.ForceData.(plates{i}).PlateCorners(:,2),...
            TrialData.ForceData.(plates{i}).PlateCorners(:,3),'.k','MarkerSize',15);
    end
    title('CoP');
    view([45,45]);
    hold off;
end

end