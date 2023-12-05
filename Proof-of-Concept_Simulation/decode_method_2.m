function dd = decode_method_2(Xd1, Rd1, Xd2, Rd2, H3)

    d1 = norm(Xd1 - Rd1);   % 1,  1
    d2 = norm(H3*Xd1-Rd1);  %-1,  1
    d3 = norm(-H3*Xd1 - Rd1);   %1, -1
    d4 = norm(-Xd1-Rd1);    %-1, -1
    [minV1, minId1] = min([d1, d2, d3, d4]);
    
    d5 = norm(Xd2 - Rd2);   % 1,  1
    d6 = norm(H3*Xd2-Rd2);  %-1,  1
    d7 = norm(-H3*Xd2 - Rd2);   %1, -1
    d8 = norm(-Xd2-Rd2);    %-1, -1
    [minV2, minId2] = min([d5, d6, d7, d8]);
    
    if minId1 == 1 && minId2 == 2
        dd = [1, 1];
    elseif minId1 == 2 && minId2 == 4
        dd = [0, 1];
    elseif minId1 == 3 && minId2 == 1
        dd = [1, 0];        
    elseif minId1 == 4 && minId2 == 3
        dd = [0, 0];
    else
        dd = [2, 2]; % default
    end
end