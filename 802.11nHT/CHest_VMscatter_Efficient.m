function CH_Pre_Tag_Est = CHest_VMscatter_Efficient(txSC, rxSC, NumTag, cfgHT)

mcsTable   = wlan.internal.getRateTable(cfgHT);
numSS      = mcsTable.Nss;

if NumTag <= numSS 
    code_rank = 2^floor(log2(NumTag));
else
    code_rank = 2^floor(log2(numSS));
end

txSC = txSC(:,:,1:code_rank-1);
rxSC = rxSC(:,:,1:code_rank-1);

H1 = zeros(code_rank, code_rank, code_rank-1);

for ii = 1:1:code_rank-1
    H1(:,:,ii) = rxSC(:,:,ii) / txSC(:,:,ii);
end

%% Example for 2x2x2
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
% If it's necessary to compute CH_Pre_Tag
% you can pick up one solution from the infinite solutions
% c1 - 1 = -2 * b1a1
% c2 = -2 * b1a2
% c3 - 1 = -2 * b3a1
% c4 = -2 * b3a2
% for example, set a1 = 1 and a3 = 1.

% V = diag(ones(1,2)); % Inv(CH_Pre_Tag) *  diag([1,1]) * CH_Pre_Tag

% Pick up the first and 3rd line of Inv(CH_Pre_Tag) *  diag * CH_Pre_Tag
% [1, c1] = [b1, b2] * [a1,-a1]
% [0, c3]   [b3, b4]   [a3, a3]
% set a1 = 1 and a3 = 1 
% [V(:,1), H1(:,1)] = Inv_CH_Pre_Tag * [1, -1; 1, 1];
% [1, -1; 1, 1] can be replaced by the reference matrix

% Inv_CH_Pre_Tag = [V(:,1), H1(:,1)] / [1, -1; 1, 1];
% 
% CH_Pre_Tag_Est = inv(Inv_CH_Pre_Tag);
%% 

refMatrix = [ones(code_rank,1), VMscatterRef(code_rank)];

CH = zeros(code_rank, code_rank);
V = diag(ones(1,code_rank));
CH(:,1) = V(:,1);

for kk = 1:size(H1,3)
    CH(:,kk+1) = H1(:,1,kk);
end

Inv_CH_Pre_Tag = CH / refMatrix;

CH_Pre_Tag_Est = inv(Inv_CH_Pre_Tag);


end