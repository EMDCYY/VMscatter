function y = wlanOFDMModulate(x,cplen,varargin)
%wlanOFDMModulate Perform OFDM modulation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = wlanOFDMModulate(X, CPLEN) performs OFDM modulation on the
%   frequency-domain input signal X and outputs the time-domain signal Y.
% 
%   X is the Nc-by-Nsym-by-Nt frequency-domain signal, where Nc represents
%   the number of frequency subcarriers, Nsym represents the number of OFDM
%   symbols, and Nt represents the number of antennas in the
%   spatial-domain.
% 
%   CPLEN is either:
%    * A non-negative, integer scalar representing the cyclic prefix
%      length for all OFDM symbols.
%    * A column vector of length Nsym containing non-negative integers.
%      Each element represents the cyclic prefix length for an OFDM symbol.
%      symbol.
%
%   Y is the modulated time-domain signal.
%
%   Y = wlanOFDMModulate(X, CPLEN, OSF) performs OFDM modulation given an
%   oversampling factor OSF. OSF must >=1 and result in an integer number
%   of cyclic prefix samples and an even FFT length.

%   Copyright 2015-2021 The MathWorks, Inc.

%#codegen

[fftLen,numSym,numTx] = size(x);

if nargin>2
    osf = varargin{1};
    if osf>1
        wlan.internal.validateOFDMOSF(osf,fftLen,cplen);
        numSamples = (osf-1)*fftLen/2;        
        padding = zeros(numSamples,numSym,numTx,'like',x);
        x = [padding; x*osf; padding]; % Scale by OSF to account for larger FFT
        cplen = cplen*osf;
        fftLen = fftLen*osf;
    end
end

% OFDM modulate
prmStr = struct;
prmStr.NumSymbols = numSym;
prmStr.NumTransmitAntennas = numTx;
prmStr.FFTLength = fftLen;
prmStr.CyclicPrefixLength = cplen;
% y = comm.internal.ofdm.modulate(x,prmStr);
y = ofdmModulate(x,prmStr);



end