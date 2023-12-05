close all;
clear;
clc;

modulation = 64;

% 2X2 MIMO
CH_Pre_Tag = complex(randn(2),randn(2)); %[ha1, ha2; hb1, hb2]
CH_Post_Tag = complex(randn(2),randn(2)); %[h1a, h1b; h2a, h2b]


%% Preamble Training

bd3 = [-1, 1]; % reference data [1, 1]
ts3 = WiFiData(2, modulation); % WiFi transmitted subcarrier
rs3 = rxSubcarrier(ts3, bd3, CH_Pre_Tag, CH_Post_Tag);
H3 = rs3/ts3; % == inv(CH_Pre_Tag)*diag(bd)*CH_Pre_Tag


%% Transmission
for loop = 1:1:1000
    for n = 0:1:3 % 2X2 MIMO has 4 kinds of data combination 
        bd = dec2bin(n,2) - '0'; % backscatter data
        [cd1, cd2] = code(bd); % coded data
        Xd1 = WiFiData(2, modulation); %Incoming Symbol 1
        Rd1 = rxSubcarrier(Xd1, cd1, CH_Pre_Tag, CH_Post_Tag); % Received Symbol 1
        Xd2 = WiFiData(2, modulation); %Incoming Symbol 2
        Rd2 = rxSubcarrier(Xd2, cd2, CH_Pre_Tag, CH_Post_Tag); % Received Symbol 2

        dd_1 = decode_method_1(Xd1, Rd1, Xd2, Rd2, H3); % decoded backscatter data using mehtod 1
%         dd_2 = decode_method_2(Xd1, Rd1, Xd2, Rd2, H3); % decoded backscatter data using mehtod 1

        [number_1,ratio_1] = biterr(bd, dd_1);
        disp(['BER with Method 1:' num2str(ratio_1)]);
        if ratio_1 ~= 0
            return
        end

%         [number_2,ratio_2] = biterr(bd, dd_2);
%         disp(['BER with Method 2:' num2str(ratio_2)]);
%         if ratio_2 ~= 0
%             return
%         end

    end
end
