function ratesTrialsNeurons = pmdDataSetup(Data)
% Code to organize the data to facilitate the tuning curve analysis.
% Pass in processed PMd data

% find successful trials. Only include these.
ov = [Data.Overview];
success = [ov.trialStatus] == 1;
data = Data(success);

% find any trials that do not contain spike data. Exclude these.
noData = false(size(data));
for trl = 1:length(data)
    noData(trl) = isempty(data(trl).TrialData.spikes) || ...
        isnan(data(trl).TrialData.timeMoveOnset);
end
data(noData) = [];

% create matrix with spike data around movement time
td = [data.TrialData];
reachAngle = [td.reachAngle];
moveStart = [td.timeMoveOnset];
spikeCount = NaN(length(data),length(data(1).TrialData.spikes));
for trl = 1:length(data)
    % get spike count around movement onset
    for neuron = 1:length(data(trl).TrialData.spikes)
        spikeTimes = data(trl).TrialData.spikes(neuron).timestamps;
        % count spikes between 200ms before and 200ms after movement
        spikeCount(trl,neuron) = sum((spikeTimes > (moveStart(trl)-200))...
            &(spikeTimes < (moveStart(trl)+200)));
    end
end

%normalize firing rates and remove non-firing neurons
spikeCount = spikeCount/(400/1000);
spikeCount(:,sum(spikeCount,1)==0) = [];

% combine into simple matrix
%%% rows = trials
%%% column 1 = target angle, columns 2:N+1 = firing rate for all N neurons
ratesTrialsNeurons = [reachAngle', spikeCount];
