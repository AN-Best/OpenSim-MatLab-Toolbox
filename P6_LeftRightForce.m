function TrialData = P6_LeftRightForce(TrialData,Fthres,HSPlate,VTaxis,order,fc,pltflag)
%This function splits the force data into the Left and Right Foot for the
%HMRL treadmill (front-back split)
%   TrialData = data structure for processing, must include processed
%   forces
%   HSPlate = index of which plate is the HS plate (1 when facing forward)
%   Mnames = marker names of markers on the right and left foot (one marker
%   per foot, order right left)
%   order = order for filter (need to refilter to smooth out the
%   transitions)
%   fc = cutoff frequency for filter
%   pltflag = flag for plotting (default is zero)

%   Note this code requires gait events to be found prior to use, the code
%   then only fills in the time when a valid stride has been found if there
%   is no valid stride the force, cop and moment are equal to zero. As a
%   result this function can only be used for walking, when no flight phase
%   occurs.


%Originally Written By: Aaron N. Best (Apr 2023)
%Update Record:

%% Check if plot flag is provided

if nargin == 2
    pltflag = 0;
end

%% Pull out the force data

if HSPlate == 1 %front plate is the HS plate
    HS_F = TrialData.ForceData.Plate1.Force(:,:);
    HS_CoP = TrialData.ForceData.Plate1.CoP(:,:);
    HS_M = TrialData.ForceData.Plate1.Moment(:,:);
    TO_F = TrialData.ForceData.Plate2.Force(:,:);
    TO_CoP = TrialData.ForceData.Plate2.CoP(:,:);
    TO_M = TrialData.ForceData.Plate2.Moment(:,:);

else %back plate is the HS plate
    HS_F = TrialData.ForceData.Plate2.Force(:,:);
    HS_CoP = TrialData.ForceData.Plate2.CoP(:,:);
    HS_M = TrialData.ForceData.Plate2.Moment(:,:);
    TO_F = TrialData.ForceData.Plate1.Force(:,:);
    TO_CoP = TrialData.ForceData.Plate1.CoP(:,:);
    TO_M = TrialData.ForceData.Plate1.Moment(:,:);

end

GaitEvents = (TrialData.ForceData.Plate1.FrameRate/TrialData.MarkerData.FrameRate)*TrialData.GaitEvents;

R_transition = NaN(length(GaitEvents(:,1)),2);
L_transition = NaN(length(GaitEvents(:,1)),2);

%% Split the force into right and left

R_Force = zeros(size(HS_F));
R_CoP = zeros(size(HS_F));
R_Moment = zeros(size(HS_F));

L_Force = zeros(size(HS_F));
L_CoP = zeros(size(HS_F));
L_Moment = zeros(size(HS_F));

RTOonplate = 0;
LHSonplate = 0;
for i = 1:length(GaitEvents(:,1))

    start = GaitEvents(i,1);
    fin = GaitEvents(i,5);

    %A stride would have only been located if this was the case
    RHSonplate = 1;
    LTOonplate = 1;

    for j = start:fin

        %Phase 1 - Right on HS and Left on TO
        if RHSonplate == 1 && RTOonplate == 0 &&...
            LHSonplate == 0 && LTOonplate == 1

            R_Force(j,:) = HS_F(j,:);
            R_Moment(j,:) = HS_M(j,:);
            R_CoP(j,:) = HS_CoP(j,:);

            L_Force(j,:) = TO_F(j,:);
            L_Moment(j,:) = TO_M(j,:);
            L_CoP(j,:) = TO_CoP(j,:);
        end

        %Detect lift off of left foot
        if HS_F(j,VTaxis) > Fthres && TO_F(j,VTaxis) < Fthres &&...
                RHSonplate == 1 && RTOonplate == 0 &&...
                LHSonplate == 0 && LTOonplate == 1
            LTOonplate = 0;
        end

        %Phase 2 - Right on front plate, left in flight
        if RHSonplate == 1 && RTOonplate == 0 &&...
            LHSonplate == 0 && LTOonplate == 0

            R_Force(j,:) = HS_F(j,:);
            R_Moment(j,:) = HS_M(j,:);
            R_CoP(j,:) = HS_CoP(j,:);

            L_Force(j,:) = [0 0 0];
            L_Moment(j,:) = [0 0 0];
            L_CoP(j,:) = [0 0 0];
        end

        %Detect transition of the right foot to being on both plates
        if HS_F(j,VTaxis) > Fthres && TO_F(j,VTaxis) > Fthres &&...
                RHSonplate == 1 && RTOonplate == 0 &&...
                LHSonplate == 0 && LTOonplate == 0
            RTOonplate = 1;
            R_transition(i,1) = j;
        end

        %Phase 3 - Right foot on both plates
        if RHSonplate == 1 && RTOonplate == 1 &&...
            LHSonplate == 0 && LTOonplate == 0

            R_Force(j,:) = HS_F(j,:) + TO_F(j,:);
            R_Moment(j,:) = HS_M(j,:) + TO_M(j,:);
            R_CoP(j,:) = (norm(HS_F(j,:))*HS_CoP(j,:) + norm(TO_F(j,:))*TO_CoP(j,:))/(norm(HS_F(j,:)) + norm(TO_F(j,:))) ;

            L_Force(j,:) = [0 0 0];
            L_Moment(j,:) = [0 0 0];
            L_CoP(j,:) = [0 0 0];

            
        end

        %Detect the right foot slipping onto the back plate
        if HS_F(j,VTaxis) < Fthres && TO_F(j,VTaxis) > Fthres &&...
                RHSonplate == 1 && RTOonplate == 1 &&...
                LHSonplate == 0 && LTOonplate == 0
            RHSonplate = 0;
            R_transition(i,2) = j;
        end

        %Phase 4 - Right foot only on back plate
        if RHSonplate == 0 && RTOonplate == 1 &&...
            LHSonplate == 0 && LTOonplate == 0

            R_Force(j,:) = TO_F(j,:);
            R_Moment(j,:) = TO_M(j,:);
            R_CoP(j,:) = TO_CoP(j,:);

            L_Force(j,:) = [0 0 0];
            L_Moment(j,:) = [0 0 0];
            L_CoP(j,:) = [0 0 0];
        end

        %Detect the left foot landing back on the HS plate
        if HS_F(j,VTaxis) > Fthres && TO_F(j,VTaxis) > Fthres &&...
                RHSonplate == 0 && RTOonplate == 1 &&...
                LHSonplate == 0 && LTOonplate == 0
            LHSonplate = 1;
        end

        %Phase 5 - Right on TO plate and left on HS plate
        if RHSonplate == 0 && RTOonplate == 1 &&...
            LHSonplate == 1 && LTOonplate == 0

            R_Force(j,:) = TO_F(j,:);
            R_Moment(j,:) = TO_M(j,:);
            R_CoP(j,:) = TO_CoP(j,:);

            L_Force(j,:) = HS_F(j,:);
            L_Moment(j,:) = HS_M(j,:);
            L_CoP(j,:) = HS_CoP(j,:);
        end

        %Detect the right foot lifting off
        if HS_F(j,VTaxis) > Fthres && TO_F(j,VTaxis) < Fthres &&...
                RHSonplate == 0 && RTOonplate == 1 &&...
                LHSonplate == 1 && LTOonplate == 0
            RTOonplate = 0;
        end

        %Phase 6 - Left foot just on HS plate
        if RHSonplate == 0 && RTOonplate == 0 &&...
            LHSonplate == 1 && LTOonplate == 0

            R_Force(j,:) = [0 0 0];
            R_Moment(j,:) = [0 0 0];
            R_CoP(j,:) = [0 0 0];

            L_Force(j,:) = HS_F(j,:);
            L_Moment(j,:) = HS_M(j,:);
            L_CoP(j,:) = HS_CoP(j,:) ;

        end

        %Detect the left foot being on both plate
        if HS_F(j,VTaxis) > Fthres && TO_F(j,VTaxis) > Fthres &&...
                RHSonplate == 0 && RTOonplate == 0 &&...
                LHSonplate == 1 && LTOonplate == 0
            LTOonplate = 1;
            L_transition(i,1) = j;
        end

        %Phase 7 - Left foot on both plates
        if RHSonplate == 0 && RTOonplate == 0 &&...
            LHSonplate == 1 && LTOonplate == 1

            R_Force(j,:) = [0 0 0];
            R_Moment(j,:) = [0 0 0];
            R_CoP(j,:) = [0 0 0];

            L_Force(j,:) = HS_F(j,:) + TO_F(j,:);
            L_Moment(j,:) = HS_M(j,:) + TO_M(j,:);
            L_CoP(j,:) = (norm(HS_F(j,:))*HS_CoP(j,:) + norm(TO_F(j,:))*TO_CoP(j,:))/(norm(HS_F(j,:)) + norm(TO_F(j,:))) ;
   
        end

        %Detect the left foot being fully on the back plate
        if HS_F(j,VTaxis) < Fthres && TO_F(j,VTaxis) > Fthres &&...
                RHSonplate == 0 && RTOonplate == 0 &&...
                LHSonplate == 1 && LTOonplate == 1
            LHSonplate = 0;
            L_transition(i,2) = j;
        end

        %Phase 8 - Left foot only on the back plate
        if RHSonplate == 0 && RTOonplate == 0 &&...
            LHSonplate == 0 && LTOonplate == 1

            R_Force(j,:) = [0 0 0];
            R_Moment(j,:) = [0 0 0];
            R_CoP(j,:) = [0 0 0];

            L_Force(j,:) = TO_F(j,:);
            L_Moment(j,:) = TO_M(j,:);
            L_CoP(j,:) = TO_CoP(j,:) ;
        end
        
        %Detect if the right foot has landed back again
        if HS_F(j,VTaxis) > Fthres && TO_F(j,VTaxis) > Fthres &&...
                RHSonplate == 0 && RTOonplate == 0 &&...
                LHSonplate == 0 && LTOonplate == 1
            RHSonplate = 1;
        end

       %Phase 1 - Right on HS and Left on TO
        if RHSonplate == 1 && RTOonplate == 0 &&...
            LHSonplate == 0 && LTOonplate == 1

            R_Force(j,:) = HS_F(j,:);
            R_Moment(j,:) = HS_M(j,:);
            R_CoP(j,:) = HS_CoP(j,:);

            L_Force(j,:) = TO_F(j,:);
            L_Moment(j,:) = TO_M(j,:);
            L_CoP(j,:) = TO_CoP(j,:);
        end
    end
end

%% Refilter to smoot out the forces

%Find continous force sections
sets = [GaitEvents(1,1) NaN];
for i = 2:length(GaitEvents(:,1))

    endcycle = GaitEvents(i-1,5);
    begincycle = GaitEvents(i,1);

    if endcycle-begincycle == 0
        %do nothing
    else 
        sets(end,2) = endcycle;
        sets = [sets;begincycle NaN];
    end
end
sets(end,2) = length(R_Force(:,1));

%Filter Setup
fs = TrialData.ForceData.Plate1.FrameRate;
wn = (fc/0.802)/(fs/2);
[b,a] = butter(order,wn);

%Filter the continuous section
for i = 1:length(sets(:,1))

    R_Force(sets(i,1):sets(i,2),:) = filtfilt(b,a,R_Force(sets(i,1):sets(i,2),:));
    R_Moment(sets(i,1):sets(i,2),:) = filtfilt(b,a,R_Moment(sets(i,1):sets(i,2),:));
    R_CoP(sets(i,1):sets(i,2),:) = filtfilt(b,a,R_CoP(sets(i,1):sets(i,2),:));

    L_Force(sets(i,1):sets(i,2),:) = filtfilt(b,a,L_Force(sets(i,1):sets(i,2),:));
    L_Moment(sets(i,1):sets(i,2),:) = filtfilt(b,a,L_Moment(sets(i,1):sets(i,2),:));
    L_CoP(sets(i,1):sets(i,2),:) = filtfilt(b,a,L_CoP(sets(i,1):sets(i,2),:));
end

%% Check the remove forces if the foot should be in flight phase


for i = 1:length(GaitEvents(:,1))

    L_Flight = [GaitEvents(i,2), GaitEvents(i,3)];
    R_Flight = [GaitEvents(i,4),GaitEvents(i,5)];

    %Check left foot
    for j = L_Flight(1):L_Flight(2)
        if L_Force(j,VTaxis) ~= 0
            L_Force(j,:) = [0 0 0];
            L_Moment(j,:) = [0 0 0];
            L_CoP(j,:) = [0 0 0];
        end
    end

    %Check Right foot
    for j = R_Flight(1):R_Flight(2)
        if R_Force(j,VTaxis) ~= 0
            R_Force(j,:) = [0 0 0];
            R_Moment(j,:) = [0 0 0];
            R_CoP(j,:) = [0 0 0];
        end
    end
end



%% Optional Plotting

if pltflag == 1 

    figure;

    subplot(2,1,1);
    hold on;
    title('Right Force');
    plot(R_Force(:,:));
    for i = 1:length(GaitEvents)
        line([GaitEvents(i,1) GaitEvents(i,1)], [-100 800],'Color','k');
        line([GaitEvents(i,5) GaitEvents(i,5)], [-100 800],'Color','r');
    end
    legend('x','y','z');
    hold off;

    subplot(2,1,2);
    hold on;
    title('Left Force');
    plot(L_Force(:,:));
    for i = 1:length(GaitEvents)
        line([GaitEvents(i,1) GaitEvents(i,1)], [-100 800],'Color','k');
        line([GaitEvents(i,5) GaitEvents(i,5)], [-100 800],'Color','r');
    end
    legend('x','y','z');
    hold off;

    figure;
    
    subplot(2,1,1);
    hold on;
    plot(R_CoP(:,1));
    plot(L_CoP(:,1));
    legend('Right','Left');
    title('AP CoP');
    hold off;

    subplot(2,1,2);
    hold on;
    plot(R_CoP(:,3));
    plot(L_CoP(:,3));
    legend('Right','Left');
    title('ML CoP');
    hold off;

end


%% Pack into TrialData Structure

TrialData.ForceData.RightFoot.Force = R_Force;
TrialData.ForceData.RightFoot.CoP = R_CoP;
TrialData.ForceData.RightFoot.Moment = R_Moment;
TrialData.ForceData.LeftFoot.Force = L_Force;
TrialData.ForceData.LeftFoot.CoP = L_CoP;
TrialData.ForceData.LeftFoot.Moment = L_Moment;


end