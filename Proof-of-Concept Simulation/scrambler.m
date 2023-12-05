function scrData = scrambler(data)
   N = 2;
   scramblerPoly = comm.Scrambler(N,'1 + z^-4 + z^-7', ...
    [1 0 1 1 1 0 1]);
   scrData = scramblerPoly(data.');
    
end