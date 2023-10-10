clc;
clearvars;
close all;

% Updated values
TOTAL_SAMPLES = 18000; % total number of samples (16000 training + 2000 testing)
TR_RATIO = 16000 / TOTAL_SAMPLES; % training dataset percentage
TE_RATIO = 2000 / TOTAL_SAMPLES;  % testing dataset percentage

All_IDX = 1:TOTAL_SAMPLES;
training_samples = randperm(TOTAL_SAMPLES, round(TR_RATIO * TOTAL_SAMPLES)).'; % choose randomly 80% of the total indices for training
testing_samples = setdiff(All_IDX, training_samples).';
save(['./samples_indices_', num2str(TOTAL_SAMPLES), '.mat'], 'training_samples', 'testing_samples');
