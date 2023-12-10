function yout = ofdmModulate(gridIn,prmStr)
% COMM.INTERNAL.OFDM.MODULATE OFDM modulation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = comm.internal.ofdm.modulate(GRIDIN,PRMSTR) performs OFDM modulation
%   on the input GRIDIN, using the parameters specified in the structure
%   PRMSTR, and returns the result in Y. GRIDIN is the fully populated
%   3D input accounting for all data, null and pilot subcarriers.
%
%   PRMSTR must have the following fields:
%       FFTLength
%       CyclicPrefixLength
%       NumSymbols
%       NumTransmitAntennas
%   PRMSTR may have the following optional field:
%       OversamplingFactor
%
%   See also comm.internal.ofdm.demodulate, ofdmdemod, ofdmmod.

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen

    fftLen = prmStr.FFTLength;
    cpLen  = prmStr.CyclicPrefixLength;
    numSym = prmStr.NumSymbols;
    numTx  = prmStr.NumTransmitAntennas;
    if (~isfield(prmStr,'OversamplingFactor'))
        osf = 1;
    else
        osf = prmStr.OversamplingFactor;
    end
    typeOut = cast(1i, 'like', gridIn);
    
    % Shift and IFFT
    zeroPaddedGrid = zeros(fftLen*osf,numSym,numTx,'like',typeOut);
    if isreal(gridIn)
        zeroPaddedGrid(ceil(fftLen*(osf-1)/2)+(1:fftLen),:,:) = complex(gridIn,0);
    else
        zeroPaddedGrid(ceil(fftLen*(osf-1)/2)+(1:fftLen),:,:) = gridIn;
    end
    postShift = ifftshift(zeroPaddedGrid,1);
    postIFFT = osf*ifft(postShift,[],1); 
        
    % Append cyclic prefix
    if isscalar(cpLen) % same length
        
        fftLenOSF = osf*fftLen;     % oversampled FFT length 
        cpLen1OSF = osf*cpLen(1);   % oversampled CP length (first CP entry)
        postCP = postIFFT([end-cpLen1OSF+(1:cpLen1OSF),1:end],:,:);
        yout = reshape(postCP,[(fftLenOSF+cpLen1OSF)*numSym numTx]);

    else % different lengths per symbol
        
       yout = coder.nullcopy( ...
           zeros(osf*(fftLen*numSym+sum(cpLen)),numTx,'like',typeOut));
        for symIdx = 1:numSym
            cpLenOSF = osf*cpLen(symIdx);
            % Use reshape instead of squeeze in case of CP length ==1
            yout(osf*(fftLen*(symIdx-1)+sum(cpLen(1:symIdx-1))) + ...
                 (1:osf*(fftLen+cpLen(symIdx))),:) = ...
                [reshape(postIFFT(end-cpLenOSF+(1:cpLenOSF), ...
                symIdx,:), [cpLenOSF numTx]); ...
                squeeze(postIFFT(:,symIdx,:))];
        end

    end

end

% [EOF]
