% Identify the datasets you'll be using
% Here we'll add one at ~/lorenz_example/datasets/dataset001.mat
[full_file_path, ~, ~] = fileparts(mfilename('fullpath'))
dc = CNBCPipeline.DatasetCollection(strcat(full_file_path, 'experiment/data'));
dc.name = 'generic-pipeline-example';
ds = CNBCPipeline.Dataset(dc, 'Nelson20160111handControl_translated20171215'); % adds this dataset to the collection
dc.loadInfo; % loads dataset metadata

% Run a single model for each dataset, and one stitched run with all datasets
runRoot = strcat(full_file_path, 'experiment/runs');
rc = CNBCPipeline.RunCollection(runRoot, 'example', dc);

% run files will live at ~/lorenz_example/runs/example/

% Setup hyperparameters, 4 sets with number of factors swept through 2,4,6,8
par = CNBCPipeline.RunParams;
par.spikeBinMs = 2; % rebin the data at 2 ms
par.c_co_dim = 0; % no controller outputs --> no inputs to generator
par.c_batch_size = 150; % must be < 1/5 of the min trial count
par.c_gen_dim = 64; % number of units in generator RNN
par.c_ic_enc_dim = 64; % number of units in encoder RNN
par.c_learning_rate_stop = 1e-3; % we can stop really early for the demo
parSet = par.generateSweep('c_factors_dim', [2 4 6 8]);
rc.addParams(parSet);


% Setup which datasets are included in each run, here just the one
runName = dc.datasets(1).getSingleRunName();
rc.addRunSpec(CNBCPipeline.RunSpec(runName, dc, 1));

% Generate files needed for LFADS input on disk
rc.prepareForLFADS(true);

% Write a python script that will train all of the LFADS runs using a
% load-balancer against the available CPUs and GPUs
rc.writeShellScriptRunQueue('display', 0, 'virtualenv', 'tensorflow' );
