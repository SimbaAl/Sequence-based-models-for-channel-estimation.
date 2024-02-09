clc;clearvars; close all; warning('off','all');
ch_func = Channel_functions();
%% --------OFDM Parameters - Given in IEEE 802.11p Spec--
ofdmBW                 = 10 * 10^6 ;                                % OFDM bandwidth (Hz)
nFFT                   = 64;                                        % FFT size 
nDSC                   = 48;                                        % Number of data subcarriers
nPSC                   = 4;                                         % Number of pilot subcarriers
nZSC                   = 12;                                        % Number of zeros subcarriers
nUSC                   = nDSC + nPSC;                               % Number of total used subcarriers
K                      = nUSC + nZSC;                               % Number of total subcarriers
nSym                   = 50;                                       % Number of OFDM symbols within one frame
deltaF                 = ofdmBW/nFFT;                               % Bandwidth for each subcarrier - include all used and unused subcarriers 
Tfft                   = 1/deltaF;                                  % IFFT or FFT period = 6.4us
Tgi                    = Tfft/4;                                    % Guard interval duration - duration of cyclic prefix - 1/4th portion of OFDM symbols = 1.6us
Tsignal                = Tgi+Tfft;                                  % Total duration of BPSK-OFDM symbol = Guard time + FFT period = 8us
K_cp                   = nFFT*Tgi/Tfft;                             % Number of symbols allocated to cyclic prefix 
pilots_locations       = [8,22,44,58].';                            % Pilot subcarriers positions
pilots                 = [1 1 1 -1].';
data_locations         = [2:7, 9:21, 23:27, 39:43, 45:57, 59:64].'; % Data subcarriers positions
null_locations         = [1, 28:38].';
ppositions             = [7,21, 32,46].';                           % Pilots positions in Kset
dpositions             = [1:6, 8:20, 22:31, 33:45, 47:52].';        % Data positions in Kset
% Pre-defined preamble in frequency domain
dp = [ 0  0 0 0 0 0 +1 +1 -1 -1 +1  +1 -1  +1 -1 +1 +1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1 +1 +1 +1 0 +1 -1 -1 +1 +1 -1 +1 -1 +1 -1 -1 -1 -1 -1 +1 +1 -1 -1 +1 -1 +1 -1 +1 +1 +1 +1 0 0 0 0 0];
Ep                     = 1;                                         % pramble power per sample
dp                     = fftshift(dp);                              % Shift zero-frequency component to center of spectrum    
predefined_preamble    = dp;
Kset                   = find(dp~=0);                               % set of allocated subcarriers                  
Kon                    = length(Kset);                              % Number of active subcarriers
dp                     = sqrt(Ep)*dp.';
xp                     = sqrt(K)*ifft(dp);
xp_cp                  = [xp(end-K_cp+1:end); xp];                  % Adding CP to the time domain preamble
preamble_80211p        = repmat(xp_cp,1,2);                         % IEEE 802.11p preamble symbols (tow symbols)
%% ------ Bits Modulation Technique------------------------------------------
modu                      = '16QAM';
Mod_Type                  = 1;              % 0 for BPSK and 1 for QAM 
if(Mod_Type == 0)
    nBitPerSym            = 1;
    Pow                   = 1;
    %BPSK Modulation Objects
    bpskModulator         = comm.BPSKModulator;
    bpskDemodulator       = comm.BPSKDemodulator;
    M                     = 1;
elseif(Mod_Type == 1)
    if(strcmp(modu,'QPSK') == 1)
         nBitPerSym       = 2; 
    elseif (strcmp(modu,'16QAM') == 1)
         nBitPerSym       = 4; 
    elseif (strcmp(modu,'64QAM') == 1)
         nBitPerSym       = 6; 
    end
    M                     = 2 ^ nBitPerSym; % QAM Modulation Order   
    Pow                   = mean(abs(qammod(0:(M-1),M)).^2); % Normalization factor for QAM    
    Constellation         =  1/sqrt(Pow) * qammod(0:(M-1),M); % 
end

%% ---------Scrambler Parameters---------------------------------------------
scramInit                 = 93; % As specidied in IEEE 802.11p Standard [1011101] in binary representation
%% ---------Convolutional Coder Parameters-----------------------------------
constlen                  = 7;
trellis                   = poly2trellis(constlen,[171 133]);
tbl                       = 34;
rate                      = 1/2;
%% -------Interleaver Parameters---------------------------------------------
% Matrix Interleaver
Interleaver_Rows          = 16;
Interleaver_Columns       = (nBitPerSym * nDSC * nSym) / Interleaver_Rows;
% General Block Interleaver
Random_permutation_Vector = randperm(nBitPerSym*nDSC*nSym); % Permutation vector
%% -----------------Vehicular Channel Model Parameters--------------------------
mobility                  = 'Very_High';
ChType                    = 'VTV_SDWW';             % Channel model
fs                        = K*deltaF;               % Sampling frequency in Hz, here case of 802.11p with 64 subcarriers and 156250 Hz subcarrier spacing
fc                        = 5.9e9;                  % Carrier Frequecy in Hz.
vel                       = 200;                    % Moving speed of user in km
c                         = 3e8;                    % Speed of Light in m/s
fD                        = 1100;%(vel/3.6)/c*fc;         % Doppler freq in Hz
rchan                     = ch_func.GenFadingChannel(ChType, fD, fs);
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

%% ---------Bit to Noise Ratio------------------%
SNR_p                     = EbN0dB + 10*log10(K/nDSC) + 10*log10(K/(K + K_cp)) + 10*log10(nBitPerSym) + 10*log10(rate);
SNR_p                     = SNR_p.';
N0                        = Ep*10.^(-SNR_p/10);
N_CH                      = size(indices,1); 
N_SNR                     = length(SNR_p); 

% Normalized mean square error (NMSE) vectors
Err_DPA_TA                   = zeros(N_SNR,1);
% Bit error rate (BER) vectors
Ber_Ideal                    = zeros(N_SNR,1);
Ber_DPA_TA                   = zeros(N_SNR,1);
% average channel power E(|hf|^2)
Phf_H_Total                  = zeros(N_SNR,1);

%% Simulation Loop
for n_snr = 1:N_SNR
    disp(['Running Simulation, SNR = ', num2str(EbN0dB(n_snr))]);
    tic;      
     TX_Bits_Stream_Structure               = zeros(nDSC * nSym  * nBitPerSym *rate, N_CH);
     Received_Symbols_FFT_Structure         = zeros(Kon,nSym, N_CH);
     True_Channels_Structure                = zeros(Kon, nSym + 1, N_CH);
     HLS_Structure                          = zeros(Kon, N_CH);
     DPA_TA_Structure                       = zeros(Kon, nSym, N_CH);

    for n_ch = 1:N_CH % loop over channel realizations
        % Bits Stream Generation 
        Bits_Stream_Coded = randi(2, nDSC * nSym  * nBitPerSym * rate,1)-1;
        % Data Scrambler 
        scrambledData = wlanScramble(Bits_Stream_Coded,scramInit);
        % Convolutional Encoder
        dataEnc = convenc(scrambledData,trellis);
        % Interleaving
        % Matrix Interleaving
        codedata = dataEnc.';
        Matrix_Interleaved_Data = matintrlv(codedata,Interleaver_Rows,Interleaver_Columns).'; 
        % General Block Interleaving
        General_Block_Interleaved_Data = intrlv(Matrix_Interleaved_Data,Random_permutation_Vector);
        % Bits Mapping: M-QAM Modulation
        TxBits_Coded = reshape(General_Block_Interleaved_Data,nDSC , nSym  , nBitPerSym);
        % Gray coding goes here
        TxData_Coded = zeros(nDSC ,nSym);
        for m = 1 : nBitPerSym
           TxData_Coded = TxData_Coded + TxBits_Coded(:,:,m)*2^(m-1);
        end
        % M-QAM Modulation
         Modulated_Bits_Coded  =1/sqrt(Pow) * qammod(TxData_Coded,M);
         % Check the power of Modulated bits. it must be equal to 1
         avgPower = mean (abs (Modulated_Bits_Coded).^ 2,2);
         % OFDM Frame Generation
         OFDM_Frame_Coded = zeros(K,nSym);
         OFDM_Frame_Coded(data_locations,:) = Modulated_Bits_Coded;
         OFDM_Frame_Coded(pilots_locations,:) = repmat(pilots,1,nSym);
         % Taking FFT, the term (nFFT/sqrt(nDSC)) is for normalizing the power of transmit symbol to 1 
         IFFT_Data_Coded = sqrt(K)*ifft(OFDM_Frame_Coded);
         % checking the power of the transmit signal (it has to be 1 after normalization)
         power_Coded = var(IFFT_Data_Coded(:)) + abs(mean(IFFT_Data_Coded(:)))^2; 
         % Appending cylic prefix
         CP_Coded = IFFT_Data_Coded((K - K_cp +1):K,:);
         IFFT_Data_CP_Coded = [CP_Coded; IFFT_Data_Coded];
         % Appending preamble symbol 
         %IFFT_Data_CP_Preamble_Coded = [xp_cp IFFT_Data_CP_Coded];
         IFFT_Data_CP_Preamble_Coded = [ preamble_80211p IFFT_Data_CP_Coded];
         power_transmitted =  var(IFFT_Data_CP_Preamble_Coded(:)) + abs(mean(IFFT_Data_CP_Preamble_Coded(:)))^2; 

        % ideal estimation
        release(rchan);
        rchan.Seed = indices(n_ch,1);
        [ h, y ] = ch_func.ApplyChannel( rchan, IFFT_Data_CP_Preamble_Coded, K_cp);
        %release(rchan);
        %rchan.Seed = rchan.Seed+1;
        yp = y((K_cp+1):end,1:2);
        y  = y((K_cp+1):end,3:end);
        
        yFD = sqrt(1/K)*fft(y);
        yfp = sqrt(1/K)*fft(yp); % FD preamble
        
        
        h = h((K_cp+1):end,:);
        hf = fft(h); % Fd channel
        hfp1 = hf(:,1);
        hfp2 = hf(:,2);
        hfp = (hfp1 + hfp2) ./2;
        hf  = hf(:,3:end);        
      
        Phf_H_Total(n_snr,1) = Phf_H_Total(n_snr,1) + mean(sum(abs(hf(Kset,:)).^2));
       
        %add noise
        noise_preamble = sqrt(N0(n_snr))*ch_func.GenRandomNoise([K,2], 1);
        yfp_r = yfp +  noise_preamble;
        noise_OFDM_Symbols = sqrt(N0(n_snr))*ch_func.GenRandomNoise([K,size(yFD,2)], 1);
        y_r   = yFD + noise_OFDM_Symbols;
       %% Channel Estimation
       % IEEE 802.11p LS Estimate at Preambles
        he_LS_Preamble = ((yfp_r(Kset,1) + yfp_r(Kset,2))./(2.*predefined_preamble(Kset).'));   
 
      
       [H_DPA_TA, Equalized_OFDM_Symbols_DPA_TA] = DPA_TA(he_LS_Preamble ,y_r, Kset,modu, nUSC, nSym, ppositions);
       Err_DPA_TA(n_snr) = Err_DPA_TA(n_snr) + mean(sum(abs(H_DPA_TA - hf(Kset,:)).^2)); 
       
        
        %%    IEEE 802.11p Rx     
        Bits_Ideal                                          = de2bi(qamdemod(sqrt(Pow) * (y_r(data_locations ,:) ./ hf(data_locations,:)),M));
        Bits_DPA_TA                                        = de2bi(qamdemod(sqrt(Pow) * Equalized_OFDM_Symbols_DPA_TA(dpositions,:),M)); 
       
        
        Ber_Ideal (n_snr)                                   = Ber_Ideal (n_snr) + biterr(wlanScramble((vitdec((matintrlv((deintrlv(Bits_Ideal(:),Random_permutation_Vector)).',Interleaver_Columns,Interleaver_Rows).'),trellis,tbl,'trunc','hard')),scramInit),Bits_Stream_Coded);
        Ber_DPA_TA(n_snr)                                    = Ber_DPA_TA(n_snr) + biterr(wlanScramble((vitdec((matintrlv((deintrlv(Bits_DPA_TA(:),Random_permutation_Vector)).',Interleaver_Columns,Interleaver_Rows).'),trellis,tbl,'trunc','hard')),scramInit),Bits_Stream_Coded);
        
       
    
        
          hfC = [hfp, hf];
          TX_Bits_Stream_Structure(:, n_ch)                  = Bits_Stream_Coded;
          Received_Symbols_FFT_Structure(:,:,n_ch)           = y_r(Kset,:);
          True_Channels_Structure(:,:,n_ch)                  = hfC(Kset,:);
          HLS_Structure(:,n_ch)                              = he_LS_Preamble;
          DPA_TA_Structure(:,:,n_ch)                         = H_DPA_TA;

        
         
    end 
   
    if (isequal(configuration,'training'))

        save(['./',mobility,'_',ChType,'_',modu,'_training_simulation_' num2str(EbN0dB(n_snr))],...
           'True_Channels_Structure',...
           'HLS_Structure',...
           'DPA_TA_Structure');
    
    
    elseif(isequal(configuration,'testing'))
          
          save(['./',mobility,'_',ChType,'_',modu,'_testing_simulation_' num2str(EbN0dB(n_snr))],...
           'TX_Bits_Stream_Structure',...
           'Received_Symbols_FFT_Structure',...
           'True_Channels_Structure',...
           'DPA_TA_Structure',...
           'HLS_Structure');
        
    end
    toc;
end 

%% Load data from the first script
%load('trans.mat','BER_scheme_Transformer')
%load('trans1.mat','BER_scheme_Transformer1')
%load('lstm.mat','BER_scheme_LSTM')
%load('results_scriptTrans_RTV_EX1.mat', 'ERR_scheme_Transformer'); 
%load('results_scriptRTV_EX1.mat','ERR_scheme_LSTM');
%load('ber_data.mat','BER_GRU','BER_LSTM_MP', 'BER_AE')
%%
BER_Ideal                    = Ber_Ideal /(N_CH * nSym * nDSC * nBitPerSym);
BER_DPA_TA                   = Ber_DPA_TA / (N_CH * nSym * nDSC * nBitPerSym);
save('BER_DPA_TA', "BER_DPA_TA")
save("BER_Ideal", "BER_Ideal")
%figure,
%p1 = semilogy(EbN0dB, BER_Ideal,'k-o','LineWidth',2);
%hold on;
%p2 = semilogy(EbN0dB, BER_DPA_TA,'k--o','LineWidth',2);
%hold on;
%p1 = semilogy(EbN0dB, BER_scheme_Transformer,'r-s','LineWidth',2);
%hold on;
%p2 = semilogy(EbN0dB, BER_scheme_LSTM,'c-*','LineWidth',2);
%hold on;
%p3 = semilogy(EbN0dB, BER_GRU,'g-d','LineWidth',2);
%hold on;
%p4 = semilogy(EbN0dB, BER_LSTM_MP,'m-v','LineWidth',2);
%hold on;
%p5 = semilogy(EbN0dB, BER_AE,'b-p','LineWidth',2);
%hold on;
%p6 = semilogy(EbN0dB, BER_scheme_Transformer1,'rd','LineWidth',2);
%hold on;
%grid on;
%legend([p1(1),p2(1),p3(1),p4(1),p5(1),p6(1)],{'Transformer-DPA-TA','LSTM-DPA-TA(128)','DPA-GRU(10)','LSTM-MLP(128-40)','AE(20-10-20)','Transformer-DPA-TA (233)'});
%xlabel('SNR(dB)');
%ylabel('Bit Error Rate (BER)');
%legend('Location', 'southwest');
%xlim([min(EbN0dB), 30]);  % Set x-axis limits
% NMSE Plot 
Phf_H                         = Phf_H_Total/(N_CH);
ERR_DPA_TA                    = Err_DPA_TA ./ (Phf_H * N_CH);
save('EER_DPA_TA', "ERR_DPA_TA")
%figure,
%p1 = semilogy(EbN0dB, ERR_DPA_TA,'k--o','LineWidth',2);
%hold on;
%p2 = semilogy(EbN0dB, ERR_scheme_Transformer,'r-s','LineWidth',2);
%hold on;
%p3 = semilogy(EbN0dB, ERR_scheme_LSTM,'g-d','LineWidth',2);
%hold on;
%grid on;

%legend([p1(1),p2(1),p3(1)],{'DPA-TA','Transformer-DPA-TA', 'LSTM-DPA-TA'});
%xlabel('SNR(dB)');
%ylabel('Normalized Mean Sqaure Error (NMSE)');
%legend('Location', 'best');

if (isequal(configuration,'training'))
       
elseif(isequal(configuration,'testing'))
      save(['./',mobility,'_',ChType,'_',modu,'_simulation_parameters'],...
      'BER_Ideal','BER_DPA_TA',...
      'ERR_DPA_TA',...
      'modu','Kset','Random_permutation_Vector','fD');
end



