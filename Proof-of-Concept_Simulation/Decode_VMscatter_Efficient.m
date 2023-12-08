function rx_code = Decode_VMscatter_Efficient(tx1, rx1, tx2, rx2, CH)

rx_code_1 = diag(CH * rx1 / tx1 / CH);
rx_code_2 = diag(CH * rx2 / tx2 / CH);

rx_code = [rx_code_1.'; rx_code_2.'];

end
