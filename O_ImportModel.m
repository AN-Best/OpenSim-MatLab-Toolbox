function TrialData = O_ImportModel(TrialData,OSFolder,OSModel)
%This function imports the mass and inertia of the segments of the model
%into matlab from opensim
%   TrialData = structure for saving the data to
%   OSFolder = folder containing opensim model
%   OSModel = name of the .osim model

%Originally Written By: Aaron N. Best (Apr 2023)
%Update Record:

%% Access OpenSim

import org.opensim.modeling.*

%% Openup the model tool

model = Model(convertStringsToChars(strcat(OSFolder,'/',OSModel)));

%% Iterate through the bodies and save attributes

nBodies = model.getNumBodies();

%Total mass summing
MASS = 0;

for i = 0:nBodies-1
    
    %Pull out attributes
    body = model.getBodySet().get(i);
    mass = body.get_mass();
    inertia_OS = body.get_inertia();

    %Convert further convert inertia
    inertia = NaN(inertia_OS.size,1);
    for j = 0:inertia_OS.size-1
        inertia(j+1,1) = inertia_OS.get(j);
    end
    
    %save to TrialData
    TrialData.OSModelProperties.(string(body)).Mass = mass;
    TrialData.OSModelProperties.(string(body)).Inertia = inertia;
    %Sum segement mass
    MASS = MASS + mass;
end


TrialData.OSModelProperties.TotalMass = MASS;
TrialData.OSModelProperties.Name = OSModel;

end