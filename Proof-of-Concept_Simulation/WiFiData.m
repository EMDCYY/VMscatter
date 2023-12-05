function X_Freq=WiFiData(n, modulation)

k = log2(modulation);
tbit = randi([0 1],n,24*k);
tc = ChannelCode(tbit, modulation);

X_Freq =[zeros(n,6), tc(: , 1: 5), ones(n,1), tc(:, 6: 18), ...
    ones(n,1), tc(:, 19:24), zeros(n,1), tc(:, 25:30), ones(n,1), tc(:, 31:43), ...
    -ones(n,1), tc(:, 44:48), zeros(n,5)]; 

end