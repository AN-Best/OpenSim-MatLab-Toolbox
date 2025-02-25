function TrialData = P5_GaitEventsSplitBelt(TrialData,Plates,VTaxis,Fthres,pltflag)
%This function finds the gait events for a left right split treadmill
%   Plates = 1x2 array of the plate number for the right and left plates
%   VTaxis = vertical axis for threasholding
%   Fthres = force threshold
%   pltflag = optional plot flag
%   Note gait events are indexes in the force framerate not the marker
%   framerate

%Originally Written By: Aaron N. Best (July 2023)
%Update Record:

%% Check for pltflag

if nargin == 4
    pltflag = 0;
end

%% Pull out the force data

plate_names = fieldnames(TrialData.ForceData);

RF = TrialData.ForceData.(plate_names{Plates(1)}).Force(:,VTaxis);
LF = TrialData.ForceData.(plate_names{Plates(2)}).Force(:,VTaxis);


%% Find the Gait Events

RHS = [];
LTO = [];
LHS = [];
RTO = [];

for i = 2:length(RF)
    %Right Heel Strike
    if RF(i,1) > Fthres && RF(i-1,1) < Fthres
        RHS = [RHS;i];
    end
    %Left toe off
    if LF(i,1) < Fthres && LF(i-1) > Fthres
        LTO = [LTO;i];
    end
    %Left Heel Strike
    if LF(i,1) > Fthres && LF(i-1,1) < Fthres
        LHS = [LHS;i];
    end
    %Right toe off
    if RF(i,1) < Fthres && RF(i-1,1) > Fthres
        RTO = [RTO;i];
    end
end

%% Organize into strides

GaitEvents = NaN(length(RHS)-1,5);
GaitEvents(:,1) = RHS(1:end-1);
GaitEvents(:,5) = RHS(2:end,:);

%Check to see if the stride is to long
for i = 1:length(GaitEvents)
    if GaitEvents(i,5) - GaitEvents(i,1) > 2*TrialData.ForceData.Plate1.FrameRate
        GaitEvents(i,1) = NaN;
    end
end

%Add in the LTO
for i = 1:length(LTO)
    for j = 1:length(GaitEvents(:,1))
        if isnan(GaitEvents(j,1))
            %Don't add an event
        else
            if LTO(i,1) > GaitEvents(j,1) &&  LTO(i,1) < GaitEvents(j,5)
                GaitEvents(j,2) = LTO(i,1);
            end
        end
    end
end

%Add in the LHS
for i = 1:length(LHS)
    for j = 1:length(GaitEvents(:,1))
        if isnan(GaitEvents(j,2))
            %Don't add an event
        else
            if LHS(i,1) > GaitEvents(j,2) &&  LHS(i,1) < GaitEvents(j,5)
                GaitEvents(j,3) = LHS(i,1);
            end
        end
    end
end

%Add in the RTO
for i = 1:length(RTO)
    for j = 1:length(GaitEvents(:,1))
        if isnan(GaitEvents(j,3))
            %Don't add an event
        else
            if RTO(i,1) > GaitEvents(j,3) &&  RTO(i,1) < GaitEvents(j,5)
                GaitEvents(j,4) = RTO(i,1);
            end
        end
    end
end


%% Eliminate the Gait Cycles that have NaN Value

TrialData.GaitEvents = [];

for i = 1:length(GaitEvents(:,1))
    if isnan(mean(GaitEvents(i,:)))
        %Do nothing
    else
        TrialData.GaitEvents = [TrialData.GaitEvents;GaitEvents(i,:)];
    end
end

%% Optional Plotting 


if pltflag == 1

    figure;

    subplot(2,1,1);
    hold on;
    plot(RF);
    ylim([0 1000]);
    for i = 1:length(TrialData.GaitEvents(:,1))
        line([TrialData.GaitEvents(i,1) TrialData.GaitEvents(i,1)],[0 1000],'Color','r');
        line([TrialData.GaitEvents(i,4) TrialData.GaitEvents(i,4)],[0 1000],'Color','k');
    end

    title('Right Foot');
    hold off;

    subplot(2,1,2);
    hold on;
    plot(LF);
    ylim([0 1000]);
    for i = 1:length(TrialData.GaitEvents(:,1))
        line([TrialData.GaitEvents(i,2) TrialData.GaitEvents(i,2)],[0 1000],'Color','k');
        line([TrialData.GaitEvents(i,3) TrialData.GaitEvents(i,3)],[0 1000],'Color','r');
    end

    title('Left Foot');
    hold off;
end

end