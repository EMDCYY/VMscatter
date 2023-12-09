function code = iterativeSTC(a)
    K = length(theta);
    if K == 2
        b = 2*a -1;
        b1 = b(1);
        b2 = b(2);
        code1 = b;
        code2 = [-conj(b2), conj(b1)];
        code = [code1;code2];
    else
        % 分割 theta 并递归调用
        GammaTop = iterativeSTC(theta(1:K/2));
        GammaBottom = iterativeSTC(theta(K/2 + 1:end));
        
        % 创建 K 天线的编码矩阵
        Gamma = [GammaTop, GammaBottom; ...
                 -conj(GammaBottom), conj(GammaTop)];
    end
end

