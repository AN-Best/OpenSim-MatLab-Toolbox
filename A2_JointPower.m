function StrideData = A2_JointPower(StrideData)
%Computes joint power for and positive and negative joint work
%   StrideData = normalized stride data, note must include IK and ID
%   results

%% Compute Power

Nstrides = length(StrideData.StrideTime);

angle_names = fieldnames(StrideData.InverseKinematics);
torque_names = fieldnames(StrideData.InverseDynamics);

for i = 1:length(angle_names)  
    %Create the matching name for torque
    tname_i = strcat(angle_names{i},'_moment');
    fname_i = strcat(angle_names{i},'_force');
    for j = 1:length(torque_names)
        %find the index of the joint torque
        if strcmp(tname_i,torque_names{j}) || strcmp(fname_i,torque_names{j})
            t_ind = j;
        end
    end

    for k = 1:Nstrides

        stridetime = StrideData.StrideTime(k,1);
        angle = (pi/180)*StrideData.InverseKinematics.(angle_names{i})(:,k);
        torque = StrideData.InverseDynamics.(torque_names{t_ind})(:,k);

        %Take derivative of angle
        dt = stridetime/length(angle);

        omega = [(angle(2,1) - angle(1,1))/dt;...
            (angle(3:end,1) - angle(1:end-2))/(2*dt);...
            (angle(end,1)-angle(end-1,1))/dt];

        power = torque.*omega;

        %Save to the structures
        pname_i = strcat(angle_names{i},'_power');
        StrideData.JointPower.(pname_i)(:,k) = power;
    end
end

%% Joint Energy

power_names = fieldnames(StrideData.JointPower);

for i = 1:Nstrides
    time = linspace(0,StrideData.StrideTime(i,1),1000);
    for j = 1:length(power_names)

        %Seperate positive and negative power
        pos_power = StrideData.JointPower.(power_names{j})(:,i);
        pos_power(pos_power<0) = 0;
        neg_power = StrideData.JointPower.(power_names{j})(:,i);
        neg_power(neg_power>0) = 0;

        %Compute work
        pos_work = trapz(time,pos_power);
        neg_work = trapz(time,neg_power);

        %Save in structure
        wname_i = strcat(angle_names{j},'_work');
        StrideData.JointWork.(wname_i)(i,1) = pos_work;
        StrideData.JointWork.(wname_i)(i,2) = neg_work;
    end
end
end