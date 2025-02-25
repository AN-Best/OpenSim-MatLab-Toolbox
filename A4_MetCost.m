function StrideData = A4_MetCost(StrideData,k5table,TrialName,QuietStanding,t_avg)
%This function computes the metabolic cost for a trial from the output of
%the K5 unit, metabolic cost is provided in W according to the Brockway
%equation and O2 and CO2 rates are in mL/s
%   StrideData = structure that you would like this data saved into
%   k5table = table containing the excel data exported from the K5 unit,
%   this should be imported using read cell
%   TrialName = name of the trial used to marker the data in the K5 data,
%   the beginning of the trial should be marked with (TrialName)_s and the
%   end of the trial should be marker with (TrialName)_e
%   QuietStanding = name of the quiet standing trial in the K5 data, the
%   end of beginning of the trial should be marked with (QuietStanding)_s
%   and the end of the trial should be marked with (QuietStanding)_e
%   t_avg = time to average cost over in seconds, this is down in the last
%   t_avg seconds of the trial

%% Pull out the important columns


column_names = {"t";"VO2";"VCO2";"Marker"};
col_num = NaN(length(column_names),1);

for i = 1:length(k5table(1,:))

    for j = 1:length(column_names)

        if strcmp(k5table{1,i},column_names{j,1})
            col_num(j,1) = i;
        end
    end
end

clock_time = cell2mat(k5table(4:end,col_num(1,1)));
VO2 = cell2mat(k5table(4:end,col_num(2,1)));
VCO2 = cell2mat(k5table(4:end,col_num(3,1)));
Marker = k5table(4:end,col_num(4,1));

%% Fix the time format

clock_time = string(datetime(clock_time, 'ConvertFrom','excel', 'Format','HH:mm:ss'));
clock_time = str2double(split(clock_time,':'));

t = (60*60)*clock_time(:,1) + 60*clock_time(:,2) + clock_time(:,3);

%% Pull out the quiet standing and trial data

QS_ind = NaN(1,2);
trial_ind = NaN(1,2);

for i = 1:length(Marker)

    %Find the quiet standing trial
    if strcmp(strcat(QuietStanding,'_s'),Marker{i,1})
        QS_ind(1,1) = i;
    end
    if strcmp(strcat(QuietStanding,'_e'),Marker{i,1})
        QS_ind(1,2) = i;
    end

    %Find the walking trial
    if strcmp(strcat(TrialName,'_s'),Marker{i,1})
        trial_ind(1,1) = i;
    end
    if strcmp(strcat(TrialName,'_e'),Marker{i,1})
        trial_ind(1,2) = i;
    end
end

QS_data.t = t(QS_ind(1,1):QS_ind(1,2),1) - t(QS_ind(1,1),1);
QS_data.VO2 = VO2(QS_ind(1,1):QS_ind(1,2),1)/60;
QS_data.VCO2 = VCO2(QS_ind(1,1):QS_ind(1,2),1)/60;

trial_data.t = t(trial_ind(1,1):trial_ind(1,2),1) - t(trial_ind(1,1),1);
trial_data.VO2 = VO2(trial_ind(1,1):trial_ind(1,2),1)/60;
trial_data.VCO2 = VCO2(trial_ind(1,1):trial_ind(1,2),1)/60;

%% Compute the gross metabolic cost in both the QS and walking trial


QS_start = QS_data.t(end,1) - t_avg;
QS_O2 = QS_data.VO2(QS_data.t(:,1) > QS_start,1);
QS_CO2 = QS_data.VCO2(QS_data.t(:,1) > QS_start,1);

QS_data.GrossPower = 16.58*mean(QS_O2) + 4.51*mean(QS_CO2);

t_start = trial_data.t(end,1) - t_avg;
t_O2 = trial_data.VO2(trial_data.t(:,1) > t_start,1);
t_CO2 = trial_data.VCO2(trial_data.t(:,1) > t_start,1);

trial_data.GrossPower = 16.58*mean(t_O2) + 4.51*mean(t_CO2);

%% Compute the net metabolic power for the walking trial

NetPower = trial_data.GrossPower - QS_data.GrossPower;

%% Save the results

StrideData.Metabolic.t = trial_data.t;
StrideData.Metabolic.VO2 = trial_data.VO2;
StrideData.Metabolic.VCO2 = trial_data.VCO2;
StrideData.Metabolic.GrossPower = trial_data.GrossPower;
StrideData.Metabolic.NetPower = NetPower;











end