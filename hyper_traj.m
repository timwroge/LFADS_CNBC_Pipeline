% Identify the datasets you'll be using

% Here we'll add one at ~/lorenz_example/datasets/dataset001.mat
[full_file_path, ~, ~] = fileparts(mfilename('fullpath'));
instance = 'Nelson20160111handControl_translated20171215';
%dataset_name = strcat(full_file_path , '/experiment/data/datasets/', instance, '.mat');
dataset_name = strcat(full_file_path , '/experiment/data/datasets/', instance, '.mat');

PRELOAD_DATA = true;

if (exist('dc', 'var') & PRELOAD_DATA)
	% ds is in the workspace
	disp('Dataset found in workspace');
	dc=evalin('base', 'dc');
else
    dc = CNBCPipeline.DatasetCollection(strcat(full_file_path, '/experiment/data/datasets/'));
    dc.name = 'generic-pipeline-example';
    ds = CNBCPipeline.Dataset(dc, 'Nelson20160111handControl_translated20171215'); % adds this dataset to the collection
    dc.loadInfo; % loads dataset metadata
end



disp('Loading File for post analysis');
if (exist('postAnalysisDataset', 'var') & PRELOAD_DATA)
	disp('Dataset found in workspace');
	% ds is in the workspace
	postAnalysisDataset=evalin('base', 'postAnalysisDataset');
else
	disp('Loading again from scratch');
	postAnalysisDataset  = load(dataset_name);
	postAnalysisDataset = postAnalysisDataset.Data;
end


% Run a single model for each dataset, and one stitched run with all datasets
runRoot = strcat(full_file_path, '/experiment/runs');
rc = CNBCPipeline.RunCollection(runRoot, 'hyperparametertuning', dc);

% run files will live at ~/lorenz_example/runs/example/

% Setup hyperparameters, 4 sets with number of factors swept through 2,4,6,8
par = CNBCPipeline.RunParams;
par.spikeBinMs = 2; % rebin the data at 2 ms
par.c_co_dim = 0; % no controller outputs --> no inputs to generator
par.c_batch_size = 150; % must be < 1/5 of the min trial count
par.c_gen_dim = 100; % number of units in generator RNN
par.c_ic_enc_dim = 100; % number of units in encoder RNN
par.c_learning_rate_stop = 1e-6; % we can stop really early for the demo
parSet = par.generateSweep('c_factors_dim', [11]);
rc.addParams(parSet);

% Setup which datasets are included in each run, here just the one
runName = dc.datasets(1).getSingleRunName();
rc.addRunSpec(CNBCPipeline.RunSpec(runName, dc, 1));

% run1 = rc.findRuns(runName, 'param_kVGN2Y');
run1 = rc.findRuns(runName, 'param_cjT1uT');

pm = run1.loadPosteriorMeans();

times = pm.time;
figure
disp('Making figure now' )

factors = pm.factors;

factorSize = size(factors);
numberOfFactors=factorSize( 1);
timePoints=factorSize(2);
numTrials=factorSize(2);


% find the task conditions
numTaskConditions = 8;
taskConditions = [];
taskAngles = -135:45:180;
reachStarts = [] ;
reachEnds = [] ;

for trial = 1:numTrials
    %find the angle for the trial
    table= postAnalysisDataset(trial).Parameters.StateTable(4).StateTargets.location;
    collapsed = table(2, :) - table(1, :);
    angle = atan2d(collapsed(1) , collapsed(2));
    taskConditions(trial) = angle;
    %find the reach times for the trial
    reachStarts(trial)  = postAnalysisDataset(trial) .TrialData.stateTransitions(2,3);
    reachEnds(trial)  = postAnalysisDataset(trial) .TrialData.stateTransitions(2,4);
    withinReach(trial, :) = [( times <= reachEnds(trial) ) & ( times >= reachStarts(trial)) ];
end

colorMapping=jet(numTaskConditions);


for i = 1:numTaskConditions
    for j = 1:numTrials
        if(taskAngles(i) == taskConditions(j))
            factor_x = factors(1, withinReach(j, :) , j);
            factor_y = factors(2, withinReach(j, :) , j);
            factor_z = factors(3, withinReach(j, :) , j);
            if(~isempty(factor_x)  & ~isempty( factor_y) & ~isempty(factor_z) )
                %%draw starting points
                %hold on,scatter3([ factor_x(1)] , [ factor_y(1) ], [ factor_z(1)] ,...
                %     'filled' , 'MarkerFaceColor', colorMapping(i, :));
                %%% %draw end points
                %hold on,scatter3([ factor_x(end)] , [  factor_y(end)] , [ factor_z(end)] ,...
                %'*' , 'MarkerFaceColor', colorMapping(i, :) );
                hold on,plot3(factor_x, factor_y, factor_z,...
                     'Color', colorMapping(i, :));
            end
         end
     end
end

xlabel('Factor 1');
ylabel('Factor 2');
zlabel('Factor 3');
title('Trajectory based on task');
disp('Saving figure' )
savefig('hyper_traj_456.fig');
disp('Figure saved' )
