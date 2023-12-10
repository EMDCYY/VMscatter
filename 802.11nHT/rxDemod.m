function [rxPSDU, rxDataSubcarrier, detectionError] = rxDemod(rx, cfgHT) 

        detectionError = 0;

        % Packet detect and determine coarse packet offset
        coarsePktOffset = wlanPacketDetect(rx,cfgHT.ChannelBandwidth);
        if isempty(coarsePktOffset) % If empty no L-STF detected; packet error
            detectionError= 1;
            return;
        end

        % Get the baseband sampling rate
        fs = wlanSampleRate(cfgHT);

        % Indices for accessing each field within the time-domain packet
        ind = wlanFieldIndices(cfgHT);

        % Extract L-STF and perform coarse frequency offset correction
        lstf = rx(coarsePktOffset+(ind.LSTF(1):ind.LSTF(2)),:);
        coarseFreqOff = wlanCoarseCFOEstimate(lstf,cfgHT.ChannelBandwidth);
        rx = frequencyOffset(rx,fs,-coarseFreqOff);

        % Extract the non-HT fields and determine fine packet offset
        nonhtfields = rx(coarsePktOffset+(ind.LSTF(1):ind.LSIG(2)),:);
        finePktOffset = wlanSymbolTimingEstimate(nonhtfields,...
            cfgHT.ChannelBandwidth);

        % Determine final packet offset
        pktOffset = coarsePktOffset+finePktOffset;

        % If packet detected outwith the range of expected delays from the
        % channel modeling; packet error
        if pktOffset>15
            detectionError = 1;
            return;
        end

        % Extract L-LTF and perform fine frequency offset correction
        lltf = rx(pktOffset+(ind.LLTF(1):ind.LLTF(2)),:);
        fineFreqOff = wlanFineCFOEstimate(lltf,cfgHT.ChannelBandwidth);
        rx = frequencyOffset(rx,fs,-fineFreqOff);

        % Extract HT-LTF samples from the waveform, demodulate and perform
        % channel estimation
        htltf = rx(pktOffset+(ind.HTLTF(1):ind.HTLTF(2)),:);
        htltfDemod = wlanHTLTFDemodulate(htltf,cfgHT);
        chanEst = wlanHTLTFChannelEstimate(htltfDemod,cfgHT);

        % Extract HT Data samples from the waveform
        htdata = rx(pktOffset+(ind.HTData(1):ind.HTData(2)),:);

        % Estimate the noise power in HT data field
        nVarHT = htNoiseEstimate(htdata,chanEst,cfgHT);

        % Recover the transmitted PSDU in HT Data
        [rxPSDU, rxDataSubcarrier]  = wlanHTDataRecover(htdata,chanEst,nVarHT,cfgHT, ...
            "LDPCDecodingMethod","norm-min-sum", 'PilotPhaseTracking', 'None');

end