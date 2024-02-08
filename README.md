### Files Description 
- Main.m: The main simulation file, where the simulation parameters (Channel model, OFDM parameters, Modulation scheme, etc...) are defined. 
- Channel_functions.m: Includes the pre-defined vehicular channel models [3] for different mobility conditions.
- DPA_TA.m: Includes the implementation of the data-pilot-aided (DPA) channel estimation followed by temporal averaging (TA).
- LSTM_Datasets_Generation.m: Generating the LSTM training/testing datasets.
- LSTM_Results_Processing.m: Processing the testing results generated by the LSTM testing and calculating the BER and NMSE results of the LSTM-DPA-TA estimator.
- LSTM.py: The LSTM training/testing is performed employing the generated training/testing datasets. The file should be executed twice as follows:
	- **Step1: Training by executing this command python LSTM.py  Mobility Channel_Model Modulation_Order Channel_Estimator Training_SNR LSTM_Input LSTM_Cell_Size Epochs Batch_size**
	- **Step2: Testing by executing this command: python LSTM.py  Mobility Channel_Model Modulation_Scheme Channel_Estimator Testing_SNR** 
> ex: python LSTM.py  High VTV_SDWW QPSK DPA_TA 40 104 128 500 128

> ex: python LSTM.py High VTV_SDWW QPSK DPA_TA 40
		
### Running Steps:
1. Run the IDX_Generation.m to generate the dataset indices, training dataset size, and testing dataset size.
2. Run the main.m file two times as follows:
	- Specify all the simulation parameters like the number of OFDM symbols, channel model, mobility scenario, modulation order, SNR range, etc.
	- Specify the path of the generated indices in step (1).
	- The first time for generating the training simulation file (set the configuration = 'training' in the code).
	- The second time for generating the testing simulations files (set the configuration = 'testing' in the code).
	- After that, the generated simulation files will be saved in your working directory.
3. Run the LSTM_Datasets_Generation.m also two times by changing the configuration as done in step (2) in addition to specifying the channel estimation scheme as well as the OFDM simulation parameters. This step generates the LSTM training/testing datasets.
4. Run the LSTM.py file also two times to perform the training first then the testing as mentioned in the LSTM.py file description.
5. After finishing step 4, the LSTM results will be saved as a .mat file. Then you need to run the LSTM_Results_Processing.m file to get the NMSE and BER results of the studied channel estimation scheme.

### References
- [1] A. K. Gizzini, M. Chafii, S. Ehsanfar and R. M. Shubair, "Temporal Averaging LSTM-based Channel Estimation Scheme for IEEE 802.11p Standard," 2021 IEEE Global Communications Conference (GLOBECOM), 2021, pp. 01-07, doi: 10.1109/GLOBECOM46510.2021.9685409.

