function rx_tag_data = SpaceTimeDecode(rx_code)


% Do not use round(rx_code) as it will increase BER 
% Must use maximum likelihood estimation instead

distance = zeros(4,1);

for n = 1:1:4 % 2X2 MIMO has 4 kinds of data combination 
        tag_data = dec2bin(n-1,2) - '0'; % backscatter data
        tag_code = SpaceTimeCode(tag_data); % 
        distance(n) = norm(tag_code - rx_code);
end

[~, minInd] = min(distance);

rx_tag_data = dec2bin(minInd-1,2) - '0';

end