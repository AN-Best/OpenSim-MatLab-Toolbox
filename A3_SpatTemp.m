function StrideData = A3_SpatTemp(StrideData,speed)
%This function calculate spatio-temporal measures from the normalized data
%   StrideData = structure of normalized data
%   speed = speed of the treadmill in m/s

%% Compute ST measures in each stride

for i = 1:length(StrideData.StrideTime)
    
    GaitEvents = StrideData.GaitEvents(i,:);
    ST = StrideData.StrideTime(i,1);
    
    %StrideLength
    StrideData.StrideLength(i,1) = ST*speed;
    
    %StepWidth
    CoPR = StrideData.ForceData.RightFoot.CoP(GaitEvents(1,1),3,i);
    CoPL = StrideData.ForceData.LeftFoot.CoP(GaitEvents(1,1),3,i);

    StrideData.StepWidth(i,1) = CoPR - CoPL;
    CoPR = StrideData.ForceData.RightFoot.CoP(GaitEvents(1,3),3,i);
    CoPL = StrideData.ForceData.LeftFoot.CoP(GaitEvents(1,3),3,i);

    StrideData.StepWidth(i,2) = CoPR - CoPL;
end


end