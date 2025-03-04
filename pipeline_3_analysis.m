%% 1. Initialize EEGLAB and Load Preprocessed Data
clc; clear; close all;
eeglab nogui; % Suppress EEGLAB GUI

% Define subjects and preprocessed dataset filenames
subjects = {'sub_100', 'sub_101'};
preprocessed_files = {'sub_100_preprocessed.set', 'sub_101_preprocessed.set'};

% Set relative path (assumes script is in the parent directory of 'datasets/')
data_path = fullfile(pwd, 'datasets');

% Define frontocentral electrodes in correct order for N2 extraction
electrodes = {'Fz', 'FCz', 'Cz'}; 

% Initialize structures to store results
results = struct();
trial_counts = struct();

%% 🔹 Create Figures for All Subjects Before the Loop
figure_N2_electrodes = figure('Name', 'N2 Waveforms per Electrode', 'NumberTitle', 'off');
figure_N2_avg = figure('Name', 'Averaged N2 Waveforms', 'NumberTitle', 'off');

%% 2. Loop Through Subjects for N2 Analysis
for i = 1:length(subjects)
    fprintf('Processing %s...\n', subjects{i});

    % Load preprocessed EEG dataset
    EEG = pop_loadset('filename', preprocessed_files{i}, 'filepath', data_path);
    
    %% 🔹 Step 1: Extract Number of Trials Per Condition
    num_S1 = sum(strcmp({EEG.event.type}, 'S1'));
    num_S2 = sum(strcmp({EEG.event.type}, 'S2'));

    % Store trial counts
    trial_counts.(subjects{i}) = struct('S1', num_S1, 'S2', num_S2);
    fprintf('%s - Trials: S1 = %d, S2 = %d\n', subjects{i}, num_S1, num_S2);

    %% 🔹 Step 2: Extract N2 Waveforms (200–350 ms)
    elec_idx = find(ismember({EEG.chanlocs.labels}, electrodes));

    % Extract average ERP per condition
    ERP_S1 = mean(EEG.data(elec_idx, :, strcmp({EEG.epoch.eventtype}, 'S1')), 3);
    ERP_S2 = mean(EEG.data(elec_idx, :, strcmp({EEG.epoch.eventtype}, 'S2')), 3);

    time_vector = EEG.times; % Define time axis

    %% 🔹 Step 3: Plot N2 Waveforms for Each Electrode (Single Figure for All Subjects)
    figure(figure_N2_electrodes);
    for j = 1:length(elec_idx)
        subplot(2,3, (i-1)*3 + j); % Places subject 1 in row 1, subject 2 in row 2
        plot(time_vector, ERP_S1(j,:), 'b', 'LineWidth', 1.5); hold on;
        plot(time_vector, ERP_S2(j,:), 'r', 'LineWidth', 1.5);
        title(strrep([subjects{i} ' - ' electrodes{j}], '_', '\_')); % Fix "_" displaying as subscript
        xlabel('Time (ms)'); ylabel('Amplitude (µV)');
        legend('S1 (Congruent)', 'S2 (Incongruent)');
    end

    %% 🔹 Step 4: Compute and Plot N2 Averaged Across Electrodes (Single Figure for All Subjects)
    ERP_S1_avg = mean(ERP_S1, 1);
    ERP_S2_avg = mean(ERP_S2, 1);

    figure(figure_N2_avg);
    subplot(2,1,i);
    plot(time_vector, ERP_S1_avg, 'b', 'LineWidth', 2); hold on;
    plot(time_vector, ERP_S2_avg, 'r', 'LineWidth', 2);
    title(strrep([subjects{i} ' - N2 (Averaged Fz, FCz, Cz)'], '_', '\_')); % Fix title formatting
    xlabel('Time (ms)'); ylabel('Amplitude (µV)');
    legend('S1 (Congruent)', 'S2 (Incongruent)');

    %% 🔹 Step 5: Compute Mean N2 Amplitude (200–350 ms)
    time_window = [200 350];
    time_idx = time_vector >= time_window(1) & time_vector <= time_window(2);

    mean_N2_S1 = mean(ERP_S1_avg(time_idx));
    mean_N2_S2 = mean(ERP_S2_avg(time_idx));

    % Store results for each subject
    results.(subjects{i}) = struct('N2_S1', mean_N2_S1, 'N2_S2', mean_N2_S2);
end

%% 6. Display Trial Counts in Table Format
T_trials = table(fieldnames(trial_counts), ...
                 structfun(@(x) x.S1, trial_counts), ...
                 structfun(@(x) x.S2, trial_counts), ...
                 'VariableNames', {'Subject', 'Trials_S1 (Congruent)', 'Trials_S2 (Incongruent)'});
disp('Trial Counts Per Subject:');
disp(T_trials);

%% 7. Display Mean N2 Amplitudes in Table Format
T_results = table(fieldnames(results), ...
                  structfun(@(x) x.N2_S1, results), ...
                  structfun(@(x) x.N2_S2, results), ...
                  'VariableNames', {'Subject', 'N2_S1 (Congruent)', 'N2_S2 (Incongruent)'});
disp('Mean N2 Amplitudes Per Subject:');
disp(T_results);
