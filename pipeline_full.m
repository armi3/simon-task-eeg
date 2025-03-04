%% =========================== 1. Initialize EEGLAB ===========================
clc; clear; close all;
eeglab nogui; % Prevent EEGLAB GUI from opening

% Define subjects and dataset filenames
subjects = {'sub_100', 'sub_101'};
raw_files = {'sub_100_Simon_eeg.set', 'sub_101_Simon_eeg.set'};
manual_files = {'sub_100_preprocessed_manual.set', 'sub_101_preprocessed_manual.set'};
final_files = {'sub_100_preprocessed.set', 'sub_101_preprocessed.set'};

% Set relative path (assumes script is in the parent directory of 'datasets/')
data_path = fullfile(pwd, 'datasets');

%% =========================== 2. Manual Preprocessing ===========================
fprintf('\n===== MANUAL PREPROCESSING =====\n');

for i = 1:length(subjects)
    fprintf('Processing %s (Manual Preprocessing)...\n', subjects{i});

    % Load raw dataset
    EEG = pop_loadset('filename', raw_files{i}, 'filepath', data_path);

    % Remove defective channels (subject-specific)
    if strcmp(subjects{i}, 'sub_100')
        EEG = pop_select(EEG, 'rmchannel', {'F4', 'TP8'});
    elseif strcmp(subjects{i}, 'sub_101')
        EEG = pop_select(EEG, 'rmchannel', {'TP8'});
    end

    % Remove artifacts (subject-specific epochs)
    if strcmp(subjects{i}, 'sub_100')
        EEG = eeg_eegrej(EEG, [5 2412; 4150 15524; 15528 21471; 53223 61948; 110751 118679; 216103 220424]);
    elseif strcmp(subjects{i}, 'sub_101')
        EEG = eeg_eegrej(EEG, [4 8334; 22702 23513; 26714 27606; 63075 67311; 80483 81554; 
                               88137 92987; 94828 96353; 97266 98085; 99124 101720; 109811 133878;
                               146918 147648; 157191 158077; 192211 194494; 218946 220112;
                               229535 231346; 234704 238740]);
    end

    % Save final manually preprocessed dataset
    EEG = pop_saveset(EEG, 'filename', manual_files{i}, 'filepath', data_path);
    fprintf('Manual preprocessing complete: Saved as %s\n', manual_files{i});
end

%% =========================== 3. Automated Preprocessing ===========================
fprintf('\n===== AUTOMATED PREPROCESSING =====\n');

for i = 1:length(subjects)
    fprintf('Processing %s (Automated Preprocessing)...\n', subjects{i});

    % Load manually preprocessed dataset
    EEG = pop_loadset('filename', manual_files{i}, 'filepath', data_path);

    % Standardize event markers (remove extra spaces)
    for e = 1:length(EEG.event)
        if ischar(EEG.event(e).type)
            EEG.event(e).type = strtrim(EEG.event(e).type);
            EEG.event(e).type = strrep(EEG.event(e).type, ' ', '');
        elseif isnumeric(EEG.event(e).type)
            EEG.event(e).type = num2str(EEG.event(e).type);
        end
    end

    % Band-Pass Filtering (1–30 Hz, FIR Filter with Kaiser Window)
    EEG = pop_eegfiltnew(EEG, 1, 30, [], 0, [], 0.01);

    % Re-Referencing (Average Reference)
    EEG = pop_reref(EEG, []);

    % Interpolating Previously Removed Channels
    EEG = pop_interp(EEG, EEG.chanlocs, 'spherical');

    % Count S1 and S2 Trials Before Epoching
    num_S1 = sum(strcmp({EEG.event.type}, 'S1'));
    num_S2 = sum(strcmp({EEG.event.type}, 'S2'));
    trial_counts.(subjects{i}) = struct('S1', num_S1, 'S2', num_S2);
    
    if num_S1 == 0 && num_S2 == 0
        error('No S1 or S2 events found after artifact rejection. Check preprocessing.');
    end

    % Extract Epochs (Stimulus-Locked to S1 and S2)
    EEG = pop_epoch(EEG, {'S1', 'S2'}, [-0.3 0.7]);

    % Baseline Correction (-300 ms to 0 ms)
    EEG = pop_rmbase(EEG, [-300 0]);

    % Save Final Preprocessed Dataset
    EEG = pop_saveset(EEG, 'filename', final_files{i}, 'filepath', data_path);
    fprintf('Automated preprocessing complete: Saved as %s\n', final_files{i});
end

%% =========================== 4. N2 Analysis Pipeline ===========================
fprintf('\n===== N2 ANALYSIS PIPELINE =====\n');

electrodes = {'Fz', 'FCz', 'Cz'}; 
global_min = Inf;
global_max = -Inf;
results = struct();

figure_N2_electrodes = figure('Name', 'N2 Waveforms per Electrode', 'NumberTitle', 'off');
figure_N2_avg = figure('Name', 'Averaged N2 Waveforms', 'NumberTitle', 'off');

for i = 1:length(subjects)
    EEG = pop_loadset('filename', final_files{i}, 'filepath', data_path);
    elec_idx = find(ismember({EEG.chanlocs.labels}, electrodes));

    ERP_S1 = mean(EEG.data(elec_idx, :, strcmp({EEG.epoch.eventtype}, 'S1')), 3);
    ERP_S2 = mean(EEG.data(elec_idx, :, strcmp({EEG.epoch.eventtype}, 'S2')), 3);
    time_vector = EEG.times;

    figure(figure_N2_electrodes);
    for j = 1:length(elec_idx)
        subplot(2,3, (i-1)*3 + j);
        plot(time_vector, ERP_S1(j,:), 'b', 'LineWidth', 1.5); hold on;
        plot(time_vector, ERP_S2(j,:), 'r', 'LineWidth', 1.5);
        title(strrep([subjects{i} ' - ' electrodes{j}], '_', '\_'));
        xlabel('Time (ms)'); ylabel('Amplitude (µV)');
        legend('S1 (Congruent)', 'S2 (Incongruent)');
    end

    ERP_S1_avg = mean(ERP_S1, 1);
    ERP_S2_avg = mean(ERP_S2, 1);

    figure(figure_N2_avg);
    subplot(2,1,i);
    plot(time_vector, ERP_S1_avg, 'b', 'LineWidth', 2); hold on;
    plot(time_vector, ERP_S2_avg, 'r', 'LineWidth', 2);
    title(strrep([subjects{i} ' - N2 (Averaged Fz, FCz, Cz)'], '_', '\_'));
    xlabel('Time (ms)'); ylabel('Amplitude (µV)');
    legend('S1 (Congruent)', 'S2 (Incongruent)');

    %% Compute Mean N2 Amplitude (200–350 ms)
    time_window = [200 350];
    time_idx = time_vector >= time_window(1) & time_vector <= time_window(2);

    mean_N2_S1 = mean(ERP_S1_avg(time_idx));
    mean_N2_S2 = mean(ERP_S2_avg(time_idx));

    % Store results for each subject
    results.(subjects{i}) = struct('N2_S1', mean_N2_S1, 'N2_S2', mean_N2_S2);
end

% Display tables
T_trials = table(fieldnames(trial_counts), ...
                 structfun(@(x) x.S1, trial_counts), ...
                 structfun(@(x) x.S2, trial_counts), ...
                 'VariableNames', {'Subject', 'Trials_S1 (Congruent)', 'Trials_S2 (Incongruent)'});
disp('Trial Counts Per Subject:');
disp(T_trials);

T_results = table(fieldnames(results), ...
                  structfun(@(x) x.N2_S1, results), ...
                  structfun(@(x) x.N2_S2, results), ...
                  'VariableNames', {'Subject', 'N2_S1 (Congruent)', 'N2_S2 (Incongruent)'});
disp('Mean N2 Amplitudes Per Subject:');
disp(T_results);

fprintf('\n===== PIPELINE COMPLETE =====\n');
