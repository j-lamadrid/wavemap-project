function fig = Figure_2( strNIXFolderPath, varargin )

% Figure_2.m reproduces Figure 2 in the dataset publication
% fig = Figure_2(strNIXFolderPath) reproduces Figure 2
% strNIXFolderPath is the path of the folder with NIX files
% fig is the figure handle
% Default neuron number plotted is 30
% fig = Figure_2(strNIXFolderPath,nNexampleNeuron) reproduces Figure 2 with the
% example neuron nNexampleNeuron
%
% Add the toolbox 'gramm' to the MATLAB path
% The toolbox can be downloaded from https://github.com/piermorel/gramm

% Example neuron
if(nargin>1)
    nExampleNeuron = varargin{1};
else
    nExampleNeuron = 30;
end

SPIKES_All = [];
% Load data for all neurons
for nSubject = 1:9
    % File name
    strNIXFileName = sprintf('Data_Subject_%.2d_Session_01.h5',nSubject);
    % Read the NIX file
    f = nix.File([strNIXFolderPath,filesep,strNIXFileName],nix.FileMode.ReadOnly);
    % NIX data
    block = f.blocks{1};
    % Multitags for spike times
    group_MultiTagsSpikes = block.openGroup('Spike times multitags');
    multiTags_SpikeTimes = group_MultiTagsSpikes.multiTags;
    
    % If there are no neurons, continue
    if(isempty(multiTags_SpikeTimes))
        continue;
    end
    % List of neurons and trials
    % Format for the name is
    % 'Multitag_Spike_Times_Unit_<neuron number>_<micro wire name>_Trial_<trial number>'
    strSpikeTimeLabels = cellfun(@(x) x.name,multiTags_SpikeTimes,'UniformOutput',0);
    strSpikeTimeLabels = cellfun(@(x) strsplit(x,'_'),strSpikeTimeLabels,'UniformOutput',0);
    nNeuronsTrialsList = [cell2mat(cellfun(@(x) str2double(x{5}),strSpikeTimeLabels,'UniformOutput',0)),...
        cell2mat(cellfun(@(x) str2double(x{9}),strSpikeTimeLabels,'UniformOutput',0))];
    ranNeurons = unique(nNeuronsTrialsList(:,1));
    ranTrials = unique(nNeuronsTrialsList(:,2));
    
    % Load spike times and waveforms for each neuron
    SPIKES = [];
    for iNeuron = 1:length(ranNeurons)
        nNeuron = ranNeurons(iNeuron);
        spikes = [];
        for iTrial = 1:length(ranTrials)
            nTrial = ranTrials(iTrial);
            nDataArray = (nNeuronsTrialsList(:,1)==nNeuron)&(nNeuronsTrialsList(:,2)==nTrial);
            % Data array for the selected neuron and trial
            dataArray = multiTags_SpikeTimes{nDataArray}.openPositions;
            % Read spike times
            spike_times = dataArray.readAllData';
            spikes = [spikes;[spike_times,nTrial*ones(length(spike_times),1)]];
        end
        % Store spike times and trial numbers
        SPIKES(iNeuron).spikes = spikes;
        
        % Read waveform for the selected neuron
        dataArray_Waveform = multiTags_SpikeTimes{nDataArray}.features{1}.openData;
        % Store waveforms
        SPIKES(iNeuron).waveform = dataArray_Waveform.readAllData';
    end
    SPIKES_All = [SPIKES_All,SPIKES];
end


%% Firing rates
FiringRatesHz = [];
tTrialDuration = 26; % seconds
for iNeuron = 1:length(SPIKES_All)
    nNumberOfTrials = max(SPIKES_All(iNeuron).spikes(:,2));
    FiringRatesHz = [FiringRatesHz,length(SPIKES_All(iNeuron).spikes(:,1))/(tTrialDuration*nNumberOfTrials)];
end

%% ISI
isis = [];
for iNeuron = 1:length(SPIKES_All)
    isis_ = [];
    for iTrial = 1:max(SPIKES_All(iNeuron).spikes(:,2))
        isis_ = [isis_;diff(sort(SPIKES_All(iNeuron).spikes(SPIKES_All(iNeuron).spikes(:,2)==iTrial,1))*1000)];
    end
    isis = [isis;(length(isis_(isis_<3))/length(isis_))*100];
end

%% SNR
snr = [];
waveform = [];
for iNeuron = 1:length(SPIKES_All)
    snr_0 = max(abs(SPIKES_All(iNeuron).waveform(:,1)))/mean(SPIKES_All(iNeuron).waveform(:,2));
    snr = [snr snr_0];
    waveform = [waveform;SPIKES_All(iNeuron).waveform(:,1)'];
end

FR = SPIKES_All(nExampleNeuron).spikes;

%% Firing rate for a single neuron
c = [];
tPre = -2;
tPost = 24;
binSize = 0.1;
ranTrials = {};
for i = 1:max(FR(:,2))
    for iCondition = [0,1] % 1 - aversive, 0 - neutral
        if(mod(i,2)==iCondition)
            spikeTimes = FR(FR(:,2) == i,1);
            ranTrials{i} = spikeTimes;
            % Trial conditions
            c = [c,iCondition+1];
            % Binned spikes
            temp = histc(spikeTimes,tPre:binSize:tPost);
            binned{i} = smooth(temp(1:end-1)/binSize,10);
            % Bin centers
            bins{i} = (tPre+binSize/2):binSize:(tPost-binSize/2);
        end
    end
end

%% Plot Figure 2
fig = figure;
fig.Units = 'centimeters';
fig.Position(2:4) = [5,16,16];
% Example neuron
% Firing rate
strTrialCondition = {'Aversive','Neutral'};
catTrialCondition = strTrialCondition(c);
g(1) = gramm('x',bins,'y',binned,'Color',catTrialCondition);
custom_statfun = @(y)([mean(y);
    mean(y)-std(y)/sqrt(17);
    mean(y)+std(y)/sqrt(17)]);
g(1).stat_summary('setylim',true,'type',custom_statfun);
g(1).set_names('x','','y','Rate (Hz)','Color','');
g(1).set_layout_options('position',[0.05,0.7,0.85,0.25],'Legend_Position',[0.16,0.85,0.25,0.15]);
g(1).set_color_options('map',[1,0,0;0,0,1],'n_color',2,'n_lightness',1);
g(1).axe_property('XLim',[tPre,tPost],'XTick',[],'YLim',[-1,10.5],'YTick',0:5:10,'XColor','none','YColor','k',...
    'FontName','Arial','FontSize',10,'TickDir','out','TickLength',[0.015,0.0250]);
% Spike shape
g(6) = gramm('x',((1:64)-20)/32,'y',waveform(nExampleNeuron,:));
g(6).geom_line();
g(6).set_names('x','Time (ms)','y','\muV');
g(6).set_layout_options('position',[0.75,0.85,0.13,0.12]);
g(6).set_text_options('base_size',4,'interpreter','tex');
% g(6).set_color_options('chroma',0,'lightness',30);
g(6).set_color_options('map',[0,0,0],'n_color',1,'n_lightness',1);
g(6).set_line_options('base_size',1);
g(6).no_legend();
g(6).axe_property('XLim',[(1-20)/32,(64-20)/32],'XTick',[0,1],'YTick',[0,30],'XColor','k','YColor','k',...
    'FontName','Arial','FontSize',7,'TickDir','out','TickLength',[0.08,0.0250]);
% Raster
g(2) = gramm('x',ranTrials,'Color',c);
g(2).geom_raster('geom','point');
g(2).set_point_options('base_size',3);
g(2).set_names('x','Time (s)','y','Trial no. (reordered)');
g(2).set_layout_options('position',[0.05,0.4,0.85,0.28]);
g(2).set_color_options('map',[1,0,0;0,0,1],'n_color',2,'n_lightness',1);
g(2).no_legend();
g(2).axe_property('XLim',[tPre,tPost],'YLim',[-1,11],'YTick',0:5:10,'XColor','k','YColor','k',...
    'FontName','Arial','FontSize',10,'TickDir','out','TickLength',[0.015,0.0250]);
% Spike sorting quality metrics
% ISI
g(3) = gramm('x',isis);
g(3).stat_bin();
g(3).set_layout_options('position',[0.05,0.1,0.25,0.25]);
g(3).set_names('x','Percentage of ISI < 3 ms','y','No. of neurons');
g(3).axe_property('XLim',[-0.15,3.7],'YLim',[0,7],'XColor','k','YColor','k',...
    'FontName','Arial','FontSize',10,'TickDir','out','TickLength',[0.03,0.0250]);
g(3).set_color_options('hue_range',[155,200]);
% Firing rate
g(4) = gramm('x',FiringRatesHz);
g(4).stat_bin();
g(4).set_layout_options('position',[0.35,0.1,0.25,0.25]);
g(4).set_names('x','Firing rate (Hz)','y','No. of neurons');
g(4).axe_property('XLim',[-0.8 20],'YLim',[0,7],'XColor','k','YColor','k',...
    'FontName','Arial','FontSize',10,'TickDir','out','TickLength',[0.03,0.0250]);
g(4).set_color_options('hue_range',[155,200]);
% SNR
g(5) = gramm('x',snr);
g(5).stat_bin();
g(5).set_layout_options('position',[0.65,0.1,0.25,0.25]);
g(5).set_names('x','Waveform peak SNR','y','No. of neurons');
g(5).axe_property('XLim',[-0.4,10],'YLim',[0,7],'XColor','k','YColor','k',...
    'FontName','Arial','FontSize',10,'TickDir','out','TickLength',[0.03,0.0250]);
g(5).set_color_options('hue_range',[155,200]);
% Labels
x = [0.02,0.02,0.34,0.66];
y = [0.98,0.35,0.35,0.35];
l = ['a','b','c','d'];
g(7) = gramm('x',x,'y',y,'label',l);
g(7).geom_label('Color','k','FontWeight','bold','FontName','Arial');
g(7).axe_property('XColor','none','YColor','none','XLim',[0,1],...
    'YLim',[0,1],'Visible','off');
g(7).set_layout_options('position',[0,0,1,1]);
g.draw();

yPosOffset = g(1).facet_axes_handles.Position(1)-g(3).facet_axes_handles.Position(1);
for iAx = 3:5
    g(iAx).facet_axes_handles.Position(1) = g(iAx).facet_axes_handles.Position(1)+yPosOffset;
end
% YLabel positions
for iAx = setdiff(1:7,[6,7])
    g(iAx).facet_axes_handles.YLabel.Units = 'centimeters';
    g(iAx).facet_axes_handles.YLabel.Position(1) = -0.8;
end

g(2).facet_axes_handles.Children(1).MarkerSize = 2.5;
g(2).facet_axes_handles.Children(2).MarkerSize = 2.5;

% Save figure
print('-dpdf','-r600','-painters','Fig2.pdf');
print('-dpng','-r600','-painters','Fig2.png');

end