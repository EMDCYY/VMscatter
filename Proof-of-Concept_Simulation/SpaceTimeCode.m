function code = SpaceTimeCode(a)
        b = 2*a -1;
        b1 = b(1);
        b2 = b(2);
        code1 = b;
        code2 = [-conj(b2), conj(b1)];
        code = [code1.',code2.'];
end