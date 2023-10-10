clc;clearvars;close all; warning('off','all');
% Create your data columns
BER_LSTM_DPA_TA_128 = [0.23633196101141216; 0.19217104123021506; 0.06906269137607096; 0.011583232862547121; 0.0014798331982375317; 0.0004769655340106422; 0.0002922274713945107; 0.0002678526707631277; 0.0002564386320651305];
BER_LSTM_DPA_TA_64 = [0.23633196101141216; 0.19217104123021506; 0.0753474498164568; 0.013199800758320359; 0.0019427462335254375; 0.0006330214694359402; 0.0003672922970732505; 0.0003403414882518311; 0.0002890632676818967];
BER_LSTM_DNN_DPA_128 = [0.23633196101141216; 0.20965875491911135; 0.08871366954425072; 0.017710342103215888; 0.0026931469264167072; 0.0007870115164006512; 0.0004616391157394758; 0.0004051025825295201; 0.0003713128274551755];
BER_STA_DNN = [0.23633196101141216; 0.16863602419185106; 0.06831488890762931; 0.01659044961891214; 0.004743762432475034; 0.002938225383971015; 0.002522848973703971; 0.0022873786410707478; 0.002142738964775227 ];
% Save each column in separate files
save('BER_LSTM_DPA_TA_128.mat', 'BER_LSTM_DPA_TA_128');
save('BER_LSTM_DPA_TA_64.mat', 'BER_LSTM_DPA_TA_64');
save('BER_LSTM_DNN_DPA_128.mat', 'BER_LSTM_DNN_DPA_128');
save('BER_STA_DNN.mat', 'BER_STA_DNN');