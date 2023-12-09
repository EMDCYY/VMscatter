close all;
clear;
clc;

modulation = 64;

% 2X2 MIMO
CH_Pre_Tag = complex(randn(2),randn(2)); %[ha1, ha2; hb1, hb2]
CH_Post_Tag = complex(randn(2),randn(2)); %[h1a, h1b; h2a, h2b]

%% Channel Estimation using WiFi Long Training Sequence (LTS)
% During LTS, the tag sends all 0 sequence
% The estimated channel can be obtained
H0 = CH_Post_Tag * CH_Pre_Tag;

%% VMscatter Channel Estimation 

% tranmistted symbol for backscatter reference signal
tx_wifi_reference = WiFiData(2, modulation); 
tx_tag_reference = [-1, 1]; % reference data

% recovered symbol
% Inv(A) * B = A \ B
rx_wifi_reference = H0 \ CH_Post_Tag * diag(tx_tag_reference) * CH_Pre_Tag * tx_wifi_reference; 

% For Lite VMscatter, there's no need to estimate the channel post tag. 
% Treat the channel between the rx and tx, including backscatter, as a single integrated channel.
CH_VMscatter_Lite = rx_wifi_reference / tx_wifi_reference;

% For Accurate VMscatter, estimate the element of the multiplication channel matrix
CH_VMscatter_Accurate = CHest_VMscatter_Accurate(tx_wifi_reference, rx_wifi_reference);
% Verfiry
% Hr = CH_Pre_Tag; Hi = inv(Hr);
% disp([Hi(1,1)*Hr(1,1), Hi(1,1)*Hr(1,2), Hi(2,1)*Hr(1,1), Hi(2,1)*Hr(1,2); ...
% Hi(1,2)*Hr(2,1), Hi(1,2)*Hr(2,2), Hi(2,2)*Hr(2,1), Hi(2,2)*Hr(2,2)]);
% disp(CH_VMscatter_Accurate);

% For Efficient VMscatter, estimate channel after tag
CH_Post_Tag_Est  = CHest_VMscatter_Efficient(tx_wifi_reference, rx_wifi_reference);
% Verfiry
% CH_Post_Tag_Est \ diag([-1,1]) * CH_Post_Tag_Est * tx_wifi_reference - rx_wifi_reference


%% Transmission
% In the proof-of-concept, we do not consider factors such as noise, delay, CFO, and others
% Solely aim to test that WiFi data does not affect the decoding of backscatter data.
for loop = 1:1:10000
        tx_tag_data = dec2bin(randi([0, 3]),2) - '0'; % backscatter data
        code = SpaceTimeCode(tx_tag_data); % space-time coding

        tx_wifi_symbol_1 = WiFiData(2, modulation); %Incoming Symbol 1
        rx_wifi_symbol_1 = H0 \ CH_Post_Tag * diag(code(:,1)) * CH_Pre_Tag * tx_wifi_symbol_1; % Received Symbol 1

        tx_wifi_symbol_2 = WiFiData(2, modulation); %Incoming Symbol 2
        rx_wifi_symbol_2 = H0 \ CH_Post_Tag * diag(code(:,2)) * CH_Pre_Tag * tx_wifi_symbol_2;% Received Symbol 2


        % Decoded backscatter data using Lite VMscatter
        rx_tag_data_lite = Decode_VMscatter_Lite(tx_wifi_symbol_1, rx_wifi_symbol_1, ...
                                tx_wifi_symbol_2, rx_wifi_symbol_2, CH_VMscatter_Lite); 


        [number_lite,ratio_lite] = biterr(tx_tag_data, rx_tag_data_lite);
        disp(['BER with Lite VMscatter:' num2str(ratio_lite)]);
        if ratio_lite ~= 0
            return
        end

        % Decoded backscatter data using Accurate VMscatter
        rx_code_accurate = Decode_VMscatter_Accurate(tx_wifi_symbol_1, rx_wifi_symbol_1, ...
                                tx_wifi_symbol_2, rx_wifi_symbol_2, CH_VMscatter_Accurate); 
        rx_tag_data_accurate = SpaceTimeDecode(rx_code_accurate);

        [number_accurate,ratio_accurate] = biterr(tx_tag_data, rx_tag_data_accurate);
        disp(['BER with Accurate VMscatter:' num2str(ratio_accurate)]);
        if ratio_accurate ~= 0
            return
        end

        % Decoded backscatter data using Efficient VMscatter
        rx_code_efficient = Decode_VMscatter_Efficient(tx_wifi_symbol_1, rx_wifi_symbol_1, ...
                                tx_wifi_symbol_2, rx_wifi_symbol_2, CH_Post_Tag_Est); 
        rx_tag_data_efficient = SpaceTimeDecode(rx_code_efficient);

        [number_efficient,ratio_efficient] = biterr(tx_tag_data, rx_tag_data_efficient);
        disp(['BER with Efficient VMscatter:' num2str(ratio_efficient)]);
        if ratio_efficient ~= 0
            return
        end

end
