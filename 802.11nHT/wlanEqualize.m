function [y, CSI] = wlanEqualize(x, chanEst, eqMethod, varargin)
%wlanEqualize Perform MIMO channel equalization. 
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y, CSI] = wlanEqualize(X, CHANEST, 'ZF') performs equalization using
%   the signal input X and the channel estimation input CHANEST, and
%   returns the estimation of transmitted signal in Y and the soft channel
%   state information in CSI. The zero-forcing (ZF) method is used. The
%   inputs X and CHANEST can be double precision 2-D matrices or 3-D arrays
%   with real or complex values. X is of size Nsd x Nsym x Nr, where Nsd
%   represents the number of data subcarriers (frequency domain), Nsym
%   represents the number of OFDM symbols (time domain), and Nr represents
%   the number of receive antennas (spatial domain). CHANEST is of size Nsd
%   x Nsts x Nr, where Nsts represents the number of space-time streams.
%   The double precision output Y is of size Nsd x Nsym x Nsts. Y is
%   complex when either X or CHANEST is complex and is real otherwise. The
%   double precision, real output CSI is of size Nsd x Nsts.
%
%   [Y, CSI] = wlanEqualize(X, CHANEST, 'MMSE', NOISEVAR) performs the
%   equalization using the minimum-mean-square-error (MMSE) method. The
%   noise variance input NOISEVAR is a double precision, real, nonnegative
%   scalar.
%
%   See also wlanSTBCCombine.

%   Copyright 2015-2022 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

% Input validation
narginchk(3, 4);

validateattributes(x, {'double'}, {'3d','finite','nonempty'}, ...
    'wlanEqualize:InSignal', 'signal input');
validateattributes(chanEst, {'double'}, {'3d','finite','nonempty'}, ...
    'wlanEqualize:ChanEst', 'channel estimation input');   
coder.internal.errorIf(~strcmp(eqMethod, 'ZF') && ~strcmp(eqMethod, 'MMSE'), ...
    'wlan:wlanEqualize:InvalidEqMethod');
coder.internal.errorIf(size(x, 1) ~= size(chanEst, 1), ...
    'wlan:wlanEqualize:UnequalFreqCarriers');
coder.internal.errorIf(size(x, 3) ~= size(chanEst, 3), ...
    'wlan:wlanEqualize:UnequalNumRx');

if strcmp(eqMethod, 'MMSE')
    narginchk(4,4);
    validateattributes(varargin{1}, {'double'}, {'real','scalar','nonnegative','finite','nonempty'}, ...
        'wlanEqualizer:noiseVarEst', 'noise variance estimation input'); 
    noiseVarEst = varargin{1};
else % ZF
    noiseVarEst = 0;
end

% Perform equalization
[numSc, numTx, numRx] = size(chanEst);

CSI = zeros(size(x, 1), numTx); % Pre-allocation here for code generation
if (numTx == 1 && numRx == 1) % SISO
    chanEstSISO = chanEst(:, 1, 1); % For codegen
    CSI = real(chanEstSISO.*conj(chanEstSISO)) + noiseVarEst;
    y =  x(:, :, 1) .* conj(chanEstSISO) ./ CSI;
elseif (numTx == 1 && numRx > 1) % SIMO
    chanEstSIMO = chanEst(:, 1, :); % For codegen
    chanEst2D = reshape(chanEstSIMO, size(chanEst, 1), numRx);    
    CSI = real(diag(chanEst2D*chanEst2D')) + noiseVarEst;
    y = sum(x .* conj(chanEstSIMO), 3) ./ CSI;
elseif (numTx > 1 && numRx == 1) % MISO
    chanEstMISO = chanEst(:, :, 1); % For codegen
    chanPower = real(chanEstMISO.*conj(chanEstMISO));
    if strcmp(eqMethod, 'ZF')
        CSI = chanPower; 
    else % Use Schur complement formula
        CSI = noiseVarEst + noiseVarEst*chanPower ./ ...
            (sum(chanPower, 2) - chanPower + noiseVarEst);
    end
    chanEstInv = conj(chanEstMISO) ./ (sum(chanPower, 2) + noiseVarEst);
    chanEstInvPermute = permute(chanEstInv, [1 3 2]);
    y = x(:, :, 1) .* chanEstInvPermute; % Indexing for codegen
elseif (numTx > numRx) && strcmp(eqMethod, 'ZF') % MIMO: singular channel matrix using ZF
    numSym = size(x, 2);
    CSI = sum(real(chanEst .* conj(chanEst)), 3);
    xTmp = permute(x, [2 3 1]); % numSym-by-numRx-by-numSc
    chanEstTmp = permute(chanEst,[2 3 1]); % numTx-by-numRx-by-numSc
    y = coder.nullcopy(complex(zeros(numSc, numSym, numTx)));
    for idx = 1:numSc
        y(idx, 1:numSym, 1:numTx) = xTmp(:, :, idx) * pinv(chanEstTmp(:, :, idx)); 
    end
else % MIMO: numTx > numRx using MMSE or numTx <= numRx
    numSym = size(x, 2);
    xTmp = permute(x, [2 3 1]); % numSym-by-numRx-by-numSc
    chanEstTmp = permute(chanEst,[2 3 1]); % numTx-by-numRx-by-numSc
    y = coder.nullcopy(complex(zeros(numSc, numSym, numTx)));
    for idx = 1:numSc
        H = chanEstTmp(:,:,idx);
        invH = inv(H*H'+noiseVarEst*eye(numTx));
        CSI(idx, :)  = 1./real(diag(invH));
        y(idx, 1:numSym, 1:numTx) = xTmp(:, :, idx) * H' * invH; %#ok<MINV>
    end
end
