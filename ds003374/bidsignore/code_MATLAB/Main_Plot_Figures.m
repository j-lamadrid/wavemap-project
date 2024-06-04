%% Close all figures, clear variables and command window
close all
clear
clc

%% Directory of the repository and the NIX library
% Download the BIDS directory to a folder named 'ieeg_jokeit' (or any other chosen name)
strMainPath = 'ieeg_jokeit';
strNIXLibraryPath = 'nix-mx_Win64_1.4.1'; % or 'nix_mx_macOS_1.4.2_Matlab2020a'
strFieldTripPath = 'fieldtrip-20200315';
strGrammPath = 'gramm-master'; % https://github.com/piermorel/gramm

%% Add necessary folders to the MATLAB path
addpath([strMainPath,filesep,'bidsignore',filesep,'code_MATLAB',filesep])
addpath(genpath(strNIXLibraryPath))
addpath(strFieldTripPath)
addpath(strGrammPath)
ft_defaults

warning('strMainPath should be the full path of the folder for the repository ieeg_jokeit')
warning('strNIXLibraryPath should be the full path of the NIX library ''nix-mx_Win64_1.4.1''')
warning('strFieldTripPath should be the full path of the FieldTrip toolbox ''fieldtrip-2020xxxx''')
warning('strGrammPath should be the full path of the Gramm toolbox ''gramm-master''')

%% NIX data files
strNIXFileNames = dir([strMainPath,filesep,'bidsignore',filesep,'data_NIX',filesep,'*.h5']);
strNIXFileNames = {strNIXFileNames.name}';

assert(~isempty(strNIXFileNames),'strMainPath should be the full path of the folder ieeg_jokeit')

%% Figure 2
nExampleNeuron = 32; % neuron 32 reproduces the publication figure
fig2 = Figure_2([strMainPath,filesep,'bidsignore',filesep,'data_NIX',filesep],nExampleNeuron);

%% Figure 3
fig3 = Figure_3([strMainPath,filesep,'bidsignore',filesep,'data_NIX',filesep]);