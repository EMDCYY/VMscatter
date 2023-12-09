function [rx_vmsx, txTagData] = VMscatterMod(rx, ind, NumTX, NumTag, NumRX)

code_rank = min(min(NumTX, NumTag), NumRX);

KK = code_rank ;
while mod(KK, 2) == 0
    KK = KK / 2;
end
if KK ~= 1
    error('The minimum number of antenna is not a power of 2.');
end

code_ref = VMscatterRef(code_rank);



rx_vmsx = rx;
txTagData= 0;

end