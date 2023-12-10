function rxTagData = VMscatterDeMod(txSC, rxSC, NumTag, cfgHT)


txSC = permute(txSC, [3, 1, 2]);
rxSC = permute(rxSC, [3, 1, 2]);

%% Efficient Way 
CH_Pre_Tag_Est  = CHest_VMscatter_Efficient(txSC, rxSC, NumTag, cfgHT);
rx_code = Decode_VMscatter_Efficient(CH_Pre_Tag_Est, txSC, rxSC, NumTag, cfgHT); 
rxTagData = SpaceTimeDecode(rx_code, NumTag, cfgHT);

end