function [txWaveform, txDataSubcarrier] = wlanWaveformGenerator(dataBits,cfgFormat,varargin)
% wlanWaveformGenerator WLAN waveform generation
%   WAVEFORM = wlanWaveformGenerator(DATA,CFGFORMAT) generates a waveform
%   for a given format configuration and information bits. The generated
%   waveform contains a single packet with no idle time. For OFDM based
%   formats, the data scrambler initial state is 93 and the packet is
%   windowed for spectral controls with a windowing transition time of 1e-7
%   seconds.
%
%   WAVEFORM is a complex Ns-by-Nt matrix containing the generated
%   waveform, where Ns is the number of time domain samples, and Nt is the
%   number of transmit antennas.
%
%   DATA is the information bits including any MAC padding to be coded
%   across the number of packets to generate, i.e., representing multiple
%   concatenated PSDUs. It can be a double or int8 typed binary vector.
%   Alternatively, it can be a scalar cell array or a vector cell array
%   with length equal to number of users. Each element of the cell array
%   must be a double or int8 typed, binary vector. When DATA is a vector or
%   scalar cell array, it applies to all users. When DATA is a vector cell
%   array, each element applies to a single user. For each user, the bit
%   vector applied is looped if the number of bits required across all
%   packets of the generation exceeds the length of the vector provided.
%   This allows a short pattern to be entered, e.g. [1;0;0;1]. This pattern
%   will be repeated as the input to the PSDU coding across packets and
%   users. The ith element of the CFGFORMAT.PSDULength property contains
%   the number of bytes in a data stream for the ith user when generating a
%   DMG, S1G, HT, or non-HT packet. The ith element of the PSDU length
%   returned by the getPSDULength(CFGFORMAT) method contains the number of
%   bytes in a data stream for the ith user when generating an HE packet.
%   The ith element of the PSDU length returned by the
%   psduLength(CFGFORMAT) method contains the number of bytes in a data
%   stream for the ith user when generating an EHT packet.
%
%   CFGFORMAT is a format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>, <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a>, <a href="matlab:help('wlanS1GConfig')">wlanS1GConfig</a>, <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a>,
%   <a href="matlab:help('wlanHTConfig')">wlanHTConfig</a>, <a href="matlab:help('wlanNonHTConfig')">wlanNonHTConfig</a>, <a href="matlab:help('wlanWURConfig')">wlanWURConfig</a>, or <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a>. The format
%   of the generated waveform is determined by the type of CFGFORMAT. The
%   properties of CFGFORMAT are used to parameterize the packets generated
%   including the data rate and PSDU length.
%
%   WAVEFORM = wlanWaveformGenerator(DATA,CFGFORMAT,Name,Value) specifies
%   additional name-value pair arguments described below. When a name-value
%   pair is not specified, its default value is used.
%
%   'NumPackets'               The number of packets to generate. It must
%                              be a positive integer. The default value is
%                              1.
%
%   'IdleTime'                 The length in seconds of an idle period
%                              after each generated packet. The valid range
%                              depends on the format to generate. For DMG
%                              it must be 0 or greater than or equal to
%                              1e-6 seconds. For all other formats it must
%                              be 0 or greater than or equal to 2e-6
%                              seconds. The default value is 0 seconds.
%
%   'OversamplingFactor'       The oversampling factor used by the
%                              function to generate the waveform, applied
%                              for EHT, HE, WUR, S1G, VHT, HT, and non-HT
%                              OFDM formats. The oversampling factor must
%                              be >=1. The resultant FFT length must be
%                              even, and the cyclic prefix length in
%                              samples must be integer-valued for all
%                              symbols within a packet. The default value
%                              is 1.
%
%   'ScramblerInitialization'  Scrambler initial state(s), applied for EHT,
%                              HE, DMG, S1G, VHT, HT, and non-HT OFDM
%                              formats. It must be a double or int8-typed
%                              scalar or matrix containing integer values.
%                              The valid range depends on the format to
%                              generate.
%
%                              For DMG Control PHY the valid range is
%                              between 1 and 15 inclusive. For other DMG
%                              formats, the valid range is between 1 and
%                              127 inclusive.
%
%                              For HE, S1G, VHT, and HT formats, the valid
%                              range is between 1 and 127 inclusive.
%
%                              For EHT, the valid range is between 1 and
%                              2047 inclusive.
%
%                              For Non-HT OFDM the valid range depends on
%                              whether bandwidth signaling is enabled.
%
%                              When bandwidth signaling is not used
%                              (CFGFORMAT.SignalChannelBandwidth is false)
%                              the specified value is the initial state of
%                              the scrambler. The specified value must be
%                              between 1 and 127 inclusive.
%
%                              When bandwidth signaling is used
%                              (CFGFORMAT.SignalChannelBandwidth is true),
%                              the specified value is the initial
%                              pseudorandom scrambler sequence as
%                              described in IEEE 802.11-2020 Table 17-7.
%                              The valid range depends on the value of
%                              CFGFORMAT.BandwidthOperation and
%                              CFGFORMAT.ChannelBandwidth. For more
%                              information, see: <a href="matlab:doc('wlanwaveformgenerator')">wlanWaveformGenerator</a>
%                              documentation.
%
%                              To initialize all packets with the same
%                              state for all users, specify this input as a
%                              scalar.
%
%                              To initialize each packet with a distinct
%                              state, specify this input as a column vector
%                              of length NumUsers. The function uses these
%                              initial states for all users.
%
%                              To initialize each packet with a distinct
%                              state for each user, specify this input as a
%                              matrix of size NumPackets-by-NumUsers. Each
%                              column specifies the initial states for a
%                              single user. Each row specifies the initial
%                              state of the corresponding packet.
%
%                              If the number of packets in the waveform
%                              exceeds the number of rows you provide in
%                              this input, the function generates the
%                              waveform by looping the rows.
%
%                              For all formats except DMG, the default
%                              value is 93, which is the example state
%                              given in IEEE Std 802.11-2020 Section
%                              I.1.5.2. For the DMG format, the value
%                              specified will override the
%                              ScramblerInitialization property of the
%                              configuration object. The mapping of the
%                              initialization bits on scrambler schematic
%                              X1 to X7 is specified in IEEE Std
%                              802.11-2020, Section 17.3.5.5. For more
%                              information, see: <a href="matlab:doc('wlanwaveformgenerator')">wlanWaveformGenerator</a>
%                              documentation.
%
%   'WindowTransitionTime'     The windowing transition length in seconds,
%                              applied to OFDM based formats. For all
%                              formats except DMG it must be a nonnegative
%                              scalar and no greater than 16e-6 seconds.
%                              Specifying it as 0 turns off windowing. For
%                              all formats except DMG, the default value is
%                              1e-7 seconds. For DMG OFDM format it must be
%                              a nonnegative scalar and no greater than
%                              9.6969e-08 (256/2640e6) seconds. The default
%                              value for DMG format is 6.0606e-09
%                              (16/2640e6) seconds.
%
%   Examples:
%
%   Example 1:
%       %  Generate a time domain signal txWaveform for an 802.11ac VHT
%       %  transmission with 10 packets and 20 microsecond idle period
%       %  between packets.
%
%       numPkts = 10;                   % 10 packets in the waveform
%
%       cfgVHT = wlanVHTConfig();       % Create format configuration
%       % Change properties from defaults
%       cfgVHT.NumTransmitAntennas = 2; % 2 transmit antennas
%       cfgVHT.NumSpaceTimeStreams = 2; % 2 spatial streams
%       cfgVHT.MCS = 1;                 % Modulation: QPSK Rate: 1/2
%       cfgVHT.APEPLength = 1024;       % A-MPDU length in bytes
%
%       % Create bit vector containing concatenated PSDUs
%       numBits = cfgVHT.PSDULength*8*numPkts;
%       dataBits = randi([0 1],numBits,1);
%
%       txWaveform = wlanWaveformGenerator(dataBits, cfgVHT, ...
%           'NumPackets', numPkts, 'IdleTime', 20e-6, ...
%           'WindowTransitionTime', 1e-7);
%
%   Example 2:
%       %  Generate a waveform containing a single 802.11a packet without
%       %  any windowing.
%
%       cfgNonHT = wlanNonHTConfig(); % Create format configuration
%
%       psdu = randi([0 1], cfgNonHT.PSDULength*8, 1); % Create a PSDU
%
%       txWaveform = wlanWaveformGenerator(psdu, cfgNonHT, ...
%           'WindowTransitionTime', 0); % Disable windowing
%
%   Example 3:
%       %  Generate a waveform containing a single DMG packet with a
%       %  specified scrambler initialization.
%
%       cfgDMG = wlanDMGConfig(); % Create format configuration
%       cfgDMG.MCS = 1;           % Single carrier
%       cfgDMG.ScramblerInitialization = 93; % Specify initialization
%
%       psdu = randi([0 1], cfgDMG.PSDULength*8, 1); % Create a PSDU
%
%       txWaveform = wlanWaveformGenerator(psdu, cfgDMG);
%
%   Example 4:
%       %  Generate a waveform containing a multiple DMG packets, each with
%       %  a random scrambler initialization.
%
%       cfgDMG = wlanDMGConfig(); % Create format configuration
%       numPkts = 4; % Generate 4 packets
%
%       % Create bit vector containing concatenated PSDUs
%       numBits = cfgDMG.PSDULength*8*numPkts;
%       dataBits = randi([0 1],numBits,1);
%
%       txWaveform = wlanWaveformGenerator(dataBits, cfgDMG, ...
%           'NumPackets', numPkts, ...
%           'IdleTime', 1e-5, ...
%           'ScramblerInitialization', randi([1 15],numPkts,1));
%
%   Example 5:
%       %  Generate a waveform containing an 802.11ax HE single user packet
%       %  without any windowing.
%
%       cfgHESU = wlanHESUConfig(); % Create format configuration
%
%       psdu = randi([0 1], getPSDULength(cfgHESU)*8, 1); % Create a PSDU
%
%       txWaveform = wlanWaveformGenerator(psdu, cfgHESU, ...
%           'WindowTransitionTime', 0); % Disable windowing
%
%   Example 6:
%       %  Generate a waveform containing an 802.11ax HE multi user packet
%       %  with Packet Extension, for two RUs and two users.
%
%       cfgHEMU = wlanHEMUConfig([192 192]); % Create format configuration
%       cfgHEMU.User{1}.NominalPacketPadding = 16;
%       cfgHEMU.User{2}.NominalPacketPadding = 8;
%
%       % Generate a random PSDU for each user
%       psdu = cell(1,numel(cfgHEMU.User));
%       psduLength = getPSDULength(cfgHEMU);
%       for i = 1:numel(cfgHEMU.User)
%           psdu{i} = randi([0 1],psduLength(i)*8,1,'int8');
%       end
%
%       txWaveform = wlanWaveformGenerator(psdu, cfgHEMU);
%
%   Example 7:
%       %  Generate a waveform containing an 802.11ax HE trigger-based
%       %  packet without any windowing. The trigger method used to
%       %  generate the HE TB PPDU is set to TriggerFrame (by default).
%
%       cfgHETB = wlanHETBConfig(); % Create format configuration
%
%       psdu = randi([0 1], getPSDULength(cfgHETB)*8, 1); % Create a PSDU
%
%       txWaveform = wlanWaveformGenerator(psdu, cfgHETB, ...
%           'WindowTransitionTime', 0); % Disable windowing
%
%   Example 8:
%       %  Generate a waveform containing an 802.11ba WUR packet of 20 MHz
%       %  without any windowing.
%
%       cfgWUR = wlanWURConfig(); % Create format configuration
%
%       psdu = randi([0 1], getPSDULength(cfgWUR)*8, 1); % Create a PSDU
%
%       txWaveform = wlanWaveformGenerator(psdu, cfgWUR, ...
%           'WindowTransitionTime', 0); % Disable windowing
%
%   Example 9:
%       % Generate a non-OFDMA, full-band, single-user 320 MHz time domain
%       % signal for an 802.11be EHT MU transmission with 10 packets and 20
%       % microsecond idle period between packets.
%
%       numPkts = 10; % 10 packets in the waveform
%
%       cfg = wlanEHTMUConfig('CBW320'); % Create format configuration
%
%       % Change properties from defaults
%       cfg.NumTransmitAntennas = 2;         % 2 transmit antennas
%       cfg.User{1}.NumSpaceTimeStreams = 2; % 2 spatial streams
%       cfg.User{1}.MCS = 12;                % 4096 QAM Rate: 3/4
%       cfg.User{1}.APEPLength = 1024;       % A-MPDU length in bytes
%
%       % Create bit vector containing concatenated PSDUs
%       numBits = psduLength(cfg)*8*numPkts;
%       data = randi([0 1],numBits,1);
%
%       txWaveform = wlanWaveformGenerator(data,cfg, ...
%           'NumPackets',numPkts,'IdleTime',20e-6, ...
%           'WindowTransitionTime',1e-7);
%
%   Example 10:
%       % Generate a punctured non-OFDMA 160 MHz, MU-MIMO 802.11be EHT MU
%       % packet for three users. The second 20 MHz subchannel of a 160 MHz
%       % channel is punctured.
%
%       % Create format configuration
%       cfg = wlanEHTMUConfig('CBW160','NumUsers',3,'PuncturedChannelFieldValue',2);
%       cfg.NumTransmitAntennas = 3;
%
%       allocInfo = ruInfo(cfg); % Get allocation information
%       userInput = cell(1,allocInfo.NumUsers);
%       psduLen = psduLength(cfg); % Get PSDU length
%       for i=1:allocInfo.NumUsers % Create a PSDU
%           userInput{i} = randi([0 1],psduLen(i)*8,1);
%       end
%
%       % Create packet with random bit for all users
%       txWaveform = wlanWaveformGenerator(userInput,cfg);
%
%   Example 11:
%       % Generate a 160 MHz, OFDMA waveform with two RUs. The first RU is
%       % MRU2 996+484 containing eight users in a MU-MIMO configuration.
%       % The second RU is of size 484. There are two users in this RU in a
%       % MU-MIMO configuration.
%
%       % Create format configuration
%       cfg = wlanEHTMUConfig([146 146 30 30 73 29 144 144]);
%
%       cfg.NumTransmitAntennas = 8;
%       allocInfo = ruInfo(cfg);
%
%       % Space time stream for all users
%       userSTS = [1 1 1 1 1 1 1 1 4 4];
%       for u=1:allocInfo.NumUsers
%           cfg.User{u}.NumSpaceTimeStreams = userSTS(u);
%           cfg.User{u}.MCS = 12;
%           cfg.User{u}.APEPLength = randi(500,1,1);
%       end
%
%       % Get PSDULength for all users
%       psduLen = psduLength(cfg);
%       userInput = cell(1,allocInfo.NumUsers);
%       for i=1:allocInfo.NumUsers
%           userInput{i} = randi([0 1],psduLen(i)*8,1);
%       end
%
%       % Create a packet with random bit for all users
%       wlanWaveformGenerator(userInput,cfg);
%
%   See also wlanVHTConfig, wlanHTConfig, wlanNonHTConfig, wlanS1GConfig,
%   wlanDMGConfig, wlanHESUConfig, wlanHEMUConfig, wlanHETBConfig,
%   wlanWURConfig, wlanEHTMUConfig, wirelessWaveformGenerator.

%   Copyright 2015-2022 The MathWorks, Inc.

%#codegen

% Check number of input arguments
coder.internal.errorIf(mod(nargin, 2) == 1, 'wlan:wlanWaveformGenerator:InvalidNumInputs');

% Validate the format configuration object is a valid type
validateattributes(cfgFormat,{'wlanVHTConfig','wlanHTConfig','wlanNonHTConfig','wlanS1GConfig','wlanDMGConfig','wlanHESUConfig','wlanHEMUConfig','wlanHETBConfig','wlanWURConfig','wlanEHTMUConfig'},{'scalar'},mfilename,'format configuration object');
s = validateConfig(cfgFormat);

% Get format
isNonHT = isa(cfgFormat,'wlanNonHTConfig');
isDMG = isa(cfgFormat,'wlanDMGConfig');
inDSSSMode = isNonHT && strcmpi(cfgFormat.Modulation,'DSSS');
isDMGOFDM = isDMG && strcmp(phyType(cfgFormat),'OFDM');
isS1G = isa(cfgFormat,'wlanS1GConfig');
isVHT = isa(cfgFormat,'wlanVHTConfig');
isHT = isa(cfgFormat,'wlanHTConfig');
isHEMU = isa(cfgFormat,'wlanHEMUConfig');
isHE = isa(cfgFormat,'wlanHESUConfig') || isa(cfgFormat,'wlanHETBConfig') || isHEMU;
isWUR = isa(cfgFormat,'wlanWURConfig');
isEHTMU = isa(cfgFormat,'wlanEHTMUConfig');
isOFDM = isHE || isDMGOFDM || isS1G || isVHT || isHT || isWUR || isEHTMU ||...
    (isNonHT && strcmpi(cfgFormat.Modulation,'OFDM'));

% Define default values
defaultScramblerInitialization = 93;
if isNonHT && cfgFormat.SignalChannelBandwidth
    % If bandwidth signaling is used then take only the most significant
    % bits required from the default
    numScramBits = 7;
    [~,numRandomBits] = scramblerRange(cfgFormat);
    defaultScramblerInitialization = bitshift(93,-(numScramBits-numRandomBits));
end
if isDMG
    winTransitTime = 16/2640e6; % Windowing length of 16
else
    winTransitTime = 1e-7;
end
defaultParams = struct('NumPackets', 1, ...
                       'IdleTime', 0, ...
                       'ScramblerInitialization', defaultScramblerInitialization, ...
                       'WindowTransitionTime', winTransitTime, ...
                       'OversamplingFactor', 1);

overrideObjectScramInit = false;
if nargin==2
    useParams = defaultParams;
else
    % Validation functions for values
    numPacketsValFn = @(x)validateattributes(x,{'numeric'},{'scalar','integer','>=',0},mfilename,'''NumPackets'' value');
    idleValFn = @(x)validateIdleTime(x,isDMG);
    scramValFn = @(x)validateScramblerInitialization(x,inDSSSMode,isDMG,isNonHT,isWUR,isOFDM,isEHTMU,cfgFormat);
    winValFn = @(x)validateWindowTransitionTime(x,isOFDM,isHE,isDMG,isS1G,isNonHT,isEHTMU,cfgFormat);
    osfValFn = @(x)validateOSF(x,isDMG,inDSSSMode);

    % Extract PV pairs
    if isempty(coder.target) % Simulation path
        p = inputParser;
        addParameter(p,'NumPackets',defaultParams.NumPackets,numPacketsValFn);
        addParameter(p,'IdleTime',defaultParams.IdleTime,idleValFn);
        addParameter(p,'ScramblerInitialization',defaultParams.ScramblerInitialization,scramValFn);
        addParameter(p,'WindowTransitionTime',defaultParams.WindowTransitionTime,winValFn);
        addParameter(p,'OversamplingFactor',defaultParams.OversamplingFactor,osfValFn);
        parse(p,varargin{:});
        useParams = p.Results;
    else % Codegen path
        nvNames = {'NumPackets','IdleTime','ScramblerInitialization','WindowTransitionTime','OversamplingFactor'};
        pOptions = struct('PartialMatching',true);
        pStruct = coder.internal.parseParameterInputs(nvNames,pOptions,varargin{:});
        useParams = coder.internal.vararginToStruct(pStruct,defaultParams,varargin{:});
        % Validate values
        numPacketsValFn(useParams.NumPackets);
        idleValFn(useParams.IdleTime);
        scramValFn(useParams.ScramblerInitialization);
        winValFn(useParams.WindowTransitionTime);
        osfValFn(useParams.OversamplingFactor);
    end

    % Override scrambler initialization in object if provided in NV pair
    if isDMG && any(useParams.ScramblerInitialization~=93)
        overrideObjectScramInit = true;
    end
end
osf = double(useParams.OversamplingFactor); % Force from numeric to double

if isVHT || isS1G || isWUR
    numUsers = cfgFormat.NumUsers;
elseif isHEMU || isEHTMU
    allocInfo = ruInfo(cfgFormat);
    numUsers = allocInfo.NumUsers;
else
    numUsers = 1;
end

% Cross validation
coder.internal.errorIf(all(size(useParams.ScramblerInitialization,2) ~= [1 numUsers]),'wlan:wlanWaveformGenerator:ScramInitNotMatchNumUsers');

psduLength = s.PSDULength;

% Validate that data bits are present if PSDULength is nonzero
if iscell(dataBits) % SU and MU
    % Data must be a scalar cell or a vector cell of length Nu
    coder.internal.errorIf(~isvector(dataBits) || all(length(dataBits) ~= [1 numUsers]), 'wlan:wlanWaveformGenerator:InvalidDataCell');

    for u = 1:length(dataBits)
        if ~isempty(dataBits{u}) && (psduLength(u)>0) % Data packet
            validateattributes(dataBits{u},{'double','int8'},{'real','integer','vector','binary'},mfilename,'each element in cell data input');
        else
            % Empty data check if not NDP
            coder.internal.errorIf((psduLength(u)>0) && isempty(dataBits{u}),'wlan:wlanWaveformGenerator:NoData');
        end
    end
    if isscalar(dataBits)
        % Columnize and expand to a [1 Nu] cell
        dataCell = repmat({int8(dataBits{1}(:))},1,numUsers);
    else % Columnize each element
        numUsers = numel(dataBits); % One cell element per user
        dataCell = repmat({int8(1)},1,numUsers);
        for u = 1:numUsers
            dataCell{u} = int8(dataBits{u}(:));
        end
    end
else % SU and MU: Data must be a vector
    if ~isempty(dataBits) && any(psduLength > 0) % Data packet
        validateattributes(dataBits,{'double','int8'},{'real','integer','vector','binary'}, mfilename,'Data input');

        % Columnize and expand to a [1 Nu] cell
        dataCell = repmat({int8(dataBits(:))}, 1, numUsers);
    else % NDP
        % Empty data check if not NDP
        coder.internal.errorIf(any(psduLength > 0) && isempty(dataBits),'wlan:wlanWaveformGenerator:NoData');

        dataCell = {int8(dataBits(:))};
    end
end

% Number of bits in a PSDU for a single packet (convert bytes to bits)
numPSDUBits = psduLength*8;

% Repeat to provide initial state(s) for all users and packets
scramInit = repmat(useParams.ScramblerInitialization,1,numUsers/size(useParams.ScramblerInitialization,2)); % For all users
pktScramInit = scramInit(mod((0:useParams.NumPackets-1).',size(scramInit,1))+1, :);

if useParams.OversamplingFactor>1 || ~isempty(coder.target)
    % Always pass NV when generating code
    osfNV = {'OversamplingFactor',osf};
else
    osfNV = {};
end

% Get the sampling rate of the waveform
if isDMG
    numTxAnt = 1;
    numPktSamples = s.NumPPDUSamples;

    if strcmp(phyType(cfgFormat),'OFDM')
        sr = 2640e6;
        % In OFDM PHY preamble fields are resampled to OFDM rate
        preamble = wlan.internal.dmgResample([wlan.internal.dmgSTF(cfgFormat); wlan.internal.dmgCE(cfgFormat)]);
        brfields = wlan.internal.dmgResample([wlan.internal.dmgAGC(cfgFormat); wlan.internal.dmgTRN(cfgFormat)]);
    else
        sr = 1760e6;
        preamble = [wlan.internal.dmgSTF(cfgFormat); wlan.internal.dmgCE(cfgFormat)];
        brfields = [wlan.internal.dmgAGC(cfgFormat); wlan.internal.dmgTRN(cfgFormat)];
    end
elseif isHE
    [psps,trc] = wlan.internal.hePacketSamplesPerSymbol(cfgFormat,osf);
    numPktSamples = psps.NumPacketSamples;
    numTxAnt = cfgFormat.NumTransmitAntennas;
    cbw = wlan.internal.cbwStr2Num(cfgFormat.ChannelBandwidth);
    sr = cbw*1e6*osf;
    sf = cbw*1e-3*osf; % Scaling factor to convert bandwidth and time in ns to samples
    symLength = trc.TSYM*sf;
    cpLen = trc.TGIData*sf;
    heltfSymLen = trc.THELTFSYM*sf;
    Npe = wlan.internal.heNumPacketExtensionSamples(trc.TPE,cbw)*osf;

    LSTF = wlan.internal.heLSTF(cfgFormat,osf);
    LLTF = wlan.internal.heLLTF(cfgFormat,osf);
    LSIG = wlan.internal.heLSIG(cfgFormat,osf);
    RLSIG = LSIG; % RL-SIG is identical to L-SIG
    SIGA = wlan.internal.heSIGA(cfgFormat,osf);
    STF = wlan.internal.heSTF(cfgFormat,osf);
    LTF = wlan.internal.heLTF(cfgFormat,osf);
    if isHEMU
        SIGB = wlan.internal.heSIGB(cfgFormat,osf);
        preamble = [LSTF; LLTF; LSIG; RLSIG; SIGA; SIGB; STF; LTF];
    else
        preamble = [LSTF; LLTF; LSIG; RLSIG; SIGA; STF; LTF];
    end
elseif inDSSSMode % DSSS format
    sr = 11e6;
    numTxAnt = 1;
    info = wlan.internal.dsssInfo(cfgFormat);
    numPktSamples = info.NumPPDUSamples;
    psps = struct('NumSamplesPerSymbol',0,'CPPerSymbol',0,'NumPacketSamples',0); % For codegen

    preamble = [wlan.internal.wlanDSSSPreamble(cfgFormat); wlan.internal.wlanDSSSHeader(cfgFormat)];
elseif isWUR % WUR format
    psps = wlan.internal.wurPacketSamplesPerSymbol(cfgFormat,s.NumDataSymbols,s.NumPaddingBits,osf);
    numTxAnt = cfgFormat.NumTransmitAntennas;
    chanBW = cfgFormat.ChannelBandwidth;
    sr = wlan.internal.cbwStr2Num(chanBW)*1e6*osf;
    numPktSamples = psps(1).NumPacketSamples;

    LSTF = wlan.internal.lstf(cfgFormat,osf);
    LLTF = wlan.internal.lltf(cfgFormat,osf);
    LSIG = wlan.internal.wurLSIG(cfgFormat,osf);
    BPSKMark1 = wlan.internal.wurBPSKMark1(cfgFormat,osf);
    BPSKMark2 = wlan.internal.wurBPSKMark2(cfgFormat,osf);
    preamble = [LSTF; LLTF; LSIG; BPSKMark1; BPSKMark2];
elseif isEHTMU
    [psps,trc] = wlan.internal.ehtPacketSamplesPerSymbol(cfgFormat,osf);
    numPktSamples = psps.NumPacketSamples;
    numTxAnt = cfgFormat.NumTransmitAntennas;
    cbw = wlan.internal.cbwStr2Num(cfgFormat.ChannelBandwidth);
    sr = cbw*1e6*osf; % Sampling rate of the waveform
    sf = cbw*1e-3*osf; % Scaling factor to convert bandwidth and time in ns to samples
    symLength = trc.TSYM*sf;
    cpLen = trc.TGIData*sf;
    ehtltfSymLen = trc.TEHTLTFSYM*sf;
    Npe = wlan.internal.heNumPacketExtensionSamples(trc.TPE,cbw)*osf;

    LSTF = wlan.internal.ehtLSTF(cfgFormat,osf);
    LLTF = wlan.internal.ehtLLTF(cfgFormat,osf);
    LSIG = wlan.internal.ehtLSIG(cfgFormat,osf);
    RLSIG = LSIG; % RL-SIG is identical to L-SIG
    USIG = wlan.internal.ehtUSIG(cfgFormat,osf);
    EHTSIG = wlan.internal.ehtSIG(cfgFormat,osf);
    STF = wlan.internal.ehtSTF(cfgFormat,osf);
    LTF = wlan.internal.ehtLTF(cfgFormat,osf);

    preamble = [LSTF; LLTF; LSIG; RLSIG; USIG; EHTSIG; STF; LTF];
else % NonHT/VHT/HT/S1G OFDM format
    chanBW = cfgFormat.ChannelBandwidth;
    sr = wlan.internal.cbwStr2Num(chanBW)*1e6*osf;
    numTxAnt = cfgFormat.NumTransmitAntennas;
    numPktSamples = real(s.NumPPDUSamples)*osf; % real for codegen

    if isS1G
        psps = wlan.internal.s1gPacketSamplesPerSymbol(cfgFormat,s.NumDataSymbols,osf);
        stf = wlan.internal.s1gSTF(cfgFormat,osf);
        if ~strcmp(packetFormat(cfgFormat),'S1G-Long')
            [ltf1, ltf2n] = wlan.internal.s1gLTF(cfgFormat,osf);
            sig = wlan.internal.s1gSIG(cfgFormat,osf);
            preamble = [stf; ltf1; sig; ltf2n];
        else % Preamble == 'Long'
            ltf1 = wlan.internal.s1gLTF1(cfgFormat,osf);
            siga = wlan.internal.s1gSIGA(cfgFormat,osf);
            dstf = wlan.internal.s1gDSTF(cfgFormat,osf);
            dltf = wlan.internal.s1gDLTF(cfgFormat,osf);
            sigb = wlan.internal.s1gSIGB(cfgFormat,osf);
            preamble = [stf; ltf1; siga; dstf; dltf; sigb];
        end
    else
        % Generate the legacy preamble fields for applicable formats
        lstf = wlanLSTF(cfgFormat,osfNV{:});
        lltf = wlanLLTF(cfgFormat,osfNV{:});
        lsig = wlanLSIG(cfgFormat,osfNV{:});
        if isNonHT
            preamble = [lstf; lltf; lsig];
            psps = wlan.internal.nonhtPacketSamplesPerSymbol(cfgFormat,s.NumDataSymbols,osf);
            if any(strcmp(chanBW,{'CBW10','CBW5'}))
                numTxAnt = 1; % Override and set to 1 only, for 802.11j/p
            end
        elseif isVHT
            vhtsiga = wlanVHTSIGA(cfgFormat,osfNV{:});
            vhtstf = wlanVHTSTF(cfgFormat,osfNV{:});
            vhtltf = wlanVHTLTF(cfgFormat,osfNV{:});
            vhtsigb = wlanVHTSIGB(cfgFormat,osfNV{:});
            preamble = [lstf; lltf; lsig; vhtsiga; vhtstf; vhtltf; vhtsigb];
            psps = wlan.internal.vhtPacketSamplesPerSymbol(cfgFormat,s.NumDataSymbols,osf);
        else % isHT
            htSig = wlanHTSIG(cfgFormat,osfNV{:});
            htstf = wlanHTSTF(cfgFormat,osfNV{:});
            htltf = wlanHTLTF(cfgFormat,osfNV{:});
            preamble = [lstf; lltf; lsig; htSig; htstf; htltf];
            psps = wlan.internal.htPacketSamplesPerSymbol(cfgFormat,s.NumDataSymbols,osf);
        end
    end
end

% Define a matrix of total simulation length
numIdleSamples = round(sr*useParams.IdleTime);
pktWithIdleLength = numPktSamples+numIdleSamples;
txWaveform = complex(zeros(useParams.NumPackets*pktWithIdleLength,numTxAnt));

if isWUR
    if useParams.NumPackets > 0
        preambleLength = sum(psps(1).NumSamplesPerSymbolPreamble);
        subchannel = complex(zeros(useParams.NumPackets*pktWithIdleLength,numTxAnt,cfgFormat.NumUsers));
        activeSubchannelIndex = getActiveSubchannelIndex(cfgFormat);
        wurSamplesIndex = zeros(useParams.NumPackets,psps(1).NumWURSamples);
        for i = 1:useParams.NumPackets % Generate the WUR Sync and Data fields for all packets
            psdu = getPSDUForCurrentPacket(dataCell, numPSDUBits, i);
            wurSamplesIndex(i,:) = (1+(i-1)*pktWithIdleLength+preambleLength):(i*pktWithIdleLength-numIdleSamples);
            for j = 1:cfgFormat.NumUsers % Generate the WUR Sync and Data fields for all active subchannels
                syncWUR = wlan.internal.wurSync(cfgFormat,osf,activeSubchannelIndex(j));
                dataWUR = wlan.internal.wurData(psdu{j},cfgFormat,osf,activeSubchannelIndex(j));
                % Create the waveform of Sync and Data fields only; the preamble is empty
                subchannel(wurSamplesIndex(i,:),:,j) = [syncWUR;dataWUR];
            end
        end

        if useParams.WindowTransitionTime > 0
            wLength = 2*ceil(useParams.WindowTransitionTime*sr/2); % Window length in samples
            [preamble,pre,post] = wlan.internal.windowWaveform(preamble,psps(1).NumSamplesPerSymbolPreamble,psps(1).CPPerSymbolPreamble,wLength); % Window the preamble fields
            % Window the Sync and Data fields for each user separately as
            % the data rate may differ. As the preamble portion of the
            % waveform is empty, the start of the windowed subchannel will
            % contain the postfix of the Data field, and the samples at the
            % end of the preamble will contain the prefix of the Sync
            % field.
            for j = 1:cfgFormat.NumUsers
                subchannel(:,:,j) = wlan.internal.windowWaveform(subchannel(:,:,j),psps(j).NumSamplesPerSymbol,psps(j).CPPerSymbol,wLength,useParams.NumPackets,numIdleSamples);
            end
        end
        % Add the Sync and Data fields sample-by-sample for all active subchannels
        txWaveform = sum(subchannel,3);
        % Add the preamble fields and overlap windowed elements
        for i = 1:useParams.NumPackets
            preambleIndex = (i-1)*pktWithIdleLength+(1:preambleLength);
            txWaveform(preambleIndex,:) = txWaveform(preambleIndex,:)+preamble;
            % The above windowing of subchannel and sum with preamble
            % overlaps the prefix and postfix of the Sync and Data fields.
            % Overlap the remaining prefix and postfix of the preamble.
            if useParams.WindowTransitionTime > 0
                % Overlap the first symbol of Sync and Data fields with postfix of Preamble fields
                endPreambleOverlapIndex = preambleIndex(end)+(1:height(post));
                txWaveform(endPreambleOverlapIndex,:) = txWaveform(endPreambleOverlapIndex,:)+post;
                % Overlap the prefix of preamble fields with samples before each packet assuming loopability
                startPreambleOverlapIndex = preambleIndex(1)+pktWithIdleLength-height(post)+(1:height(pre));
                txWaveform(startPreambleOverlapIndex,:) = txWaveform(startPreambleOverlapIndex,:)+pre;
            end
        end
    end
else
    for i = 1:useParams.NumPackets
        % Extract PSDU for the current packet
        psdu = getPSDUForCurrentPacket(dataCell, numPSDUBits, i);

        % Generate the PSDU with the correct scrambler initial state
        if isVHT
            if any(cfgFormat.APEPLength > 0)
                data = wlanVHTData(psdu,cfgFormat,pktScramInit(i,:),osfNV{:});
            else % NDP
                data = complex(zeros(0,cfgFormat.NumTransmitAntennas));
            end
        elseif isHT
            if cfgFormat.PSDULength > 0
                [data, payloadSubcarrier] = wlanHTData(psdu{1},cfgFormat,pktScramInit(i,:),osfNV{:});
                ofdmInfo = wlan.internal.vhtOFDMInfo('HT-Data', cfgFormat.ChannelBandwidth, cfgFormat.GuardInterval);
                txUsefulSubcarrier = payloadSubcarrier(ofdmInfo.ActiveFFTIndices,:,:);
                txDataSubcarrier = txUsefulSubcarrier(ofdmInfo.DataIndices,:,:);
            else % NDP or sounding packet
                data = complex(zeros(0,cfgFormat.NumTransmitAntennas));
            end
        elseif isNonHT
            if strcmp(cfgFormat.Modulation, 'OFDM')
                data = wlanNonHTData(psdu{1},cfgFormat,pktScramInit(i,:),osfNV{:});
            else % DSSS
                data = wlan.internal.wlanDSSSData(psdu{1},cfgFormat);
            end
        elseif isS1G
            data = wlan.internal.s1gData(psdu,cfgFormat,pktScramInit(i,:),osf);
        elseif isDMG
            % Header and data scrambled so generate for each packet together

            % Override scrambler initialization in configuration object if
            % supplied by the user to the waveform generator
            if overrideObjectScramInit
                cfgFormat.ScramblerInitialization = pktScramInit(i,:);
            end

            data = [wlan.internal.dmgHeader(psdu{1},cfgFormat); wlan.internal.dmgData(psdu{1},cfgFormat); brfields];
        elseif isHE
            if any(psduLength > 0)
                data = wlan.internal.heData(psdu,cfgFormat,pktScramInit(i,:),osf);

                % Midamble processing
                Mma = cfgFormat.MidamblePeriodicity;
                Nsym = s.NumDataSymbols;
                Nma = wlan.internal.numMidamblePeriods(cfgFormat,Nsym); % Midamble period
                if Nma>0
                    % Reshape data symbols till last midamble in to data symbol blocks
                    dataSymBlk = reshape(data(1:Nma*symLength*Mma,:),symLength*Mma,Nma,numTxAnt);
                    % Repeat HELTF symbols for each data symbol block
                    heltfSymBlk = repmat(permute(LTF,[1,3,2]),1,Nma,1);
                    % Append midamble after each data symbol block
                    dataMidambleBlk = [dataSymBlk; heltfSymBlk];
                    % Reshape and append leftover data samples after the last midamble
                    dataMidambleBlkReshape = permute(reshape(dataMidambleBlk,[],1,numTxAnt),[1 3 2]);
                    data = [dataMidambleBlkReshape(:,:,1); data(Nma*symLength*Mma+1:end,:)]; % Index 3rd dimension for codegen
                end
                dataPacket = data;

                % Packet Extension
                lastDataSymBlk = data(end-symLength+cpLen+1:end,:);
                packetExt = getPacketExtensionData(lastDataSymBlk,Npe);
                data = [dataPacket; packetExt];
            else % NDP
                lastDataSymBlk = preamble(end-heltfSymLen+cpLen+1:end,:);
                packetExt = getPacketExtensionData(lastDataSymBlk,Npe);
                data = packetExt;
            end
        elseif isEHTMU
            if any(psduLength>0)
                % Extract PSDU for the current packet
                psdu = getPSDUForCurrentPacket(dataCell,numPSDUBits,i);

                % Generate the PSDU with the correct scrambler initial state
                dataPacket = wlan.internal.ehtData(psdu,cfgFormat,pktScramInit(i,:),useParams.OversamplingFactor);

                % Packet Extension
                lastDataSymBlk = dataPacket(end-symLength+cpLen+1:end,:);
                packetExt = getPacketExtensionData(lastDataSymBlk,Npe);
                data = [dataPacket; packetExt];
            else % NDP
                lastDataSymBlk = preamble(end-ehtltfSymLen+cpLen+1:end,:);
                data = getPacketExtensionData(lastDataSymBlk,Npe);
            end
        end

        % Construct packet from preamble and data
        pktIdx = (i-1)*pktWithIdleLength+(1:numPktSamples);
        txWaveform(pktIdx,:) = [preamble; data];
    end

    if isOFDM && useParams.NumPackets > 0 && useParams.WindowTransitionTime > 0
        % Window waveform
        wLength = 2*ceil(useParams.WindowTransitionTime*sr/2); % Window length in samples
        if ~isDMG
            % Ensure window transition time is within 2x smallest CP length
            maxWLength = 2*min(psps.CPPerSymbol(psps.CPPerSymbol>0));
            coder.internal.errorIf(wLength>maxWLength,'wlan:wlanWaveformGenerator:InvalidWindowLength',round(maxWLength/(sr/1e9)));
            txWaveform = wlan.internal.windowWaveform(txWaveform,psps.NumSamplesPerSymbol,psps.CPPerSymbol,wLength,useParams.NumPackets,numIdleSamples);
        else
            txWaveform = wlan.internal.dmgWindowing(txWaveform,wLength,cfgFormat,useParams.NumPackets,numIdleSamples);
        end
    end
end
end

function packetExt = getPacketExtensionData(lastDataSymBlk,Npe)
% Cyclic extension of last symbol for packet extension
    if size(lastDataSymBlk,1)>=Npe
        packetExt = lastDataSymBlk(1:Npe,:);
    else
        buffCntt = ceil(Npe/size(lastDataSymBlk,1));
        dataBuffer = repmat(lastDataSymBlk,buffCntt,1);
        packetExt = dataBuffer(1:Npe,:);
    end
end

function psdu = getPSDUForCurrentPacket(dataCell,numPSDUBitsPerPacket,packetIdx)
    numUsers = length(dataCell); % == length(numPSDUBits)
    psdu = repmat({int8(1)},1,numUsers); % Cannot use cell(1, numUsers) for codegen
    for u = 1:numUsers
        psdu{u} = wlan.internal.parseInputBits(dataCell{u},numPSDUBitsPerPacket(u),(packetIdx-1)*numPSDUBitsPerPacket(u));
    end
end

function validateIdleTime(idleTime,isDMG)
    % Validate IdleTime
    validateattributes(idleTime,{'numeric'},{'scalar','real','>=',0},mfilename,'''IdleTime'' value');
    if isDMG
        minIdleTime = 1e-6;
    else % S1G, VHT, HT, non-HT
        minIdleTime = 2e-6;
    end
    coder.internal.errorIf((idleTime > 0) && (idleTime < minIdleTime),'wlan:wlanWaveformGenerator:InvalidIdleTimeValue',sprintf('%1.0d',minIdleTime));
end

function validateScramblerInitialization(scramInit,inDSSSMode,isDMG,isNonHT,isWUR,isOFDM,isEHTMU,cfgFormat)
    % Validate ScramblerInitialization
    if (inDSSSMode || isWUR)
        return % Not applicable if DSSS or WUR
    end
    if isDMG && any(scramInit~=93)
        if strcmp(phyType(cfgFormat),'Control')
            coder.internal.errorIf(any((scramInit<1) | (scramInit>15)),'wlan:wlanWaveformGenerator:InvalidScramblerInitialization','Control',1,15);
        elseif wlan.internal.isDMGExtendedMCS(cfgFormat.MCS)
            % At least one of the initialization bits must be non-zero,
            % therefore determine if the pseudorandom part can be 0
            % given the extended MCS and PSDU length.
            if all(wlan.internal.dmgExtendedMCSScramblerBits(cfgFormat)==0)
                minScramblerInit = 1; % Pseudorandom bits cannot be all zero
            else
                minScramblerInit = 0; % Pseudorandom bits can be all zero
            end
            coder.internal.errorIf(any((scramInit<minScramblerInit) | (scramInit>31)),'wlan:wlanWaveformGenerator:InvalidScramblerInitialization','SC extended MCS',minScramblerInit,31);
        else
            coder.internal.errorIf(any((scramInit<1) | (scramInit>127)),'wlan:wlanWaveformGenerator:InvalidScramblerInitialization','SC/OFDM',1,127);
        end
    elseif isEHTMU
        % Validate scrambler initialization
        validateattributes(scramInit,{'double','int8'},{'real','integer','2d','nonempty'},mfilename,'''ScramblerInitialization'' value');
        if any((scramInit<1) | (scramInit>2047),'all')
            coder.internal.error('wlan:wlanWaveformGenerator:InvalidScramInit',1,2047);
        end
    else
        if isNonHT && isOFDM && ...
                any(strcmp(cfgFormat.ChannelBandwidth,{'CBW20','CBW40','CBW80','CBW160'})) ...
                && cfgFormat.SignalChannelBandwidth
            % Non-HT may include bandwidth signaling

            % Validate type
            validateattributes(scramInit,{'double','int8'}, ...
                               {'real','integer','2d','nonempty'},mfilename,'''ScramblerInitialization'' value');

            % Validate range
            range = scramblerRange(cfgFormat);
            minVal = range(1);
            maxVal = range(2);
            % Check for correct range
            if any((scramInit<minVal) | (scramInit>maxVal),'all')
                coder.internal.error('wlan:wlanWaveformGenerator:InvalidScramInitBWSignaling',minVal,maxVal);
            end
        else
            % Validate scrambler initialization
            validateattributes(scramInit,{'double','int8'},{'real','integer','2d','nonempty'},mfilename,'''ScramblerInitialization'' value');
            if any((scramInit<1) | (scramInit>127),'all')
                coder.internal.error('wlan:wlanWaveformGenerator:InvalidScramInit',1,127);
            end
        end
    end
end

function validateWindowTransitionTime(tt,isOFDM,isHE,isDMG,isS1G,isNonHT,isEHTMU,cfgFormat)
    % Validate WindowTransitionTime
    if ~isOFDM
        return % Not applicable unless OFDM
    end
    % Set maximum limits for windowing transition time based on bandwidth and format
    if isHE || isEHTMU
        maxWinTransitTime = 6.4e-6; % Seconds
    elseif isDMG
        maxWinTransitTime = 9.6969e-08; % Seconds
    elseif isS1G
        maxWinTransitTime = 16e-6; % Seconds
    elseif isNonHT
        switch cfgFormat.ChannelBandwidth
          case 'CBW5'
            maxWinTransitTime = 6.4e-6; % Seconds
          case 'CBW10'
            maxWinTransitTime = 3.2e-6; % Seconds
          otherwise % 'CBW20'
            maxWinTransitTime = 1.6e-6; % Seconds
        end
    else % HT/VHT/WUR
        maxWinTransitTime = 1.6e-6; % Seconds
    end
    validateattributes(tt,{'numeric'},{'real','scalar','>=',0,'<=',maxWinTransitTime},mfilename,'''WindowTransitionTime'' value');
end

function validateOSF(osf,isDMG,inDSSSMode)
    % Validate OversamplingFactor
    validateattributes(osf,{'numeric'},{'real','finite','scalar','>=',1},mfilename,'OversamplingFactor')
    if (isDMG || inDSSSMode)
        coder.internal.errorIf(osf~=1,'wlan:wlanWaveformGenerator:invalidOSFNonOFDM');
    end
end