classdef Dataset < LFADS.Dataset
    methods
        function ds = Dataset(collection, relPath)
            ds = ds@LFADS.Dataset(collection, relPath);
            % you might also wish to set ds.name here,
            % possibly by adding a third argument to the constructor
            % and assigning it to ds.name
        end

        function data = loadData(ds)
            % load this dataset's data file from .path
            disp(strcat('Loading data from:  ',ds.path));
            data = load(ds.path);
            data = preprocessData(data.Data, 'CHECKPHASESPACESYNC', false);
        end

        function loadInfo(ds, reload)
            % Load this Dataset's metadata if not already loaded
            disp('Checking if the data is loaded')
            if ds.infoLoaded
                return;
            end

            if nargin < 2
                reload = false;
            end
            if ds.infoLoaded && ~reload, return; end


            % modify this to extract the metadata loaded from the data file
            disp('Loading data, this may take a while')

            data = ds.loadData();
            ds.subject = 'Nelson';%data.subjet;
            disp('Finding save tags')
            ds.saveTags = 1;
            ds.datenum  = datenum(today);
            disp('Finding number of channels')
            allChannels = data(1).TrialData.spikes.channel;
            ds.nChannels = allChannels(end);
            disp('Finding number of trials')
            sizeOfData = size(data);
            ds.nTrials = sizeOfData(1);
            ds.infoLoaded = true;
        end

    end
end
