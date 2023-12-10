function [rx_vmsx, txTagData] = VMscatterMod(rx, ind, NumTX, NumTag, NumRX, cfgHT)

KK = NumTag;
while mod(KK, 2) == 0
    KK = KK / 2;
end
if KK ~= 1
    error('The number of tag antennas is not a power of 2.');
end

mcsTable   = wlan.internal.getRateTable(cfgHT);
numSS      = mcsTable.Nss;

if NumTag > numSS
    error(['This code only demonstrates VMscatter under the condition of ' ...
           'full-rank encoding, hence the number of tag antennas must not ' ...
           'exceed the number of spatial streams.']);
end

code_ref = VMscatterRef(NumTag);

txTagData = dec2bin(randi([0, 2^NumTag-1]),NumTag) - '0';

code_data = iterativeSTC(txTagData);

code_mod = [code_ref, code_data];

rx_vmsx = rx.';

numSym = size(code_mod,2);

for ii = 1:1:numSym
    ref_start = ind.HTData(1,1) + +80*(ii-1);
    ref_end = ind.HTData(1,1)+80*ii-1;
    rx_vmsx(:, ref_start:ref_end) = diag(code_mod(:,ii))*rx_vmsx(:, ref_start:ref_end);
end

rx_vmsx = rx_vmsx.';

end