classdef Run < LFADS.Run
    methods
        function r = Run(varargin)
           r@LFADS.Run(varargin{:});
        end


        function out = generateCountsForDataset(r, dataset, mode, varargin) %#ok<INUSL,INUSD>
            % Generate binned spike count tensor for a single dataset.
            %
            % Parameters
            % ------------
            % dataset : :ref:`LFADS_Dataset`
            %   The :ref:`LFADS_Dataset` instance from which data were loaded
            %
            % mode (string) : typically 'export' indicating sequence struct
            %   will be exported for LFADS, or 'alignment' indicating that this
            %   struct will be used to generate alignment matrices. You can
            %   include a different subset of the data (or different time
            %   windows) for the alignment process separately from the actual
            %   data exported to LFADS, or return the same for both. Alignment
            %   is only relevant for multi-dataset models. If you wish to use
            %   separate data for alignment, override the method usesDifferentDataForAlignment
            %   to return true as well.
            %
            % Returns
            % ----------
            % out: a scalar struct with the following fields:
            %
            % .counts : nTrials x nChannels x nTime tensor
            %   spike counts in time bins in trials x channels x time. These
            %   should be total counts, not normalized rates, as they will be
            %   added during rebinning.
            %
            % .timeVecMs: nTime x 1 vector
            %   of timepoints in milliseconds associated with each time bin. You can start this
            %   wherever you like, but timeVecMs(2) - timeVecMs(1) will be
            %   treated as the spike bin width used when the data are later
            %   rebinned to match run.params.spikeBinMs
            %
            % .conditionId: nTrials x 1 vector
            %   of unique conditionIds. Can be cell array of strings or
            %   vector of unique integers.

            % grab dataset
            data = dataset.loadData();
            % initialize array to hold the spikes
            spikes = [];
            sizeOfData=size(data);
            disp('Iterating over all trials');
            trials = sizeOfData(2);
            disp(['Trials: ',num2str(trials)])

            for trial_index=1:(trials-1)
                if(mod(trial_index, 100)==0)
                    disp(['On: ', num2str(trial_index)])
                end
                trial = data(trial_index);
                spikes(trial_index, :, :) = generateMergedSpikes(trial);
            end
            disp('Assigning Spikes');
            % (required)- A tensor of binned spike counts (not rates)
            % with size nTrials x nChannels x nTime.
            % These should be total counts, not normalized rates,
            % as they will be added together during re-binning.
            out.counts = spikes;
            % (Optional):
            % A vector of timepoints with length nTime in
            % milliseconds associated with each time bin in counts.
            % You can start this wherever you like, but timeVecMs(2) - timeVecMs(1)
            % will be treated as the raw spike bin width used when the data are later
            % rebinned to match r.params.spikeBinMs. Default is 1:size(counts, 3).
            out.timeVecMs = 0:1:1999;
            % (Optional):
            %     Vector with length nTrials identifying the condition to which each 
            % trial belongs. This can either be a cell array of strings
            % or a numeric vector. Default is [].
            out.conditionId = zeros(1, trials-1);
            % For synthetic datasets, provides the ground-truth counts for each trial. 
            % Same size as .counts. Default is [].
            out.truth = [];
        end
    end
end
function array = mergeArrays(firstArray, secondArray)
    array = [firstArray secondArray];
end
% Returns: the correctly sorted and matched
% spikes
function outputSpikes = generateMergedSpikes(individulTrial)
    DT = 1;
    spikeData = individulTrial.TrialData.spikes;
    allChannels = cell2mat({spikeData.channel});
    numberOfChannels = allChannels(end);
    % filter out noise code 31, and keep the rest
    filteredSpikes = spikeData([[spikeData.sort]<31]);
    outputSpikes = [];
    min_time = 0;
    max_time = 2000;
    dt = DT;
    bin_edges = min_time:dt:max_time;
    outputSpikes = zeros(numberOfChannels, size(bin_edges, 2)-1);

    % iterate through all the channels and merge all the other codes
    for i=1:numberOfChannels
        % spikes for the current channel
        currentChannelFilter = [[filteredSpikes.channel] == i];
        spikesForChannel = filteredSpikes(currentChannelFilter);
        %iterate through all the arrays in this channel
        %outputSpikes(i) = [];
        currentSpikes = [];
        sizeOfChannels = size(spikesForChannel);
        for row=1:sizeOfChannels(2)
            currentSpikes = mergeArrays(currentSpikes, spikesForChannel(row).timestamps);
        end
        counts = histcounts(currentSpikes, bin_edges);
        outputSpikes(i, :) = counts;
    end
end
