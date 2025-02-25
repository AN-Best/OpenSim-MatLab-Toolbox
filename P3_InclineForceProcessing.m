function TrialData = P3_InclineForceProcessing(TrialData,FlatTrial,Mtread,Fthres,PlateOrigin,pltflag)
%This function takes the force data from the local coordinate system into
%the global coordinate system. This is only for trials when the treadmill
%is inclined
%   TrialData = data processing structure
%   FlatTrial = data processing structure from a flat walking trial, this
%   trial must have the same 3 treadmill markers present
%   Mtread = labels of the markers on the treadmill, order is origin,
%   primary axis and secondary axis
%   Fthres = force threshold for computing CoP
%   PlateOrigin = 1x2 array with the corner number that the origin of the
%   plate is located, use zero if the origin is at the center of the plate
%   pltflag = plot flag
%   Note the moment added to the trial data is the free moment acting on
%   the foot, not the moment measured by the force plate 
%   FreeMoment = Mz - Fy*CoPx + Fx*CoPx

%Originally Written By: Aaron N. Best (Apr 2023)
%Update Record:

%Aug 2023 - Modidied to require only three markers in the specified order
%(Aaron N. Best)



%% Check to see if pltflag is given

if nargin == 5
    pltflag = 0;
end

%% Find the location of the treadmill markers each dataset

Flat_names = fieldnames(FlatTrial.MarkerData.Trajectories);
Incline_names = fieldnames(TrialData.MarkerData.Trajectories);
Flat_ind = NaN(length(Mtread),1);
Incline_ind = NaN(length(Mtread),1);

for i = 1:length(Flat_names)
    for j = 1:length(Mtread)
        if strcmp(Mtread(1,j),Flat_names{i})
            Flat_ind(j,1) = i;
        end
    end
end

for i = 1:length(Incline_names)
    for j = 1:length(Mtread)
        if strcmp(Mtread(1,j),Incline_names{i})
            Incline_ind(j,1) = i;
        end
    end
end

%% Pull out the treadmill markers in the first frame

Incline_tmark = NaN(3,3);
Flat_tmark = NaN(3,3);
for i = 1:length(Mtread)
    Incline_tmark(i,:) = TrialData.MarkerData.Trajectories.(Incline_names{Incline_ind(i)})(1,:);
    Flat_tmark(i,:) = FlatTrial.MarkerData.Trajectories.(Flat_names{Flat_ind(i)})(1,:);
end

%% Setup Flat and Inclined Coordinate Systems

%Inclined Coordinate System
O = Incline_tmark(1,:);
X = Incline_tmark(2,:) - Incline_tmark(1,:);
V = Incline_tmark(3,:) - Incline_tmark(1,:);

Y = cross(X,V);
Z = cross(X,Y);

X = X./norm(X);
Y = Y./norm(Y);
Z = Z./norm(Z);

T_I = [X',Y',Z',O';0 0 0 1];

%Flat coordinate system
O = Flat_tmark(1,:);
X = Flat_tmark(2,:) - Flat_tmark(1,:);
V = Flat_tmark(3,:) - Flat_tmark(1,:);

Y = cross(X,V);
Z = cross(X,Y);

X = X./norm(X);
Y = Y./norm(Y);
Z = Z./norm(Z);

T_F = [X',Y',Z',O';0 0 0 1];

%Rotate the global axis
T_GI = (T_I)*(T_F^-1); %Incline

TrialData.GroundPlane = T_GI;


%% Iterate through the plates
plates = fieldnames(TrialData.ForceData);
for i = 1:length(plates)
    %% Rotate the corners of the treadmill
    tread_corners = FlatTrial.ForceData.(plates{i}).PlateCorners;
    incline_corners = NaN(size(tread_corners));
    for j = 1:length(tread_corners(:,1))
            p = [tread_corners(j,:)';1];
            p = T_GI*p;
            incline_corners(j,:) = p(1:3)';
    end

    FlatTrial.ForceData.(plates{i}).PlateCorners = incline_corners;

    %% Create the coordinate systems for the plates
    
    curr_corner = PlateOrigin(i);
    
    %center of the plate
    if curr_corner == 0
        Oflat = mean(tread_corners);
    else
        Oflat = tread_corners(curr_corner,:);
    end

    %% Pull out the forces, moments, and CoP
    % need to flip the y to make it right handed
    
    Force = TrialData.ForceData.(plates{i}).Force;
    Force = [Force(:,1),-1*Force(:,2),Force(:,3)];
    
    Moment = TrialData.ForceData.(plates{i}).Moment;
    Moment = [Moment(:,1),-1*Moment(:,2),Moment(:,3)];

    %% Compute the CoP in the flat system

    CoP = NaN(size(Force));
    for j = 1:length(CoP(:,1))
        if Force(j,3) > Fthres
            CoP(j,1) = -1*Moment(j,2)/Force(j,3);
            CoP(j,2) = Moment(j,1)/Force(j,3);
            CoP(j,3) = 0;
        else
            CoP(j,:) = [0 0 0];
        end
    end
    
    %% Compute the free Moment

    FreeMoment = zeros(size(Moment));
    FreeMoment(:,3) = Moment(:,3) - Force(:,2).*CoP(:,1) + Force(:,1).*CoP(:,2);
    
    %% Translate the CoP
    CoP(:,1) = CoP(:,1) + Oflat(:,1);
    CoP(:,2) = CoP(:,2) + Oflat(:,2);

    %% Put the Forces and Moments in the Tilted Global System
    for j = 1:length(Force)
        F = T_GI*[Force(j,:)';1]; 
        Force(j,:) = F(1:3)';
        M = T_GI*[FreeMoment(j,:)';1]; 
        FreeMoment(j,:) = M(1:3)';
        C = T_GI*[CoP(j,:)';1]; 
        CoP(j,:) = C(1:3)';
    end
    %% Rewrite all the data to TrialData
    TrialData.ForceData.(plates{i}).Force = Force;
    TrialData.ForceData.(plates{i}).Moment = FreeMoment;
    TrialData.ForceData.(plates{i}).CoP = CoP;
end
%% Optional Plotting
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