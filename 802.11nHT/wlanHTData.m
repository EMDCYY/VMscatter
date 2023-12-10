function [y, dataSubcarrier] = wlanHTData(PSDU,cfgHT,varargin)
%wlanHTData HT Data field processing of the PSDU input
%
%   Y = wlanHTData(PSDU,CFGHT) generates the HT-Mixed format Data field
%   time-domain waveform for the input Physical Layer Convergence Procedure
%   (PLCP) Service Data Unit (PSDU).
%
%   Y is the time-domain HT-Data field signal. It is a complex matrix of
%   size Ns-by-Nt, where Ns represents the number of time-domain samples
%   and Nt represents the number of transmit antennas.
%
%   PSDU is the PLCP service data unit input to the PHY. It is a double or
%   int8 typed column vector of length CFGHT.PSDULength*8, with each
%   element representing a bit.
%
%   CFGHT is the format configuration object of type <a href="matlab:help('wlanHTConfig')">wlanHTConfig</a> which
%   specifies the parameters for the HT-Mixed format.
%
%   Y = wlanHTData(...,SCRAMINIT) optionally allows specification of the
%   scrambler initialization for the Data field. When not specified, it
%   defaults to a value of 93. When specified, it can be a double or
%   int8-typed positive scalar less than or equal to 127 or a corresponding
%   double or int8-typed binary 7-by-1 column vector.
%
%   Y = wlanHTData(...,'OversamplingFactor',OSF) generates the HT-Data
%   oversampled by a factor OSF. OSF must be >=1. The resultant cyclic
%   prefix length in samples must be integer-valued for all symbols. The
%   default is 1.
%
%   Example: Generate a signal for a MIMO 40MHz HT-Mixed data field.
%
%     cfgHT = wlanHTConfig('ChannelBandwidth', 'CBW40', ...
%                          'NumTransmitAntennas', 2, ...
%                          'NumSpaceTimeStreams', 2, ...
%                          'MCS', 12);
%     inpPSDU = randi([0 1], cfgHT.PSDULength*8, 1);    % PSDU in bits
%     y = wlanHTData(inpPSDU, cfgHT);
%
%   See also wlanHTConfig, wlanWaveformGenerator, wlanHTDataRecover,
%   wirelessWaveformGenerator.

%   Copyright 2015-2021 The MathWorks, Inc.

%#codegen

narginchk(2,5);

% Default options
osf = 1;
scramInitBits = uint8([1; 0; 1; 1; 1; 0; 1]); % Default is 93
% Parse options
if nargin>2
    if ~(ischar(varargin{1}) || isstring(varargin{1}))
        scramInit = varargin{1};
        % Validate scrambler init
        validateattributes(scramInit, {'double', 'int8'}, ...
                           {'real', 'integer', 'nonempty'}, mfilename, 'Scrambler initialization');
        if isscalar(scramInit)
            % Check for correct range
            coder.internal.errorIf(any((scramInit<1) | (scramInit>127)), ...
                                   'wlan:wlanHTData:InvalidScramInit');

            scramInitBits = uint8(int2bit(scramInit, 7));
        else
            % Check for non-zero binary vector
            coder.internal.errorIf( ...
                any((scramInit~=0) & (scramInit~=1)) || (numel(scramInit)~=7) ...
                || all(scramInit==0) || (size(scramInit,1)~=7), ...
                'wlan:wlanHTData:InvalidScramInit');

            scramInitBits = uint8(scramInit);
        end
        osf = wlan.internal.parseOSF(varargin{2:end});
    else
        osf = wlan.internal.parseOSF(varargin{:});
    end
end

% Validate inputs
validateattributes(cfgHT, {'wlanHTConfig'}, {'scalar'}, mfilename, ...
                   'HT-Mixed format configuration object');
% Check dependent properties
s = validateConfig(cfgHT);

% Validate PSDU input
validateattributes(PSDU, {'double', 'int8'}, ...
                   {'real', 'integer', 'binary', 'column', 'size', [cfgHT.PSDULength*8 1]}, ...
                   mfilename, 'PSDU input');

numTx   = cfgHT.NumTransmitAntennas;
if cfgHT.PSDULength == 0
    y = complex(zeros(0, numTx));
    return;
end

% Get number of symbols and pad length
numSym = s.NumDataSymbols;
numPad = s.NumPadBits;

mcsTable  = wlan.internal.getRateTable(cfgHT);
numES     = mcsTable.NES;
rate      = mcsTable.Rate;
numDBPS   = mcsTable.NDBPS;
numBPSCS  = mcsTable.NBPSCS;
numCBPS   = mcsTable.NCBPS;
numSS     = mcsTable.Nss;
numSTS    = cfgHT.NumSpaceTimeStreams;
Ntail     = 6;
numCBPSSI = numCBPS/numSS;
STBC      = numSTS - numSS;
mSTBC     = 1 + (STBC~=0);

% Get OFDM parameters
ofdm = wlan.internal.vhtOFDMInfo('HT-Data', cfgHT.ChannelBandwidth, 1, cfgHT.GuardInterval);
chanBWInMHz = ofdm.NumSubchannels * 20;

% Generate the data field
% SERVICE bits, all zeros, IEEE Std 802.11-2012, Section 20.3.11.2
serviceBits = zeros(16,1,'int8');

% Scramble padded data
if strcmp(cfgHT.ChannelCoding,'BCC')
    %   [service; psdu; tail; pad] BCC processing
    paddedData = [serviceBits; PSDU; zeros(Ntail*numES,1); zeros(numPad, 1)];
else
    %   [service; psdu] LDPC processing
    paddedData = [serviceBits; PSDU];
end

scrambData = wlanScramble(paddedData, scramInitBits);

if strcmp(cfgHT.ChannelCoding,'BCC')
    % Zero-out the tail bits again for encoding
    scrambData(16+length(PSDU) + (1:Ntail*numES)) = zeros(Ntail*numES,1);

    % BCC Encoding
    %   Reshape scrambled data as per IEEE Std 802.11-2012, Eq 20-33,
    %   for multiple encoders
    encodedStreams = reshape(scrambData, numES, []).';
    encodedData = wlanBCCEncode(encodedStreams, rate);
else
    % LDPC Encoding
    %   Encode scrambled data as per IEEE Std 802.11-2012, Section
    %   20.3.11.17.3.
    numPLD = cfgHT.PSDULength*8 + 16; % Number of payload bits
    cfg = wlan.internal.getLDPCparameters(numDBPS, rate, mSTBC, numPLD);
    encodedData = wlan.internal.wlanLDPCEncode(scrambData, cfg);
end
% Parse encoded data into streams
streamParsedData = wlanStreamParse(encodedData, numSS, numCBPS, numBPSCS);

% BCC Interleaving
if strcmp(cfgHT.ChannelCoding,'BCC')
    interleavedData = wlanBCCInterleave(streamParsedData, 'VHT', numCBPSSI, cfgHT.ChannelBandwidth);
else
    % Interleaving is not required for LDPC
    interleavedData = streamParsedData;
end

% Constellation Mapper
mappedData = wlanConstellationMap(interleavedData, numBPSCS);

% Reshape to form OFDM symbols
mappedData = reshape(mappedData, numCBPSSI/numBPSCS, numSym, numSS);

if numSTS > numSS
    stbcData = wlan.internal.wlanSTBCEncode(mappedData(:,:,:), numSTS);  % Indexing for codegen
else
    stbcData = mappedData(:,:,:);  % Indexing for codegen
end

% Generate pilots for HT, IEEE Std 802.11-2012, Eqn 22-58/59
z = 3; % offset by 3 to allow for L-SIG, HT-SIG pilot symbols, Eqn 20-58
pilots = wlan.internal.htPilots(numSym,z,cfgHT.ChannelBandwidth,numSTS);

% Data packing with pilot insertion
packedData = complex(zeros(ofdm.FFTLength, numSym, numSTS));
packedData(ofdm.ActiveFFTIndices(ofdm.DataIndices),:,:) = stbcData;
packedData(ofdm.ActiveFFTIndices(ofdm.PilotIndices),:,:) = pilots;

% Tone rotation
gamma = wlan.internal.vhtCarrierRotations(ofdm.NumSubchannels);
rotatedData =  packedData .* gamma;

% Cyclic shift applied per STS
csh = wlan.internal.getCyclicShiftVal('VHT', numSTS, chanBWInMHz);
dataCycShift = wlan.internal.cyclicShift(rotatedData, csh, ofdm.FFTLength);

% Spatial mapping
dataSpMapped = wlan.internal.spatialMap(dataCycShift, cfgHT.SpatialMapping, numTx, cfgHT.SpatialMappingMatrix);

% OFDM modulate
% wout = wlan.internal.wlanOFDMModulate(dataSpMapped, ofdm.CPLength, osf);
wout = wlanOFDMModulate(dataSpMapped, ofdm.CPLength, osf);



% Scale and output
y = wout  * ofdm.FFTLength/sqrt(numSTS*ofdm.NumTones);

dataSubcarrier = rotatedData;

end
