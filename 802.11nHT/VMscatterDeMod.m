function rxTagData = VMscatterDeMod(txSC, rxSC, NumTX, NumTag, NumRX, cfgHT)

% We know that
% H1 = H0 \ CH_Post_Tag * diag(tx_tag_reference) * CH_Pre_Tag
% = Inv(CH_Pre_Tag) *  diag(tx_tag_reference) * CH_Pre_Tag
% We assume that
% CH_Pre_Tag = [a1, a2; ...
%               a3, a4];
% Inv(CH_Pre_Tag) = [b1, b2; ...
%                    b3, b4];
% H1 = [c1, c2; c3, c4];
% diag(tx_tag_reference) * CH_Pre_Tag = [-a1, -a2; a3, a4];
% H1 = [b1, b2] * [-a1, -a2]  
%      [b3, b4]   [ a3,  a4]
% c1 = -b1a1+b2a3
% c2 = -b1a2+b2a4
% c3 = -b3a1+b4a3
% c4 = -b3a2+b4a4
% Also,
% 1 = b1a1+b2a3
% 0 = b1a2+b2a4
% 0 = b3a1+b4a3
% 1 = b3a2+b4a4
% The CH_Pre_Tag has an infinite number of solutions
% It is sufficient to calculate each term such as b1a1, b2a3, and so on.
% If it's necessary to compute CH_Pre_Tag
% you can pick up one solution from the infinite solutions
% c1 - 1 = -2 * b1a1
% c2 = -2 * b1a2
% c3 - 1 = -2 * b3a1
% c4 = -2 * b3a2
% for example, set a1 = 1 and a3 = 1.

txSC = permute(txSC, [3, 1, 2]);
rxSC = permute(rxSC, [3, 1, 2]);

mcsTable   = wlan.internal.getRateTable(cfgHT);
numSS      = mcsTable.Nss;

if NumTag <= numSS 
    code_rank = 2^floor(log2(NumTag));
else
    code_rank = 2^floor(log2(numSS));
end

CH_Post_Tag_Est  = CHest_VMscatter_Efficient(txSC, rxSC, NumTag, cfgHT);






rx_code_efficient = Decode_VMscatter_Efficient(tx_wifi_symbol_1, rx_wifi_symbol_1, ...
                                tx_wifi_symbol_2, rx_wifi_symbol_2, CH_Post_Tag_Est); 
rxTagData = SpaceTimeDecode(rx_code_efficient);

end