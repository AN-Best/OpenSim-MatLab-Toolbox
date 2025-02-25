function TrialData = P5_GaitEvents(TrialData,VTaxis,APaxis,HSPlate,Mnames,Fthres,Tthres,pltflag)
%The function finds the gait events using the force plates for the the
%treadmill at the HMRL (front-back split)
%   TrialData = custom structure for processing, must contain force data,
%   output order is RHS,LTO,LHS,RTO,RHS
%   VTaxis = column number of the vertical axis of the force data
%   APaxis = column number of the AP axis of the marker data
%   HSPlate = index of which plate is the HS plate
%   Mnames = marker names of markers on the right and left foot (one marker
%   per foot, order right left)
%   Fthres = force cutoff threshold
%   Tthres = time threshold for time between HS
%   pltflag = optional plot flag
%   Note gait events are in order RHS, LTO, LHS, RTO, RHS and are in the
%   index of the markers 

%Originally Written By: Aaron N. Best (Apr 2023)
%Update Record:

%% Check for pltflag

if nargin == 7
    pltflag = 0;
end

%% Pull out the force and marker data

PlateNames = fieldnames(TrialData.ForceData);

if HSPlate == 1 %front plate is the HS plate
    HS_F = TrialData.ForceData.Plate1.Force(:,VTaxis);
    TO_F = TrialData.ForceData.Plate2.Force(:,VTaxis);
    
    plate_ind = [1 2];    
else %back plate is the HS plate
    HS_F = TrialData.ForceData.Plate2.Force(:,VTaxis);
    TO_F = TrialData.ForceData.Plate1.Force(:,VTaxis);

    plate_ind = [2 1];
end

for i = 1:length(Mnames)
    MarkerNames = fieldnames(TrialData.MarkerData.Trajectories);
    for j = 1:length(MarkerNames)
        if strcmp(Mnames{i},MarkerNames{j,1}) && i == 1
            RF = TrialData.MarkerData.Trajectories.(MarkerNames{j,1});
        elseif strcmp(Mnames{i},MarkerNames{j,1}) && i == 2
            LF = TrialData.MarkerData.Trajectories.(MarkerNames{j,1});
        end
    end
end

%% Resample the Force Data

HS_F = resample(HS_F,TrialData.MarkerData.FrameRate,TrialData.ForceData.(PlateNames{plate_ind(1)}).FrameRate);
TO_F = resample(TO_F,TrialData.MarkerData.FrameRate,TrialData.ForceData.(PlateNames{plate_ind(2)}).FrameRate);

%% Locate the HS and TO

HS_ind = [];
Tthres = round(Tthres*TrialData.MarkerData.FrameRate); %Covert to # of frames
for i = 2:length(HS_F)
    %Locating the first HS - no time threshold
    if isempty(HS_ind)
        if HS_F(i,1) > Fthres && HS_F(i-1,1) < Fthres
            HS_ind = i;
            last_ind = i;
        end
    %Following HS Events
    else
        if HS_F(i,1) > Fthres && HS_F(i-1,1) < Fthres && (i - last_ind) > Tthres
            HS_ind = [HS_ind;i];
            last_ind = i;
        end
    end
end

TO_ind = [];
for i = 2:length(TO_F)
    %Locating the first HS - no time threshold
    if isempty(TO_ind)
        if TO_F(i,1) < Fthres && TO_F(i-1,1) > Fthres
            TO_ind = i;
            last_ind = i;
        end
    %Following HS Events
    else
        if TO_F(i,1) < Fthres && TO_F(i-1,1) > Fthres && (i - last_ind) > Tthres
            TO_ind = [TO_ind;i];
            last_ind = i;
        end
    end
end

%% Split into Right and Left Sides

RHS_ind = [];
LHS_ind = [];
for i = 1:length(HS_ind)

    ind = HS_ind(i,1);

    RF_ind = RF(ind,APaxis);
    LF_ind = LF(ind,APaxis);

    if HSPlate == 1 %Walking forward
        if RF_ind > LF_ind %Right foot in front of left
            RHS_ind =[RHS_ind;ind];
        else %Left foot in front of right
            LHS_ind = [LHS_ind;ind];
        end
    elseif HSPlate == 2 %Walking backwards
        if RF_ind < LF_ind %Right foot in front of left
            RHS_ind =[RHS_ind;ind];
        else %Left foot in front of right
            LHS_ind = [LHS_ind;ind];
        end
    end
end

RTO_ind = [];
LTO_ind = [];
for i = 1:length(TO_ind)
    ind = TO_ind(i,1);

    RF_ind = RF(ind,APaxis);
    LF_ind = LF(ind,APaxis);

    if HSPlate == 1
        if RF_ind < LF_ind %Right foot is behind left
            RTO_ind = [RTO_ind;ind];
        else %Left foot is behind right
            LTO_ind = [LTO_ind;ind];
        end
    else
        if RF_ind > LF_ind %Right foot is behind left
            RTO_ind = [RTO_ind;ind];
        else %Left foot is behind right
            LTO_ind = [LTO_ind;ind];
        end
    end
end


%% Back into the Trial Data Structure & Take out the strides that are to long

GaitEvents = NaN(length(RHS_ind)-1,5);
GaitEvents(:,1) = RHS_ind(1:end-1);
GaitEvents(:,5) = RHS_ind(2:end,:);

%Eliminate strides that are to long
for i = 1:length(GaitEvents(:,1)) 
    if GaitEvents(i,5) - GaitEvents(i,1) > 4*Tthres
        GaitEvents(i,:) = NaN(1,5);
    end
end

%Add in the LTO
for i = 1:length(LTO_ind)
    for j = 1:length(GaitEvents(:,1))
        if isnan(GaitEvents(j,1))
            %Don't add an event
        else
            if LTO_ind(i,1) > GaitEvents(j,1) &&  LTO_ind(i,1) < GaitEvents(j,5)
                GaitEvents(j,2) = LTO_ind(i,1);
            end
        end
    end
end

%Add in the LHS
for i = 1:length(LHS_ind)
    for j = 1:length(GaitEvents(:,1))
        if isnan(GaitEvents(j,2))
            %Don't add an event
        else
            if LHS_ind(i,1) > GaitEvents(j,2) &&  LHS_ind(i,1) < GaitEvents(j,5)
                GaitEvents(j,3) = LHS_ind(i,1);
            end
        end
    end
end

%Add in the RTO
for i = 1:length(RTO_ind)
    for j = 1:length(GaitEvents(:,1))
        if isnan(GaitEvents(j,3))
            %Don't add an event
        else
            if RTO_ind(i,1) > GaitEvents(j,3) &&  RTO_ind(i,1) < GaitEvents(j,5)
                GaitEvents(j,4) = RTO_ind(i,1);
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
    plot(HS_F);
    for i = 1:length(TrialData.GaitEvents(:,1))
        line([TrialData.GaitEvents(i,1) TrialData.GaitEvents(i,1)],[0 1000],'Color','k');
        line([TrialData.GaitEvents(i,3) TrialData.GaitEvents(i,3)],[0 1000],'Color','r');
    end

    title('Heel Strike Plate');
    hold off;

        
    subplot(2,1,2);
    hold on;
    plot(TO_F);
    for i = 1:length(TrialData.GaitEvents(:,1))
        line([TrialData.GaitEvents(i,2) TrialData.GaitEvents(i,2)],[0 1000],'Color','r');
        line([TrialData.GaitEvents(i,4) TrialData.GaitEvents(i,4)],[0 1000],'Color','k');
    end

    title('Heel Strike Plate');
    hold off;


end
end






