experiment_path = '~/Documents/LFADS/lorenz-example';

initialize_lfads
dataPath = experiment_path + '/datasets';
dc = LorenzExperiment.DatasetCollection(dataPath);
dc.name = 'lorenz-example';
LorenzExperiment.Dataset(dc, 'dataset001.mat');

runRoot = experiment_path+'/runs';
rc = LorenzExperiment.RunCollection(runRoot, 'exampleSingleRun', dc);

rc.version = 20180131;
par = LorenzExperiment.RunParams;
par.spikeBinMs = 2; % rebin the data at 2 ms
par.c_co_dim = 0; % no controller outputs --> no inputs to generator
par.c_batch_size = 150; % must be < 1/5 of the min trial count
par.c_gen_dim = 64; % number of units in generator RNN
par.c_ic_enc_dim = 64; % number of units in encoder RNN
par.c_learning_rate_stop = 1e-3; % we can stop really early for the demo
parSet = par.generateSweep('c_factors_dim', [2 4 6 8]);
rc.addParams(parSet);

% Setup which datasets are included in each run, here just the one
runName = dc.datasets(1).getSingleRunName(); % == 'single_dataset001'
rc.addRunSpec(LorenzExperiment.RunSpec(runName, dc, 1));


run1 = rc.findRuns('single_dataset001', 'param_UEvXAB');
pm = run1.loadPosteriorMeans();

times = pm.time;
figure

colorMapping=jet(10);

for i= 1:10
    for ii = 1:28
        factor = squeeze(pm.factors(1, :, pm.conditionIds == i ));
        hold on,plot(times, factor(:,ii),...
             'Color', colorMapping(i, :));
    end
end
xlabel('Time (ms)');
ylabel('Factor 1');
title('Posterior Means');

