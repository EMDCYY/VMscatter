classdef (StrictDefaults)wlanTGnChannel < wlan.internal.ChannelBase
%wlanTGnChannel Filter input signal through a TGn multipath fading channel
%   tgn = wlanTGnChannel creates a System object, tgn, for the TGn channel
%   model as specified by the IEEE 802.11 Wireless LAN Working group [1],
%   which follows the MIMO modeling approach presented in [2]. This object
%   filters a real or complex input signal through the multipath, TGn
%   channel to obtain the channel impaired signal.
%
%   tgn = wlanTGnChannel(Name,Value) creates a TGn channel object,
%   tgn, with the specified property Name set to the specified Value.
%   You can specify additional name-value pair arguments in any order as
%   (Name1,Value1,...,NameN,ValueN).
%
%   Step method syntax for ChannelFiltering set to true:
%
%   Y = step(tgn,X) filters input signal X through a TGn fading channel and
%   returns the result in Y. The input X can be a double or single
%   precision, matrix of size Ns-by-Nt, where Ns is the number of samples
%   and Nt is the number of transmit antennas. Nt must be equal to the
%   NumTransmitAntennas property value of tgn. Y is the output signal of
%   size Ns-by-Nr, where Nr is the number of receive antennas, which is
%   determined by the NumReceiveAntennas property value of tgn. Y contains
%   values of the same type as the input signal X.
% 
%   [Y,PATHGAINS] = step(tgn,X) returns the TGn channel path gains of the
%   underlying fading process in PATHGAINS. Use this syntax when
%   PathGainsOutputPort property of tgn is set to true. PATHGAINS is of
%   size Ns-by-Np-by-Nt-by-Nr, where Np is the number of resolvable paths,
%   that is, the number of paths defined for the case specified by the
%   DelayProfile property. PATHGAINS is of the same type as input X.
%
%   Step method syntax for ChannelFiltering set to false:
%
%   PATHGAINS = step(tgn) produces path gains PATHGAINS where the duration
%   of the fading process is given by the NumSamples property. In this case
%   the object acts as a source of path gains without filtering an input
%   signal. The type of PATHGAINS is controlled by the property
%   OutputDataType.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
% 
%   wlanTGnChannel methods:
%
%   step     - Filter input signal through a MIMO fading channel (see above)
%   release  - Allow property value and input characteristics changes
%   clone    - Create TGn channel object with same property values
%   isLocked - Locked status (logical)
%   <a href="matlab:help matlab.System/reset   ">reset</a>    - Reset states of filters, and random stream if the
%              RandomStream property is set to 'mt19937ar with seed'
%   <a href="matlab:help wlanTGnChannel/infoImpl   ">info</a>    -  Return characteristic information about the TGn channel 
%
%   wlanTGnChannel properties:
%
%   SampleRate              - Input signal sample rate (Hz)
%   DelayProfile            - Delay profile models for WLAN
%   CarrierFrequency        - Carrier frequency (Hz)
%   EnvironmentalSpeed      - Speed of the scatterers (km/h)
%   TransmitReceiveDistance - Distance between transmit and receive (m)
%   NormalizePathGains      - Normalize path gains (logical)
%   NumTransmitAntennas     - Number of transmit antennas
%   TransmitAntennaSpacing  - Transmit antenna spacing in wavelength
%   NumReceiveAntennas      - Number of receive antennas
%   ReceiveAntennaSpacing   - Receive antenna spacing in wavelength
%   LargeScaleFadingEffect  - Inclusion of large scale fading effect
%   FluorescentEffect       - Enable fluorescent effect in channel modeling (logical)
%   PowerLineFrequency      - Power line frequency (Hz)
%   NormalizeChannelOutputs - Normalize channel outputs (logical)
%   ChannelFiltering        - Enable filtering of input signal
%   NumSamples              - Number of time samples
%   OutputDataType          - PATHGAINS data type when the ChannelFiltering is false
%   RandomStream            - Source of random number stream
%   Seed                    - Initial seed of mt19937ar random number stream
%   PathGainsOutputPort     - Enable path gain output (logical)
%
%   % Example:  
%   %   Filter a HT waveform through a TGn channel.
%
%   cfgHT = wlanHTConfig; % Create packet configuration
%   txWaveform = wlanWaveformGenerator([1;0;0;1],cfgHT);
%   tgnChannel = wlanTGnChannel;
%   channelOutput = tgnChannel(txWaveform);
%
%   % Reference:
%   % [1] Erceg, V., L. Schumacher, P. Kyritsi, et al. TGn Channel Models.
%   % Version 4. IEEE 802.11-03/940r4, May 2004.
%   % [2] Kermoal, J. P., L. Schumacher, K. I. Pedersen, P. E. Mogensen, and
%   % F. Frederiksen, "A Stochastic MIMO Radio Channel Model with
%   % Experimental Validation", IEEE Journal on Selected Areas in
%   % Communications, Vol. 20, No. 6, August 2002, pp. 1211-1226.
%
%   See also wlanTGacChannel, wlanTGahChannel, wlanTGaxChannel.

% Copyright 2015-2019 The MathWorks, Inc.

%#codegen

% Public properties
properties (Nontunable)
    %SampleRate Sample rate (Hz)
    %   Specify the sample rate of the input signal in Hz as a double
    %   precision, real, positive scalar. The default is 20e6 Hz.
    SampleRate = 20e6;
    %NumTransmitAntennas Number of transmit antennas
    %   Specify the number of transmit antennas as a numeric, positive
    %   integer scalar greater than or equal to 1. The default is 1.
    NumTransmitAntennas = 1;
    % TransmitAntennaSpacing Transmit antenna spacing in wavelengths
    %   Spacing of the regular geometry of the antenna elements at the
    %   transmitter, in wavelengths. Only uniform linear array is
    %   supported. This property applies only when NumTransmitAntennas is
    %   greater than 1. The default is 0.5.
    TransmitAntennaSpacing = 0.5;
    %NumReceiveAntennas Number of receive antennas
    %   Specify the number of receive antennas as a numeric, positive
    %   integer scalar greater than or equal to 1. The default is 1.
    NumReceiveAntennas = 1;
    % ReceiveAntennaSpacing Receive antenna spacing in wavelengths
    %   Spacing of the regular geometry of the antenna elements at the
    %   receiver, in wavelengths. Only uniform linear array is supported.
    %   This property applies only when NumReceiveAntennas is greater than
    %   1. The default is 0.5.
    ReceiveAntennaSpacing = 0.5;
    % CarrierFrequency Carrier frequency (Hz) 
    %   Specify the carrier frequency of the input signal in Hz. The
    %   default is 5.25e9 Hz.
    CarrierFrequency = 5.25e9;
    % EnvironmentalSpeed Speed of the scatterers (km/h)
    %   Specify the speed of the moving scatterers in km/h as numeric
    %   positive scalar greater than or equal to zero. The TGn channel
    %   document specify an environment speed of 1.2 km/h. The default is
    %   1.2 km/h.
    EnvironmentalSpeed = 1.2;
end

properties (Access = public)
    %NumSamples Number of time samples
    %   Specify the number of time samples used to get path gain samples
    %   for the duration of the fading process realization. This property
    %   must be a positive integer scalar and applies when ChannelFiltering
    %   is false. This property is tunable. The default value of this
    %   property is 80.
    NumSamples (1,1) {mustBeInteger, mustBePositive, mustBeReal} = 80;
end

properties(Constant, Hidden)
    UserIndex = 0;
    ChannelBandwidth = 'CBW20';
    TransmissionDirection = 'Downlink';
    NumPenetratedFloors = 0;
    NumPenetratedWalls = 0;
    WallPenetrationLoss = 0;
    InterpolationFactor = 1/10;
end

methods
  function obj = wlanTGnChannel(varargin)
    setProperties(obj, nargin, varargin{:});
    obj.pLegacyGenerator = false;
  end 
  
  function set.SampleRate(obj, val)
    propName = 'SampleRate';
        validateattributes(val, {'double'}, ...
            {'real','scalar','positive','finite'}, ...
            [class(obj) '.' propName], propName);   
    obj.SampleRate = val;
  end
  
  function set.NumTransmitAntennas(obj, val)
    propName = 'NumTransmitAntennas';
    validateattributes(val, {'numeric'}, ...
        {'real','scalar','integer','>=',1}, ...
        [class(obj) '.' propName], propName);
    obj.NumTransmitAntennas = val;
  end
  
  function set.TransmitAntennaSpacing(obj, val)
    propName = 'TransmitAntennaSpacing';
    validateattributes(val, {'numeric'}, ...
        {'real','scalar','>',0, 'finite'}, ...
        [class(obj) '.' propName], propName);
    obj.TransmitAntennaSpacing = val;
  end
  
  function set.NumReceiveAntennas(obj, val)
    propName = 'NumReceiveAntennas';
    validateattributes(val, {'numeric'}, ...
        {'real','scalar','integer','>=',1}, ...
        [class(obj) '.' propName], propName);
    obj.NumReceiveAntennas = val;
  end

  function set.ReceiveAntennaSpacing(obj, val)
    propName = 'ReceiveAntennaSpacing';
    validateattributes(val, {'numeric'}, ...
        {'real','scalar','>',0, 'finite'},  ...
        [class(obj) '.' propName], propName);
    obj.ReceiveAntennaSpacing = val;
  end
  
  function set.CarrierFrequency(obj, val)
     propName = 'CarrierFrequency';
        validateattributes(val, {'numeric'}, ...
            {'real','scalar','>',0,'finite'}, ...
            [class(obj) '.' propName], propName); 
      obj.CarrierFrequency = val;
  end
  
  function set.EnvironmentalSpeed(obj, val)
    propName = 'EnvironmentalSpeed';
    validateattributes(val, {'numeric'}, ...
        {'real','scalar','>=',0,'finite'}, ...
        [class(obj) '.' propName], propName);
    obj.EnvironmentalSpeed = val;
  end
end

methods(Access = protected)
  function flag = isInactivePropertyImpl(obj, prop)
    % Use the if-else format for codegen
    if strcmp(prop, 'TransmitAntennaSpacing')
        flag = (obj.NumTransmitAntennas == 1);
    elseif strcmp(prop, 'ReceiveAntennaSpacing')
        flag = (obj.NumReceiveAntennas == 1);
    else
        flag = isInactivePropertyImpl@wlan.internal.ChannelBase(obj, prop);
    end
  end 
end

methods(Static, Access = protected)
  function groups = getPropertyGroupsImpl
    multipath = matlab.system.display.Section( ...
        'PropertyList',{'SampleRate','DelayProfile','CarrierFrequency', ...
        'EnvironmentalSpeed','TransmitReceiveDistance','NormalizePathGains'});
    
    antenna = matlab.system.display.Section(...
        'PropertyList',{'NumTransmitAntennas','TransmitAntennaSpacing', ...
        'NumReceiveAntennas','ReceiveAntennaSpacing'}); 
    
    pathloss = matlab.system.display.Section(...
        'PropertyList',{'LargeScaleFadingEffect', ...
        'FluorescentEffect','PowerLineFrequency'}); 
    
    pRandStream = matlab.system.display.internal.Property( ...
        'RandomStream','IsGraphical', false,'UseClassDefault', false, ...
        'Default','mt19937ar with seed');
    
    randomization = matlab.system.display.Section(...
        'PropertyList',{pRandStream,'Seed','PathGainsOutputPort'});
    
    normalization = matlab.system.display.Section(...
        'PropertyList',{'NormalizeChannelOutputs'});
    
    pChannelFiltering = matlab.system.display.internal.Property(...
        'ChannelFiltering', ...
        'IsGraphical',false, ...
        'UseClassDefault',true);
    
    channelFiltering = matlab.system.display.Section(...
        'PropertyList',{pChannelFiltering,'NumSamples','OutputDataType'});
    
    mainGroup = matlab.system.display.SectionGroup(...
        'TitleSource', 'Auto', ...
        'Sections', [multipath antenna pathloss normalization channelFiltering]);
    
    realizationGroup = matlab.system.display.SectionGroup(...
        'Title', 'Realization', ...
        'Sections', randomization);
    
    groups = [mainGroup realizationGroup];
   
  end
end
end
