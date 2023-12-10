function code = iterativeSTC(a)
    K = length(a);
    if K == 2
        b = 2*a -1;
        b1 = b(1);
        b2 = b(2);
        code1 = b;
        code2 = [-conj(b2), conj(b1)];
        code = [code1.',code2.'];
    else
        codeTop = iterativeSTC(a(1:K/2));
        codeBottom = iterativeSTC(a(K/2 + 1:end));
        
        code = [codeTop, -conj(codeBottom)
                codeBottom,  conj(codeTop)];
    end

end
