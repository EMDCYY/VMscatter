function rx_tag_data = SpaceTimeDecode(rx_code, NumTag, cfgHT)

mcsTable   = wlan.internal.getRateTable(cfgHT);
numSS      = mcsTable.Nss;

if NumTag <= numSS 
    code_rank = 2^floor(log2(NumTag));
else
    code_rank = 2^floor(log2(numSS));
end

distance = zeros(2^code_rank,1);

for n = 1:1:2^code_rank 
        tag_data = dec2bin(n-1,code_rank) - '0'; % backscatter data
        tag_code = iterativeSTC(tag_data); % 
        distance(n) = norm(tag_code - rx_code);
end

[~, minInd] = min(distance);

rx_tag_data = dec2bin(minInd-1,code_rank) - '0';

end