function code_convolution = convolution(code_scramble)

    t = poly2trellis(7,[171 133]); 
    k = log2(t.numInputSymbols); 
    code_convolution = convenc(code_scramble,t); 
    
end

