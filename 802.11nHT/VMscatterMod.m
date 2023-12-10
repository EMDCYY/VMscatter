function [rx_vmsx, txTagData] = VMscatterMod(rx, ind, NumTag, cfgHT)

mcsTable   = wlan.internal.getRateTable(cfgHT);
numSS      = mcsTable.Nss;

if NumTag <= numSS 
    code_rank = 2^floor(log2(NumTag));
else
    code_rank = 2^floor(log2(numSS));
end


code_ref = VMscatterRef(code_rank);

txTagData = dec2bin(randi([0, 2^code_rank-1]),code_rank) - '0';

code_data = iterativeSTC(txTagData);

code_mod = [code_ref, code_data];

if NumTag > numSS
    multiple = floor(NumTag / numSS);
    if multiple >= 2
        code_mod_extended = repmat(code_mod, 1, multiple);
        code_mod = reshape(code_mod_extended.', size(code_mod,2), []).';
    end
end

% disp(code_mod);

rx_vmsx = rx.';

numSym = size(code_mod,2);

for ii = 1:1:numSym
    ref_start = ind.HTData(1,1) + +80*(ii-1);
    ref_end = ind.HTData(1,1)+80*ii-1;
    rx_vmsx(:, ref_start:ref_end) = diag(code_mod(:,ii))*rx_vmsx(:, ref_start:ref_end);
end

rx_vmsx = rx_vmsx.';

end