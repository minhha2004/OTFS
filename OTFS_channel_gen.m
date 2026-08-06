% Delay-Doppler channel generator shared by OTFS and OTFS-IM.
%
% Copyright (c) 2018, Raviteja Patchava, Yi Hong, and Emanuele Viterbo, Monash University
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
%% OTFS channel generator
function [taps,delay_taps,Doppler_taps,chan_coef] = OTFS_channel_gen(~,~)
% OTFS_CHANNEL_GEN tạo một kênh delay-Doppler thưa ngẫu nhiên.
% Đầu ra gồm số path, độ trễ, Doppler và hệ số kênh phức của từng path.
% Bước 1: Dùng ba path với các độ trễ cố định [0 1 2].
% Bước 2: Sinh ngẫu nhiên chỉ số Doppler cho từng path.
% Bước 3: Sinh hệ số fading Rayleigh với công suất giảm theo độ trễ.
%% Kênh dùng trong mô phỏng
taps = 3;
%delay_taps = [0 1];
%Doppler_taps = [0 1 2 3];
% Sinh Doppler và hệ số kênh mới cho mỗi frame.
delay_taps = [0 1 2];
Doppler_taps = randi([1, 10], 1, taps)-5;
%pow_prof = (1/taps) * (ones(1,taps));
%chan_coef = sqrt(pow_prof).*(sqrt(1/2) * (randn(1,taps)+1i*randn(1,taps)));
chan_coef = sqrt(exp(-delay_taps)/2).*(randn(1,taps)+1i*randn(1,taps));

end
