function CH_VMscatter_Efficient = CHest_VMscatter_Accurate(tx_wifi_reference, rx_wifi_reference)

H1 = rx_wifi_reference / tx_wifi_reference;

% We know that
% H1 = H0 \ CH_Post_Tag * diag(tx_tag_reference) * CH_Pre_Tag
% = Inv(CH_Pre_Tag) *  diag(tx_tag_reference) * CH_Pre_Tag
% We assume that
% CH_Pre_Tag = [a1, a2; ...
%               a3, a4];
% Inv(CH_Pre_Tag) = [b1, b2; ...
%                    b3, b4];
% H1 = [c1, c2; c3, c4];
% diag(tx_tag_reference) * CH_Pre_Tag = [-a1, -a2; a3, a4];
% H1 = [b1, b2] * [-a1, -a2]  
%      [b3, b4]   [ a3,  a4]
% c1 = -b1a1+b2a3
% c2 = -b1a2+b2a4
% c3 = -b3a1+b4a3
% c4 = -b3a2+b4a4
% Also,
% 1 = b1a1+b2a3
% 0 = b1a2+b2a4
% 0 = b3a1+b4a3
% 1 = b3a2+b4a4
% The CH_Pre_Tag has an infinite number of solutions
% It is sufficient to calculate each term such as b1a1, b2a3, and so on.

% The total number of term is 2x2 (TX) + 2x2 (RX) = 8
CH_VMscatter_Efficient = zeros(2,4);

referenceMatrix = [1,1;-1,1];  % all 0 sequence + reference signal

V = diag(ones(1,2)); % Inv(CH_Pre_Tag) *  diag([1,1]) * CH_Pre_Tag


for ii = 1:1:2
    for jj = 1:1:2
            H = [V(ii,jj);H1(ii,jj)];
            CH_VMscatter_Efficient(:, jj+2*(ii-1)) = referenceMatrix \ H;
    end
end


end