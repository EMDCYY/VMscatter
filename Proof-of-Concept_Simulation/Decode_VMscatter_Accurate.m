function rx_code = Decode_VMscatter_Accurate(tx1, rx1, tx2, rx2, CH)

% Use lsqlin to estimate the tag data
% min‖C⋅x−d‖


CH = CH.';
CH1_all = (reshape((rx1 / tx1).', 1, [])).';
CH2_all = (reshape((rx2 / tx2).', 1, [])).';


% We are using BPSK, where the tag data are 1 and -1. 
% Therefore, when multiplied by a complex number channel， 
% it results in the addition of real parts to real parts, 
% and imaginary parts to imaginary parts, 
% without any mixing of real and imaginary components. 
% Consequently, we can separate the real and imaginary parts for decoding. 
% This will further reduce the Bit Error Rate (BER).
% This method is also applicable to QPSK


C = [real(CH);imag(CH)];
d1 = [real(CH1_all);imag(CH1_all)];
d2 = [real(CH2_all);imag(CH2_all)];
A =[];
b = [];
Aeq = [];
beq = [];
lb = -ones(2,1);
ub = ones(2,1);
x0 = [-1, -1];

options = optimoptions('lsqlin', 'Display', 'off');
rx_code_1 = lsqlin(C,d1,A,b,Aeq,beq,lb,ub, x0, options);
rx_code_2 = lsqlin(C,d2,A,b,Aeq,beq,lb,ub, x0, options);

rx_code = [rx_code_1.'; rx_code_2.'];

end
