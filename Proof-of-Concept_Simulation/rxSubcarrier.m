function rs = rxSubcarrier(ts, bd, Hpr, Hpo)

% If the backscatter reflects the symbol with only one angle on an antenna,
% i.e., symbol level modulation,
% we don't need to put the FFT or IFFT matrix into the model.
% Because the multiple subcarriers work as if a signle subcarrier works in MIMO. 
rs = Hpo*Hpr\Hpo*diag(bd)*Hpr*ts;

end