%% Close all figures, clear variables and command window
close all
clear
clc

%% Directory of the repository and the NIX library
% Download the BIDS directory to a folder named 'ieeg_jokeit' (or any other chosen name)
strMainPath = 'ieeg_jokeit';
strNIXLibraryPath = 'nix-mx_Win64_1.4.1'; % or 'nix_mx_macOS_1.4.2_Matlab2020a'

%% Add necessary folders to the MATLAB path
addpath([strMainPath,filesep,'bidsignore',filesep,'code_MATLAB',filesep])
addpath(genpath(strNIXLibraryPath))

warning('strMainPath should be the full path of the folder for the repository ieeg_jokeit')
warning('strNIXLibraryPath should be the full path of the NIX library ''nix-mx_Win64_1.4.1''')

%% NIX data files
strNIXFileNames = dir([strMainPath,filesep,'bidsignore',filesep,'data_NIX',filesep,'*.h5']);
strNIXFileNames = {strNIXFileNames.name}';

assert(~isempty(strNIXFileNames),'strMainPath should be the full path of the folder ieeg_jokeit')

%% Select NIX file to open
nFile = 1;

%% Open NIX file
strFilePath = [strMainPath,filesep,'bidsignore',filesep,'data_NIX',filesep,strNIXFileNames{nFile}];
try
    f = nix.File(strFilePath,nix.FileMode.ReadOnly);
catch s
    if(strcmpi(s.message,'Undefined variable "nix" or class "nix.FileMode.ReadOnly".'))
        error('strNIXLibraryPath should be the full path of the NIX library ''nix-mx_Win64_1.4.1''')
    else
        error(s.message)
    end
end

%% Read metadata
% Display names of all sections
cellfun(@(x) disp(x.name),f.sections)

%% General information
sectionGeneral = f.openSection('General');
% Properties
cellfun(@(x) disp(x.name),sectionGeneral.properties)
% Institution
fprintf(['Institution: ',sectionGeneral.openProperty('Institution').values{1}.value,'\n'])
% Recording location
fprintf(['Recording location: ',sectionGeneral.openProperty('Recording location').values{1}.value,'\n'])
% Sections
cellfun(@(x) disp(x.name),sectionGeneral.sections)
% Publications
sectionPublications = sectionGeneral.openSection('Related publications');
cellfun(@(x) disp(x.name),sectionPublications.properties)
fprintf(['Publication name: ',sectionPublications.openProperty('Publication name').values{1}.value,'\n'])
fprintf(['Publication DOI: ',sectionPublications.openProperty('Publication DOI').values{1}.value,'\n'])
% Recording setup
sectionRecordingSetup = sectionGeneral.openSection('Recording setup');
cellfun(@(x) disp(x.name),sectionRecordingSetup.properties)
fprintf(['Recording setup iEEG: ',sectionRecordingSetup.openProperty('Recording setup iEEG').values{1}.value,'\n'])

%% Task information
sectionTask = f.openSection('Task');
% Properties
cellfun(@(x) disp(x.name),sectionTask.properties)
% Task characteristics
fprintf(['Task name: ',sectionTask.openProperty('Task name').values{1}.value,'\n'])
fprintf(['Task description: ',sectionTask.openProperty('Task description').values{1}.value,'\n'])
fprintf(['Task URL: ',sectionTask.openProperty('Task URL').values{1}.value,'\n']) % TODO

%% Subject information
sectionSubject = f.openSection('Subject');
% Properties
cellfun(@(x) disp(x.name),sectionSubject.properties)
% Subject characteristics
fprintf(['Age: ',num2str(sectionSubject.openProperty('Age').values{1}.value),'\n'])
fprintf(['Gender: ',sectionSubject.openProperty('Gender').values{1}.value,'\n']) % Sex?
fprintf(['Pathology: ',sectionSubject.openProperty('Pathology').values{1}.value,'\n'])
fprintf(['Depth electrodes: ',sectionSubject.openProperty('Depth electrodes').values{1}.value,'\n'])
fprintf(['Electrodes in seizure onset zone (SOZ): ',sectionSubject.openProperty('Electrodes in seizure onset zone (SOZ)').values{1}.value,'\n'])

%% Session information
sectionSession = f.openSection('Session');
% Properties
cellfun(@(x) disp(x.name),sectionSession.properties)
% Session characteristics
fprintf(['Number of trials: ',num2str(sectionSession.openProperty('Number of trials').values{1}.value),'\n'])
fprintf(['Trial duration: ',num2str(sectionSession.openProperty('Trial duration').values{1}.value),' ',sectionSession.openProperty('Trial duration').unit,'\n'])
% Sections
cellfun(@(x) disp(x.name),sectionSession.sections)

%% Trial information
sectionTrialProperties = sectionSession.openSection('Trial properties');
% Sections
cellfun(@(x) disp(x.name),sectionTrialProperties.sections)
% Each section is for a single trial
% Select trial
nTrial = 1;
sectionSingleTrial = sectionTrialProperties.sections{nTrial};

%% Single trial
% Properties
cellfun(@(x) disp(x.name),sectionSingleTrial.properties)
for nProperty = 1:length(sectionSingleTrial.properties)
    switch sectionSingleTrial.properties{nProperty}.datatype
        case {'double','logical'}
            fprintf([sectionSingleTrial.properties{nProperty}.name,': ',num2str(sectionSingleTrial.properties{nProperty}.values{1}.value),'\n'])
        otherwise
            fprintf([sectionSingleTrial.properties{nProperty}.name,': ',sectionSingleTrial.properties{nProperty}.values{1}.value,'\n'])
    end
end

%% Blocks
cellfun(@(x) disp(x.name),f.blocks)
block = f.blocks{1};

%% Groups of data arrays, tags, multitags
groups = block.groups;
cellfun(@(x) disp(x.name),block.groups)

%% Select trial
nTrial = 1;

%% Trial events
group_TrialEvents_iEEG = block.openGroup('Trial events single tags iEEG');

%% Trial events for a single trial
indTrialTags_iEEG = contains(cellfun(@(x) x.name,group_TrialEvents_iEEG.tags,'UniformOutput',0),['Trial_',num2str(nTrial,'%.2d')]);

TrialEvents_iEEG = group_TrialEvents_iEEG.tags(indTrialTags_iEEG);

cellfun(@(x) disp(x.name),TrialEvents_iEEG)

%% Time of a single event
nSingleTag = 1; % Gives the single tag for the trial condition
fprintf(['Event name: ',TrialEvents_iEEG{nSingleTag}.name,'\n'])
fprintf([sprintf('Time w.r.t. fixation: %.1f %s',TrialEvents_iEEG{nSingleTag}.position(2),TrialEvents_iEEG{nSingleTag}.units{1}),'\n'])
fprintf([sprintf('Duration: %.1f %s',TrialEvents_iEEG{nSingleTag}.extent(2),TrialEvents_iEEG{nSingleTag}.units{1}),'\n'])

%% iEEG data
group_iEEG = block.openGroup('iEEG data');
% Data array
dataArray_iEEG = group_iEEG.dataArrays{nTrial};

% Electrode labels
striEEGLabels = dataArray_iEEG.dimensions{1}.labels;
% Time axis
if(length(dataArray_iEEG.dataExtent)==2)
    tiEEG = (0:(double(dataArray_iEEG.dataExtent(2))-1))*dataArray_iEEG.dimensions{2}.samplingInterval+dataArray_iEEG.dimensions{2}.offset;
else
    tiEEG = (0:(double(dataArray_iEEG.dataExtent(1))-1))*dataArray_iEEG.dimensions{2}.samplingInterval+dataArray_iEEG.dimensions{2}.offset;
end
% Read data
data_iEEG = dataArray_iEEG.readAllData;

% Plot trial data
figure
plot(tiEEG,data_iEEG)
title(['iEEG data - Trial ',num2str(nTrial)])
xlabel(['Time (',dataArray_iEEG.dimensions{2}.unit,')'])
ylabel(['Voltage (',dataArray_iEEG.unit,')'])
xlim([tiEEG(1),tiEEG(end)])
legend(striEEGLabels)

%% Electrode information
groupiEEGElecrodes = block.openGroup('iEEG electrode information');

%% Sources of the iEEG data
for nSource = 1:dataArray_iEEG.sourceCount
    sourceUnit = dataArray_iEEG.sources{nSource};
    % Electrode label
    sourceUnit.sources{1}.name
    % Anatomical location
    sourceUnit.sources{2}.name
    % Inside/outside SOZ
    sourceUnit.sources{3}.name
    
    nElectrode = find(strcmpi(cellfun(@(x) x.name,groupiEEGElecrodes.sources,'UniformOutput',0),sourceUnit.name));
    % MNI coordinates of the electrode
    groupiEEGElecrodes.multiTags{1}.retrieveFeatureData(nElectrode,'iEEG_Electrode_MNI_Coordinates')
end

%% Units
group_SpikeTimesMultitags = block.openGroup('Spike times multitags');

if(group_SpikeTimesMultitags.multiTagCount==0)
    warning('This subject does not have any units')
    
else
    %% Select unit and trial
    nUnit = 1;
    nTrial = 5;
    % MultiTag for the selected unit and trial
    indUnitSpikeTimes = contains(cellfun(@(x) x.name,group_SpikeTimesMultitags.multiTags,'UniformOutput',0),['Unit_',num2str(nUnit),'_'])&...
        contains(cellfun(@(x) x.name,group_SpikeTimesMultitags.multiTags,'UniformOutput',0),['Trial_',num2str(nTrial,'%.2d')]);
    multiTag_SpikeTimes = group_SpikeTimesMultitags.multiTags{indUnitSpikeTimes};
    
    %% Spike times
    dataArray_SpikeTimes = multiTag_SpikeTimes.openPositions;
    % Read data
    SpikeTimes = dataArray_SpikeTimes.readAllData;
    
    figure
    stem(dataArray_SpikeTimes.readAllData,ones(length(SpikeTimes),1))
    title(['Spike times - Unit ',num2str(nUnit),' - Trial ',num2str(nTrial)])
    xlabel(['Time (',dataArray_SpikeTimes.dimensions{1}.unit,')'])
    
    %% Waveform for the unit
    dataArray_Waveform = multiTag_SpikeTimes.features{1}.openData;
    % Time axis
    tWaveform = (0:(double(dataArray_Waveform.dataExtent(2))-1))*dataArray_Waveform.dimensions{2}.samplingInterval+dataArray_Waveform.dimensions{2}.offset;
    % Read data
    waveform = dataArray_Waveform.readAllData;
    % Plot
    figure
    plot(tWaveform,waveform(1,:),'b')
    hold on
    plot(tWaveform,waveform(1,:)+waveform(2,:),'b--')
    plot(tWaveform,waveform(1,:)-waveform(2,:),'b--')
    title(['Waveform - Unit ',num2str(nUnit)])
    xlabel(['Time (',dataArray_Waveform.dimensions{2}.unit,')'])
    ylabel(['Voltage (',dataArray_Waveform.unit,')'])
    legend({'Mean','Std'})
    
    %% Source of the unit
    sourceUnit = dataArray_SpikeTimes.sources{1};
    % Electrode label
    sourceUnit.sources{1}.name
    % Anatomical location
    sourceUnit.sources{2}.name
    % Inside/outside SOZ
    sourceUnit.sources{3}.name
    
    %% Use electrode map to get properties of the macroelectrode the unit is on
    nElectrode = find(strcmpi(cellfun(@(x) x.name,groupiEEGElecrodes.sources,'UniformOutput',0),sourceUnit.name));
    
    % MNI coordinates of the electrode
    groupiEEGElecrodes.multiTags{1}.retrieveFeatureData(nElectrode,'iEEG_Electrode_MNI_Coordinates')
    
end