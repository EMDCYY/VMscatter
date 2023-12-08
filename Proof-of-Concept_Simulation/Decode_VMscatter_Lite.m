function rx_tag_data = Decode_VMscatter_Lite(tx1, rx1, tx2, rx2, CH)

    d1 = norm(tx1 - rx1);   % 1,  1
    d2 = norm(CH*tx1-rx1);  %-1,  1
    d3 = norm(-CH*tx1 - rx1);   %1, -1
    d4 = norm(-tx1-rx1);    %-1, -1
    [minV1, minId1] = min([d1, d2, d3, d4]);
    
    d5 = norm(tx2 - rx2);   % 1,  1
    d6 = norm(CH*tx2-rx2);  %-1,  1
    d7 = norm(-CH*tx2 - rx2);   %1, -1
    d8 = norm(-tx2-rx2);    %-1, -1
    [minV2, minId2] = min([d5, d6, d7, d8]);
    
    if minId1 == 1 && minId2 == 2
        rx_tag_data = [1, 1];
    elseif minId1 == 2 && minId2 == 4
        rx_tag_data = [0, 1];
    elseif minId1 == 3 && minId2 == 1
        rx_tag_data = [1, 0];        
    elseif minId1 == 4 && minId2 == 3
        rx_tag_data = [0, 0];
    else
        rx_tag_data = [2, 2]; % default
    end
end

