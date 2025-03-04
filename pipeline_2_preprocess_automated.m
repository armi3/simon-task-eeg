%% 1. Initialize EEGLAB
% Clears workspace, closes figures, and launches EEGLAB.
clc; clear; close all;
eeglab nogui;

% Define subjects and input/output filenames
subjects = {'sub_100', 'sub_101'};
manual_files = {'sub_100_preprocessed_manual.set', 'sub_101_preprocessed_manual.set'};
final_files = {'sub_100_preprocessed.set', 'sub_101_preprocessed.set'};

% Set relative path (assumes script is in the parent directory of 'datasets/')
data_path = fullfile(pwd, 'datasets');

%% 2. Loop Through Subjects for Automated Preprocessing
for i = 1:length(subjects)
    fprintf('Processing %s...\n', subjects{i});

    % Load manually preprocessed dataset
    EEG = pop_loadset('filename', manual_files{i}, 'filepath', data_path);

    % 🔹 Register the dataset in EEGLAB
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);
    eeglab('redraw'); % Refresh EEGLAB dataset list

    %% 🔹 Clean Event Marker Names
    % Ensures event types are correctly formatted (removes spaces & converts numbers to strings).
    for e = 1:length(EEG.event)
        if ischar(EEG.event(e).type)
            EEG.event(e).type = strtrim(EEG.event(e).type); % Remove leading/trailing spaces
            EEG.event(e).type = strrep(EEG.event(e).type, ' ', ''); % Remove extra spaces within names
        elseif isnumeric(EEG.event(e).type)
            EEG.event(e).type = num2str(EEG.event(e).type); % Convert numeric event codes to strings
        end
    end

    % Display cleaned event types for verification
    disp('Event types found in EEG after cleaning:');
    disp(unique({EEG.event.type}));

    %% 🔹 Step 3: Band-Pass Filtering (1–30 Hz)
    % Applies a zero-phase FIR filter (Kaiser Window) to remove slow drifts (<1 Hz) and high-frequency noise (>30 Hz).
    EEG = pop_eegfiltnew(EEG, 1, 30, [], 0, [], 0.01);

    %% 🔹 Step 4: Re-Referencing (Average Reference)
    % Computes an average reference across all electrodes to normalize signals.
    EEG = pop_reref(EEG, []);

    %% 🔹 Step 5: Interpolating Missing Channels
    % Restores previously removed bad electrodes using spherical interpolation.
    EEG = pop_interp(EEG, EEG.chanlocs, 'spherical');

    %% 🔹 Step 6: Count S1 and S2 Trials Before Epoching
    % Ensures that sufficient stimulus-locked trials exist before epoching.
    num_S1 = sum(strcmp({EEG.event.type}, 'S1'));
    num_S2 = sum(strcmp({EEG.event.type}, 'S2'));

    fprintf('Number of S1 trials remaining: %d\n', num_S1);
    fprintf('Number of S2 trials remaining: %d\n', num_S2);

    %% 🔹 Step 7: Extract Epochs (Stimulus-Locked to S1 and S2)
    % Segments EEG data around stimulus onset (-300 ms pre-stimulus to +700 ms post-stimulus).
    if num_S1 > 0 || num_S2 > 0
        EEG = pop_epoch(EEG, {'S1', 'S2'}, [-0.3 0.7]);
    else
        error('No S1 or S2 events found after artifact rejection. Check preprocessing.');
    end

    %% 🔹 Step 8: Baseline Correction (-300 ms to 0 ms)
    % Removes slow voltage drifts by subtracting the mean signal from the pre-stimulus period (-300 to 0 ms).
    EEG = pop_rmbase(EEG, [-300 0]);

    %% 🔹 Step 9: Save Final Preprocessed Dataset
    % Saves the fully preprocessed dataset for further ERP analysis.
    EEG = pop_saveset(EEG, 'filename', final_files{i}, 'filepath', data_path);
    fprintf('Automated preprocessing complete: Saved as %s\n', final_files{i});
end

close all;


