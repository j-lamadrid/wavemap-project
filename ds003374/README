# Dataset of neurons and intracranial EEG from human amygdala during aversive dynamic visual stimulation

## Summary
We present an electrophysiological dataset collected from the amygdalae of nine subjects attending a visual dynamic stimulation of emotional aversive content. The subjects were patients affected by epilepsy who underwent preoperative invasive monitoring in the mesial temporal lobe. Subjects were presented with dynamic visual sequences of fearful faces (aversive condition), interleaved with sequences of neutral landscapes (neutral condition).

We provide the recordings of intracranial EEG (iEEG) and metadata related to the task, subjects, sessions and electrodes in the BIDS standard.

We also provide a more extended version of the dataset that includes neuronal spike times and waveforms in the NIX standard under the folder "bidsignore/data_NIX". This extended dataset is also available in G-Node at https://gin.g-node.org/USZ_NCH/Human_Amygdala_MUA_sEEG_FearVideo/.

This dataset allows the investigation of amygdalar response to dynamic aversive stimuli at multiple spatial scales, from the macroscopic EEG to the neuronal firing in the human brain.

## Repository structure

### Main directory
Contains metadata in the BIDS standard. 

### Directories sub-**
Contains folders for each subject, named sub-<subject number>.

### Directory bidsignore
Contains data in the NIX standard, and metadata files. Subject_Characteristics.pdf describes subjects and NIX_File_Structure.pdf describes the structure of the NIX files.

#### Directory code_MATLAB
Contains MATLAB code for loading the data and generating the publication figures. Main_Load_NIX_Data.m contains code snippets for reading NIX data and task related information. Main_Plot_Figures.m uses the functions Figure_2.m and Figure_3.m to generate figures.

Required dependencies to run the script Main_Load_NIX_Data.m:

*  [Nix-mx v1.4.1](https://github.com/G-Node/nix-mx/)

Required dependencies to run the script Main_Plot_Figures.m:

*  [Nix-mx v1.4.1](https://github.com/G-Node/nix-mx/)
*  [Gramm](https://github.com/piermorel/gramm/)
*  [FieldTrip](http://www.fieldtriptoolbox.org/download/)

#### Directory data_NIX
Contains nix files for each session of the task. Each file is named with the format:  
Data\_Subject\_\<subject number>\_Session\_\<session number>.h5

## Support
For questions on the dataset or the task, contact Johannes Sarnthein at [johannes.sarnthein@usz.ch](johannes.sarnthein@usz.ch).