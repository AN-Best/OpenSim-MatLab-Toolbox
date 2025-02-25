function TrialData = P_AddAttributes(TrialData,Mass,Height,LegLength)
%This function adds the mass, height and wieght of the subject to the
%structure, if you do not want to add one of the items use a value of zero
%   TrialData = structure containing the processed data for the trial
%   Mass = measured mass
%   Height = measured height
%   LegLength = meansure leg length

%Originally Written By: Aaron N. Best (Aug 2023)
%Update Record:

%% Add the items specified

if Mass > 0
    TrialData.SubjAttributes.Mass = Mass;
end

if Height > 0
    TrialData.SubjAttributes.Height = Height;
end

if LegLength > 0
    TrialData.SubjAttributes.LegLength = LegLength;
end





end