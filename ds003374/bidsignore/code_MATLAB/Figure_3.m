function fig = Figure_3( strNIXFolderPath )

% Figure_3.m reproduces Figure 3 in the dataset publication
% fig = Figure_3(strNIXFolderPath) reproduces Figure 3
% strNIXFolderPath is the path of the folder with NIX files
% fig is the figure handle
%
% Add the toolbox 'gramm' to the MATLAB path
% The toolbox can be downloaded from https://github.com/piermorel/gramm
%
% Add the toolbox 'FieldTrip' to the MATLAB path
% The toolbox can be downloaded from http://www.fieldtriptoolbox.org/download

chs = [1,3,5,6,8,10,12]; % healthy amygdalae
nTotalNumberOfChannels = 0;
PSD_aversive = [];
PSD_neutral = [];
for nSubject = 1:9
    file_name = sprintf('Data_Subject_%.2d_Session_01.h5',nSubject);
    f = nix.File([strNIXFolderPath,filesep,file_name],nix.FileMode.ReadOnly);
    
    sectionSession = f.openSection('Session');
    all_trials = sectionSession.openProperty('Number of trials').values{1}.value;
    
    block = f.blocks{1};
    group_iEEG = block.openGroup('iEEG data');
    
    dataMacro = [];
    for nTrial = 1:all_trials
        dataArray_iEEG = group_iEEG.dataArrays{nTrial};
        striEEGLabels = dataArray_iEEG.dimensions{1}.labels;
        if(length(dataArray_iEEG.dataExtent)==2)
            tiEEG = (0:(double(dataArray_iEEG.dataExtent(2))-1))*dataArray_iEEG.dimensions{2}.samplingInterval+dataArray_iEEG.dimensions{2}.offset;
        else
            tiEEG = (0:(double(dataArray_iEEG.dataExtent(1))-1))*dataArray_iEEG.dimensions{2}.samplingInterval+dataArray_iEEG.dimensions{2}.offset;
        end
        data_iEEG = dataArray_iEEG.readAllData;
        dataMacro.time{1,nTrial} = tiEEG;
        dataMacro.trial{1,nTrial} = data_iEEG;
    end
    dataMacro.label = striEEGLabels';
    dataMacro.fsample = 2000;
    
    %% Power spectrum with FieldTrip
    cfg              = [];
    cfg.output       = 'pow';
    cfg.method       = 'mtmconvol';
    cfg.taper        = 'hanning';
    cfg.keeptrials   = 'yes';
    cfg.foi          = logspace(log10(1),log10(100),30);
    cfg.foi          = linspace( 1, 100 ,50);
    cfg.t_ftimwin    = 5./cfg.foi;   % length of time window = 0.5 sec
    cfg.toi          = -5:0.1:24;
    cfg.trials       = 2:2:17;
    TFR_face         = ft_freqanalysis(cfg, dataMacro);
    cfg.trials       = 1:2:17;
    TFR_land         = ft_freqanalysis(cfg, dataMacro );
    
    
    ch = 1:length(TFR_land.label);
    ff = TFR_land.freq;
    
    pwr_face  = squeeze(nanmean(TFR_face.powspctrm(:,ch,:,:)));
    pwr_land  = squeeze(nanmean(TFR_land.powspctrm(:,ch,:,:)));
    
    psd_face  = nanmean(pwr_face,length(size(pwr_face)));
    psd_land  = nanmean(pwr_land,length(size(pwr_land)));
    PSD_aversive(nTotalNumberOfChannels+ch,:) = psd_face;
    PSD_neutral(nTotalNumberOfChannels+ch,:) = psd_land;
    nTotalNumberOfChannels = nTotalNumberOfChannels+ch(end);
    
end

%% Plot Figure 3
fig = figure;
fig.Units = 'centimeters';
fig.Position(3:4) = [12,10];
data = [PSD_aversive(chs,:);PSD_neutral(chs,:)];
cval = {'Aversive','Neutral'};
cind = [ones(nTotalNumberOfChannels/2,1)*1;ones(nTotalNumberOfChannels/2,1)*2];
c = cval(cind);
g = gramm('x',ff,'y',data,'color',c);
custom_statfun = @(y)([10*log10(nanmean(y));
    10*log10(nanmean(y))-nanstd(10*log10(nanmean(y)))/sqrt(8*6);
    10*log10(nanmean(y))+nanstd(10*log10(nanmean(y)))/sqrt(8*6)]);
g.stat_summary('setylim',true,'type',custom_statfun);
g.set_names('x','Frequency (Hz)','y','Power (dB)','Color','');
g.axe_property('XLim',[-4,105],'YLim',[-2,18],'YTick',0:4:16,'XColor','k','YColor','k','TickDir','out','TickLength',[0.02,0.0250],...
    'FontName','Arial','FontSize',10);
g.set_layout_options('Legend_Position',[0.7,0.7,0.25,0.3]);
g.set_text_options('Font','Arial');
g.set_color_options('map',[1,0,0;0,0,1],'n_color',2,'n_lightness',1);
g.draw();

g.legend_axe_handle.FontName = 'Arial';

% Save figure
print('-dpdf','-r600','-painters','Fig3.pdf');
print('-dpng','-r600','-painters','Fig3.png');

end