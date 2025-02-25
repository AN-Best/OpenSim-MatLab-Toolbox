function StrideData = A1_Normalize(TrialData,marker,force,IK,Analyze,ID)
%This function breaks up the data and normalizes it to 1000 points per
%stride
%   TrialData = structure with processed data
%   marker = flag for normalizing markers
%   force = flag for normalizing force
%   IK = flag for normalizing IK
%   Analyze = flag for normalizing Analyze results
%   ID = flag for analyzing ID

%% Compute the Stride Time

GaitEvents = TrialData.GaitEvents;
Nstrides = length(GaitEvents(:,1));
mfreq = TrialData.MarkerData.FrameRate;

for i = 1:Nstrides

    start = GaitEvents(i,1);
    fin = GaitEvents(i,5);

    start_time = start/mfreq;
    fin_time = fin/mfreq;

    StrideData.StrideTime(i,1) = fin_time-start_time;
end

%% Normalize Gait Events to get index in 0 to 1000

for i = 1:Nstrides

    %Pull out event index
    RHS1 = GaitEvents(i,1);
    LTO = GaitEvents(i,2);
    LHS = GaitEvents(i,3);
    RTO = GaitEvents(i,4);
    RHS2 = GaitEvents(i,5);

    %Normlize from 0 to 1000
    RHS1norm = 1;
    LTOnorm = 1000*(LTO-RHS1)/(RHS2-RHS1);
    LHSnorm = 1000*(LHS-RHS1)/(RHS2-RHS1);
    RTOnorm = 1000*(RTO-RHS1)/(RHS2-RHS1);
    RHS2norm = 1000;

    %Round and save
    StrideData.GaitEvents(i,1) = RHS1norm;
    StrideData.GaitEvents(i,2) = round(LTOnorm);
    StrideData.GaitEvents(i,3) = round(LHSnorm);
    StrideData.GaitEvents(i,4) = round(RTOnorm);
    StrideData.GaitEvents(i,5) = RHS2norm;
end

%% Normalize the Marker Data

if marker == 1
    for i = 1:Nstrides

        start = GaitEvents(i,1);
        fin = GaitEvents(i,5);

        marker_names = fieldnames(TrialData.MarkerData.Trajectories);

        stridetime = StrideData.StrideTime(i,1);
        time_record = linspace(0,stridetime,fin-start+1);
        time_norm = linspace(0,stridetime,1000);

        for j = 1:length(marker_names)

            traj = TrialData.MarkerData.Trajectories.(marker_names{j})(start:fin,:);

            normtraj = [interp1(time_record,traj(:,1),time_norm,"spline")',...
                            interp1(time_record,traj(:,2),time_norm,"spline")',...
                            interp1(time_record,traj(:,3),time_norm,"spline")'];

            StrideData.MarkerData.(marker_names{j})(:,1:3,i) = normtraj;
        end
    end
end

%% Normalize Force Data

if force == 1
    for i = 1:Nstrides

        freq_factor = TrialData.ForceData.Plate1.FrameRate/TrialData.MarkerData.FrameRate;

        start = freq_factor*GaitEvents(i,1);
        fin = freq_factor*GaitEvents(i,5);

        stridetime = StrideData.StrideTime(i,1);
        time_record = linspace(0,stridetime,fin-start+1);
        time_norm = linspace(0,stridetime,1000);

        %Right Foot
        F = TrialData.ForceData.RightFoot.Force(start:fin,:);
        M = TrialData.ForceData.RightFoot.Moment(start:fin,:);
        C = TrialData.ForceData.RightFoot.CoP(start:fin,:);

        Fnorm = [interp1(time_record,F(:,1),time_norm,"spline")',...
                interp1(time_record,F(:,2),time_norm,"spline")',...
                interp1(time_record,F(:,3),time_norm,"spline")'];

        Mnorm = [interp1(time_record,M(:,1),time_norm,"spline")',...
                interp1(time_record,M(:,2),time_norm,"spline")',...
                interp1(time_record,M(:,3),time_norm,"spline")'];

        Cnorm = [interp1(time_record,C(:,1),time_norm,"spline")',...
                interp1(time_record,C(:,2),time_norm,"spline")',...
                interp1(time_record,C(:,3),time_norm,"spline")'];

        StrideData.ForceData.RightFoot.Force(:,1:3,i) = Fnorm;
        StrideData.ForceData.RightFoot.Moment(:,1:3,i) = Mnorm;
        StrideData.ForceData.RightFoot.CoP(:,1:3,i) = Cnorm;

        %Left Foot
        F = TrialData.ForceData.LeftFoot.Force(start:fin,:);
        M = TrialData.ForceData.LeftFoot.Moment(start:fin,:);
        C = TrialData.ForceData.LeftFoot.CoP(start:fin,:);

        Fnorm = [interp1(time_record,F(:,1),time_norm,"spline")',...
                interp1(time_record,F(:,2),time_norm,"spline")',...
                interp1(time_record,F(:,3),time_norm,"spline")'];

        Mnorm = [interp1(time_record,M(:,1),time_norm,"spline")',...
                interp1(time_record,M(:,2),time_norm,"spline")',...
                interp1(time_record,M(:,3),time_norm,"spline")'];

        Cnorm = [interp1(time_record,C(:,1),time_norm,"spline")',...
                interp1(time_record,C(:,2),time_norm,"spline")',...
                interp1(time_record,C(:,3),time_norm,"spline")'];

        StrideData.ForceData.LeftFoot.Force(:,1:3,i) = Fnorm;
        StrideData.ForceData.LeftFoot.Moment(:,1:3,i) = Mnorm;
        StrideData.ForceData.LeftFoot.CoP(:,1:3,i) = Cnorm;
    end
end

%% Normalize Inverse Kinematics

if IK == 1
    for i = 1:Nstrides

        start = GaitEvents(i,1);
        fin = GaitEvents(i,5);

        q_names = fieldnames(TrialData.InverseKinematics);

        stridetime = StrideData.StrideTime(i,1);
        time_record = linspace(0,stridetime,fin-start+1);
        time_norm = linspace(0,stridetime,1000);

        for j = 1:length(q_names)

            if strcmp(q_names{j},'Error') || strcmp(q_names{j},'time')
                %skip these feilds
            else
                q = TrialData.InverseKinematics.(q_names{j})(start:fin,1);
                qnorm = interp1(time_record,q,time_norm,"spline")';
                StrideData.InverseKinematics.(q_names{j})(:,i) = qnorm;
            end
        end
    end
end

%% Normalize Analyze Data

if Analyze == 1
    for i = 1:Nstrides

        start = GaitEvents(i,1);
        fin = GaitEvents(i,5);

        stridetime = StrideData.StrideTime(i,1);
        time_record = linspace(0,stridetime,fin-start+1);
        time_norm = linspace(0,stridetime,1000);

        der_names = fieldnames(TrialData.Analyze);

        for k = 1:length(der_names)
            q_names = fieldnames(TrialData.Analyze.(der_names{k}));
            for j = 1:length(q_names)
                if strcmp(q_names{j},'time')
                    %skip these feilds
                else
                    q = TrialData.Analyze.(der_names{k}).(q_names{j})(start:fin,1);
                    qnorm = interp1(time_record,q,time_norm,"spline")';
                    StrideData.Analyze.(der_names{k}).(q_names{j})(:,i) = qnorm;
                end
            end
        end
    end
end

%% Normalize the ID Data

if ID == 1
    for i = 1:Nstrides

        start = GaitEvents(i,1);
        fin = GaitEvents(i,5);

        q_names = fieldnames(TrialData.InverseDynamics);

        stridetime = StrideData.StrideTime(i,1);
        time_record = linspace(0,stridetime,fin-start+1);
        time_norm = linspace(0,stridetime,1000);

        for j = 1:length(q_names)

            if strcmp(q_names{j},'time')
                %skip these feilds
            else
                q = TrialData.InverseDynamics.(q_names{j})(start:fin,1);
                qnorm = interp1(time_record,q,time_norm,"spline")';
                StrideData.InverseDynamics.(q_names{j})(:,i) = qnorm;
            end
        end
    end
end
end