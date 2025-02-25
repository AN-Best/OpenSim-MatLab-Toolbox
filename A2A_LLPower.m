function StrideData = A2A_LLPower(StrideData)
%This function calculates the total joint power of the ankle,knee and hip
%in the AP plane
%   StrideData = StrideNormalized Data

Nstrides = length(StrideData.StrideTime);

for i = 1:Nstrides

    Hip = StrideData.JointPower.hip_flexion_r_power(:,i);
    Knee = StrideData.JointPower.knee_angle_r_power(:,i);
    Ankle = StrideData.JointPower.ankle_angle_r_power(:,i);

    Total = Hip + Knee + Ankle;

    StrideData.JointPower.LL_power(:,i) = Total;
    
        pos_power = Total;
        pos_power(pos_power<0) = 0;
        neg_power = Total;
        neg_power(neg_power>0) = 0;

        time = linspace(0,StrideData.StrideTime(i,1),1000);
        pos_work = trapz(time,pos_power);
        neg_work = trapz(time,neg_power);

        StrideData.JointWork.LL_work(i,1) = pos_work;
        StrideData.JointWork.LL_work(i,2) = neg_work;
end