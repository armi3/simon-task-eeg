%% 1. Initialize EEGLAB
clc; clear; close all;
eeglab;

% Define subjects and datasets
subjects = {'sub_100', 'sub_101'};
raw_files = {'sub_100_Simon_eeg.set', 'sub_101_Simon_eeg.set'};
preprocessed_files = {'sub_100_preprocessed_manual.set', 'sub_101_preprocessed_manual.set'};

% Set relative path (assumes script is in the parent directory of 'datasets/')
data_path = fullfile(pwd, 'datasets');

%% 2. Loop Through Subjects for Manual Preprocessing
for i = 1:length(subjects)
    fprintf('Processing %s...\n', subjects{i});

    % Load raw dataset
    EEG = pop_loadset('filename', raw_files{i}, 'filepath', data_path);

    % Manually inspect raw EEG before preprocessing
    fprintf('Plotting and pausing 10s to allow quick inspection of %s before preprocessing...\n', subjects{i});
    pop_eegplot(EEG, 1, 1, 1);
    pause(10); % Pause to allow manual inspection
    close all; % Close all figures

    % Remove defective channels (subject-specific)
    if strcmp(subjects{i}, 'sub_100')
        EEG = pop_select(EEG, 'rmchannel', {'F4', 'TP8'});
    elseif strcmp(subjects{i}, 'sub_101')
        EEG = pop_select(EEG, 'rmchannel', {'TP8'});
    end

    % Remove artifacts (subject-specific epochs)
    if strcmp(subjects{i}, 'sub_100')
        EEG = eeg_eegrej(EEG, [5 21422;53250 55441;110868 118063;216533 220424]);
    elseif strcmp(subjects{i}, 'sub_101')
        EEG = eeg_eegrej(EEG, [4 8334; 22702 23513; 26714 27606; 63075 67311; 80483 81554;
        88137 92987; 94828 96353; 97266 98085; 99124 101720; 109811 133878;
        146918 147648; 157191 158077; 192211 194494; 218946 220112;
        229535 231346; 234704 238740]);
    end

    % Save final manually preprocessed dataset
    EEG = pop_saveset(EEG, 'filename', preprocessed_files{i}, 'filepath', data_path);
    fprintf('Manual preprocessing complete: Saved as %s\n', preprocessed_files{i});

    %% 3. Display Final EEG Plot (For Quality Check)
    fprintf('Displaying plot for %s and pausing 10s to allow quick inspection...\n', subjects{i});
    pop_eegplot(EEG, 1, 1, 1);
    pause(10); % Pause to allow manual inspection
    close all; % Close all figures
end

% Redraw EEGLAB GUI
eeglab redraw;
