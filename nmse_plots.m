%% Simulation Parameters 
load('./samples_indices_18000.mat');
configuration = 'testing'; % training or testing
if (isequal(configuration,'training'))
    indices = training_samples;
    EbN0dB           = 40; 
elseif(isequal(configuration,'testing'))
    indices = testing_samples;
    EbN0dB           = 0:5:40;         
end
%% Load data from the first script
%load('BER_LSTM_DPA_TA_128.mat', 'BER_LSTM_DPA_TA_128');
%load('BER_LSTM_DPA_TA_64.mat','BER_LSTM_DPA_TA_64');
%load('BER_LSTM_DNN_DPA_128.mat','BER_LSTM_DNN_DPA_128');
%load('BER_STA_DNN.mat','BER_STA_DNN');
%load("64_bQlstm.mat", "BER_opt_64blstm")

% Save each column in separate files
load('EER_LSTM_DPA_TA_128.mat', 'EER_LSTM_DPA_TA_128');
load('EER_LSTM_DPA_TA_64.mat', 'EER_LSTM_DPA_TA_64');
load('EER_LSTM_DNN_DPA_128.mat', 'EER_LSTM_DNN_DPA_128');
load('EER_STA_DNN.mat', 'EER_STA_DNN');
load("64_bQlstm.mat", "EER_opt_64blstm");
load('EER_DPA_TA.mat','ERR_DPA_TA');
%%
%BER_Ideal                    = Ber_Ideal /(N_CH * nSym * nDSC * nBitPerSym);
%BER_DPA_TA                   = Ber_DPA_TA / (N_CH * nSym * nDSC * nBitPerSym);

figure,
%p1 = semilogy(EbN0dB, BER_Ideal,'k-o','LineWidth',2);
%hold on;
p1 = semilogy(EbN0dB, ERR_DPA_TA,'k--o','LineWidth',2);
hold on;
p2 = plot(EbN0dB, EER_LSTM_DPA_TA_128,'r-s','LineWidth',2);
hold on;
p3 = plot(EbN0dB, EER_LSTM_DPA_TA_64,'c-*','LineWidth',2);
hold on;
p4 = plot(EbN0dB, EER_LSTM_DNN_DPA_128,'g-d','LineWidth',2);
hold on;
p5 = plot(EbN0dB, EER_STA_DNN,'m-v','LineWidth',2);
hold on;
p6 = plot(EbN0dB, ERR_opt_64blstm,'b-p','LineWidth',2);
hold on;
%p7 = semilogy(EbN0dB, BER_scheme_Transformer1,'rd','LineWidth',2);
%hold on;
grid on;
legend([p1(1),p2(1),p3(1),p4(1),p5(1),p6(1)],{'DPA-TA', 'LSTM-DPA-TA-128','LSTM-DPA-TA-64','LSTM-DNN-DP-128', 'STA-DNN', 'dual-cell-LSTM (Proposed)'});
xlabel('SNR(dB)');
ylabel('NMSE');
legend('Location', 'top');
xlim([min(EbN0dB), 40]);  % Set x-axis limits
set(gca, 'YScale', 'log'); % Set y-axis to logarithmic scale
%ylim([1e-6, 10^0]);         % Set y-axis limits from 10^-6 to 10^1
