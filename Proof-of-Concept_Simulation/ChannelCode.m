function qamValue = ChannelCode(bit, modulation)

codedbit = [];
for nrow = 1:1:size(bit,1)
    bit_scramble = scrambler(bit(nrow,:));
    bit_convolution = convolution(bit_scramble);
    codedbit = [codedbit; bit_convolution.'];
end

% QAM constellation, complex value, WiFi baseband in frequency domain
qamValue = QAM(codedbit, modulation);

end