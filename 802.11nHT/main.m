close all;
clear;
clc;

NumTransmitAntennas = 2;
NumTagAntennas = 2; 
NumReceiveAntennas = 2; 
snr_vmsx = 55:10:95;
snr_orig = 55*ones(1,length(snr_vmsx));


% Create a format configuration object for a K-by-K HT transmission
cfgHT = wlanHTConfig;
cfgHT.ChannelBandwidth = 'CBW20'; % 20 MHz channel bandwidth
cfgHT.NumTransmitAntennas = NumTransmitAntennas;    % transmit antennas
cfgHT.NumSpaceTimeStreams = cfgHT.NumTransmitAntennas;    % space-time streams
cfgHT.PSDULength = 2000;          % PSDU length in bytes

switch min(NumTransmitAntennas, NumReceiveAntennas)
  case 1
        cfgHT.MCS = 7; % 1-NSS, 64-QAM rate-5/6
  case 2
        cfgHT.MCS = 15; % 2-NSS, 64-QAM rate-5/6
  case 3
        cfgHT.MCS = 23; % 3-NSS, 64-QAM rate-5/6
  case 4
        cfgHT.MCS = 31; % 4-NSS, 64-QAM rate-5/6
  otherwise 
        cfgHT.MCS = 15;
end 



cfgHT.ChannelCoding = 'BCC';      % BCC channel coding

% Get the baseband sampling rate
fs = wlanSampleRate(cfgHT);

% Create and configure the channel
tgnChannel = wlanTGnChannel;
tgnChannel.DelayProfile = 'Model-A';
tgnChannel.NumTransmitAntennas = NumTransmitAntennas;
tgnChannel.NumReceiveAntennas = NumReceiveAntennas;
tgnChannel.TransmitReceiveDistance = 10; % Distance in meters for NLOS
tgnChannel.LargeScaleFadingEffect = 'None';
tgnChannel.NormalizeChannelOutputs = false;
tgnChannel.SampleRate = fs;

tgnChannel_before_vmsx = wlanTGnChannel;
tgnChannel_before_vmsx.DelayProfile = 'Model-A';
tgnChannel_before_vmsx.NumTransmitAntennas = NumTransmitAntennas;
tgnChannel_before_vmsx.NumReceiveAntennas = NumTagAntennas;
tgnChannel_before_vmsx.TransmitReceiveDistance = 3; 
tgnChannel_before_vmsx.LargeScaleFadingEffect = 'None';
tgnChannel_before_vmsx.NormalizeChannelOutputs = false;
tgnChannel_before_vmsx.SampleRate = fs;


tgnChannel_after_vmsx = wlanTGnChannel;
tgnChannel_after_vmsx.DelayProfile = 'Model-A';
tgnChannel_after_vmsx.NumTransmitAntennas = NumTagAntennas;
tgnChannel_after_vmsx.NumReceiveAntennas = NumReceiveAntennas;
tgnChannel_after_vmsx.TransmitReceiveDistance = 3;
tgnChannel_after_vmsx.LargeScaleFadingEffect = 'None';
tgnChannel_after_vmsx.NormalizeChannelOutputs = false;
tgnChannel_after_vmsx.SampleRate = fs;


maxNumPEs = 10; % The maximum number of packet errors at an SNR point
maxNumPackets = 100; % The maximum number of packets at an SNR point

% Get the OFDM info
ofdmInfo = wlanHTOFDMInfo('HT-Data',cfgHT);

ind = wlanFieldIndices(cfgHT);

cntSNR = numel(snr_vmsx);
packetErrorRate_orig = zeros(cntSNR,1);
packetErrorRate_vmsx = zeros(cntSNR,1);

rxDemod_orig = @rxDemod;
rxDemod_vmsx = @rxDemod;

%parfor i = 1:S % Use 'parfor' to speed up the simulation
for idxSNR = 1:cntSNR % Use 'for' to debug the simulation
    % Set random substream index per iteration to ensure that each
    % iteration uses a repeatable set of random numbers
%     stream = RandStream('combRecursive','Seed',0);
%     stream.Substream = idxSNR;
%     RandStream.setGlobalStream(stream);

    % Account for noise energy in nulls so the SNR is defined per
    % active subcarrier
    packetSNR_orig = snr_orig(idxSNR)-10*log10(ofdmInfo.FFTLength/ofdmInfo.NumTones);
    packetSNR_vmsx = snr_vmsx(idxSNR)-10*log10(ofdmInfo.FFTLength/ofdmInfo.NumTones);

    % Loop to simulate multiple packets
    numPacketErrors_orig = 0;
    numPacketErrors_vmsx = 0;
    n_orig = 1; % Index of packet transmitted
    n_vmsx = 1; % Index of packet reflected

    while numPacketErrors_orig<=maxNumPEs && n_orig<=maxNumPackets

        % Generate a packet waveform
        txPSDU = randi([0 1],cfgHT.PSDULength*8,1); % PSDULength in bytes
        [tx, txDataSubcarrier] = wlanWaveformGenerator(txPSDU,cfgHT);
        % Add trailing zeros to allow for channel filter delay
        tx = [tx; zeros(15,cfgHT.NumTransmitAntennas)]; %#ok<AGROW>


        %% Original Channel
        % Pass the waveform through the TGn channel model
        reset(tgnChannel); % Reset channel for different realization
        rx_orig = tgnChannel(tx);

        % Add noise
        rx_orig = awgn(rx_orig,packetSNR_orig);

        [rxPSDU_orig, rxDataSubcarrier_orig,  detectionError_orig] = rxDemod_orig(rx_orig, cfgHT);
        n_orig = n_orig + 1;
%         disp([rxDataSubcarrier_orig(:,13,:), txDataSubcarrier(:,13,:)]); % Test
        

        if  detectionError_orig == 1
            numPacketErrors_orig = numPacketErrors_orig+ detectionError_orig;
            continue;
        end
        
        % Determine if any bits are in error, i.e. a packet error
        packetError_orig = any(biterr(txPSDU,rxPSDU_orig));
        numPacketErrors_orig = numPacketErrors_orig+packetError_orig;

        %% VMscatter Channel
        % Pass the waveform through the TGn channel model
        reset(tgnChannel_before_vmsx); % Reset channel for different realization
        rx_before_vmsx = tgnChannel_before_vmsx(tx);


        % Pass the waveform through the tag
        [rx_vmsx, txTagData] = VMscatterMod(rx_before_vmsx, ind, ...
          NumTagAntennas, cfgHT);
%         rx_vmsx = rx_before_vmsx; % Test
        

        reset(tgnChannel_after_vmsx); % Reset channel for different realization
        rx_after_vmsx = tgnChannel_after_vmsx(rx_vmsx);

        % Add noise
        rx_after_vmsx = awgn(rx_after_vmsx,packetSNR_vmsx);


        [rxPSDU_vmsx, rxDataSubcarrier_vmsx,  detectionError_vmsx] = rxDemod_vmsx(rx_after_vmsx, cfgHT);
        n_vmsx = n_vmsx + 1;
%         disp([rxDataSubcarrier_vmsx(:,8,:), txDataSubcarrier(:,8,:)]);

        rxTagData = VMscatterDeMod(txDataSubcarrier, rxDataSubcarrier_vmsx, ...
            NumTagAntennas, cfgHT);

        disp([txTagData; rxTagData]);

    end

    % Calculate packet error rate (PER) at SNR point
    packetErrorRate_orig(idxSNR) = numPacketErrors_orig/(n_orig-1);
    disp(['Original Channel: SNR ' num2str(snr_orig(idxSNR))...
          ' completed after '  num2str(n_orig-1) ' packets,'...
          ' PER: ' num2str(packetErrorRate_orig(idxSNR))]);

%     packetErrorRate_vmsx(idxSNR) = numPacketErrors_vmsx/(n_vmsx-1);
%     disp(['VMscatter Channel: SNR ' num2str(snr_vmsx(idxSNR))...
%           ' completed after '  num2str(n_vmsx-1) ' packets,'...
%           ' PER: ' num2str(packetErrorRate_vmsx(idxSNR))]);
end

figure(1);
plot(snr_orig,packetErrorRate_orig,'-ob');
grid on;
xlabel('SNR [dB]');
ylabel('PER');
title(sprintf('%dx%d WiFi MIMIO, 802.11n 20MHz, MCS15, Direct Mapping, Channel Model A', ...
    NumTransmitAntennas, NumReceiveAntennas));

% figure(2);
% plot(snr_vmsx,packetErrorRate_vmsx,'-ob');
% grid on;
% xlabel('SNR [dB]');
% ylabel('PER');
% title(sprintf('%dx%dx%d VMScatter, 802.11n 20MHz, MCS15, Direct Mapping, Channel Model A', ...
%     NumTransmitAntennas, NumTagAntennas, NumReceiveAntennas));