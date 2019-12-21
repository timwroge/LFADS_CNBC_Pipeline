# LFADS CNBC Pipline
------------------------------
In order to interface with the LFADS software, a matlab class must be created that
takes a input data format (such as `.mat`) and outputs a instance of firing rates and other
data from the trial in order to run the software and create the latent factor analysis instance.

## Example: Lorenz Dataset
The LFADS software includes an example synthetic dataset and an example class that reads that dataset.

The code for the matlab instance for the batista lab is given based off this program.

## Using this pipeline
Just clone this repository into some place like a directory called `+CNBCPipeline` or for a specific
experiment, `+NelsonHandExperiment`. From there, the run method should be modified to referenece the 
experiment's specific datasets.
