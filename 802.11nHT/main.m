close all;
clear;
clc;

snr_orig = 55*ones(1,10);
snr_vmsx = 25:10:65;

% Create a format configuration object for a 2-by-2 HT transmission
cfgHT = wlanHTConfig;
cfgHT.ChannelBandwidth = 'CBW20'; % 20 MHz channel bandwidth
cfgHT.NumTransmitAntennas = 2;    % 2 transmit antennas
cfgHT.NumSpaceTimeStreams = 2;    % 2 space-time streams
cfgHT.PSDULength = 1000;          % PSDU length in bytes
cfgHT.MCS = 15;                   % 2 spatial streams, 64-QAM rate-5/6
cfgHT.ChannelCoding = 'BCC';      % BCC channel coding


% Create and configure the channel
tgnChannel = wlanTGnChannel;
tgnChannel.DelayProfile = 'Model-A';
tgnChannel.NumTransmitAntennas = cfgHT.NumTransmitAntennas;
tgnChannel.NumReceiveAntennas = 2;
tgnChannel.TransmitReceiveDistance = 3; % Distance in meters for NLOS
tgnChannel.LargeScaleFadingEffect = 'None';
tgnChannel.NormalizeChannelOutputs = false;


maxNumPEs = 10; % The maximum number of packet errors at an SNR point
maxNumPackets = 100; % The maximum number of packets at an SNR point

% Get the baseband sampling rate
fs = wlanSampleRate(cfgHT);

% Get the OFDM info
ofdmInfo = wlanHTOFDMInfo('HT-Data',cfgHT);

% Set the sampling rate of the channel
tgnChannel.SampleRate = fs;

ind = wlanFieldIndices(cfgHT);

S = numel(snr_vmsx);
packetErrorRate_orig = zeros(S,1);
packetErrorRate_vmsx = zeros(S,1);

rxDemod_orig = @rxDemod;
rxDemod_vmsx = @rxDemod;

%parfor i = 1:S % Use 'parfor' to speed up the simulation
for i = 1:S % Use 'for' to debug the simulation
    % Set random substream index per iteration to ensure that each
    % iteration uses a repeatable set of random numbers
    stream = RandStream('combRecursive','Seed',0);
    stream.Substream = i;
    RandStream.setGlobalStream(stream);

    % Account for noise energy in nulls so the SNR is defined per
    % active subcarrier
    packetSNR_orig = snr_orig(i)-10*log10(ofdmInfo.FFTLength/ofdmInfo.NumTones);
    packetSNR_vmsx = snr_vmsx(i)-10*log10(ofdmInfo.FFTLength/ofdmInfo.NumTones);

    % Loop to simulate multiple packets
    numPacketErrors_orig = 0;
    numPacketErrors_vmsx = 0;
    n = 1; % Index of packet transmitted

    while numPacketErrors_vmsx<=maxNumPEs && n<=maxNumPackets

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
        n = n + 1;

        if  detectionError_orig == 1
            numPacketErrors_orig = numPacketErrors_orig+ detectionError_orig;
            continue;
        end
        
        % Determine if any bits are in error, i.e. a packet error
        packetError_orig = any(biterr(txPSDU,rxPSDU_orig));
        numPacketErrors_orig = numPacketErrors_orig+packetError_orig;

        %% VMscatter Channel
        % Pass the waveform through the TGn channel model
        reset(tgnChannel); % Reset channel for different realization
        rx_before_vmsx = tgnChannel(tx);


        % Pass the waveform through the tag
        [rx_vmsx, txTagData] = VMscatterMod(rx_before_vmsx, ind, ...
            tgnChannel.NumTransmitAntennas, tgnChannel.NumReceiveAntennas);


        reset(tgnChannel); % Reset channel for different realization
        rx_after_vmsx = tgnChannel(rx_before_vmsx);

        % Add noise
        rx_after_vmsx = awgn(rx_after_vmsx,packetSNR_vmsx);

        [rxPSDU_vmsx, rxDataSubcarrier_vmsx,  detectionError_vmsx] = rxDemod_orig(rx_after_vmsx, cfgHT);
        n = n + 1;

        if  detectionError_vmsx == 1
            numPacketErrors_vmsx = numPacketErrors_vmsx + detectionError_vmsx;
            continue;
        end
        
        % Determine if any bits are in error, i.e. a packet error
        packetError_vmsx = any(biterr(txPSDU,rxPSDU_vmsx));
        numPacketErrors_vmsx= numPacketErrors_vmsx+packetError_vmsx;


    end

    % Calculate packet error rate (PER) at SNR point
    packetErrorRate_orig(i) = numPacketErrors_orig/(n-1);
    disp(['Original Channel: SNR ' num2str(snr_orig(i))...
          ' completed after '  num2str(n-1) ' packets,'...
          ' PER: ' num2str(packetErrorRate_orig(i))]);

    packetErrorRate_vmsx(i) = numPacketErrors_vmsx/(n-1);
    disp(['VMscatter Channel: SNR ' num2str(snr_vmsx(i))...
          ' completed after '  num2str(n-1) ' packets,'...
          ' PER: ' num2str(packetErrorRate_vmsx(i))]);
end

figure;
plot(snr_vmsx,packetErrorRate_vmsx,'-ob');
grid on;
xlabel('SNR [dB]');
ylabel('PER');
title('802.11n 20MHz, MCS15, Direct Mapping, 2x2 Channel Model B-NLOS');