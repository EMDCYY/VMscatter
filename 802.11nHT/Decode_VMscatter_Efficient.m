function rx_code = Decode_VMscatter_Efficient(CH_Pre_Tag_Est, txSC, rxSC, NumTag, cfgHT)

mcsTable   = wlan.internal.getRateTable(cfgHT);
numSS      = mcsTable.Nss;

if NumTag <= numSS 
    code_rank = 2^floor(log2(NumTag));
else
    code_rank = 2^floor(log2(numSS));
end

rx_code = zeros(code_rank, code_rank);

for ii = 1:1:code_rank
    rx = rxSC(:,:, code_rank-1+ii);
    tx = txSC(:,:, code_rank-1+ii);
    rx_code(:,ii) = diag(CH_Pre_Tag_Est * rx / tx / CH_Pre_Tag_Est);
end

end