# simon-task-eeg
🧠 ERP analysis of EEG data from Simon task recordings.

## 📄 Description
This repository contains a fully automated EEG processing and analysis pipeline for extracting and analyzing N2 waveforms (~200–350 ms) at frontocentral electrodes (Fz, FCz, Cz).

The script processes EEG data from raw ´.set´ files, applies preprocessing steps, and extracts event-related potentials (ERPs) for congruent (S1) and incongruent (S2) trials in the Simon task.

## 📂 Running the pipeline
This is how the repo is structured:
```
/simon-task-eeg/
├── datasets/                          # EEG datasets (input & output)
│   ├── sub_100_Simon_eeg.set          # Raw EEG data (Subject 100)
│   ├── sub_101_Simon_eeg.set          # Raw EEG data (Subject 101)
├── img/
│   ├── n2_avg.png
│   ├── n2_separate.png
├── pipeline_1_preprocess_manual.m
├── pipeline_2_preprocess_automated.m
├── pipeline_3_preprocess_analysis.m
├── pipeline_full.m
├── report.pdf
```

And this is a simplified example on how to place the pipeline scripts in order to run them in Matlab's EEGLAB:
```
/eeglab2024.2/
├── datasets/
│   ├── sub_100_Simon_eeg.set
│   ├── sub_101_Simon_eeg.set
├── eeglab.m
├── pipeline_full.m
...
```

After placing the `pipeline_full.m` in the EEGLAB directory, run in Matlab's console:
```
pipeline_full
```
