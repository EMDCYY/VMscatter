function [d1,d2] = code(a)
    b = 2*a -1;
    b1 = b(1);
    b2 = b(2);
    d1 = b;
    d2 = [-conj(b2), conj(b1)];
end