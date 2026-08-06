%% OTFS channel output
function r = OTFS_channel_output(N,M,taps,delay_taps,Doppler_taps,chan_coef,sigma_2,s)
% OTFS_CHANNEL_OUTPUT truyền tín hiệu OTFS qua kênh và nhiễu AWGN.
% Bước 1: Thêm cyclic prefix có chiều dài bằng độ trễ lớn nhất.
% Bước 2: Áp dụng độ trễ, Doppler và hệ số của từng path rồi cộng lại.
% Bước 3: Cộng nhiễu Gaussian phức với phương sai sigma_2.
% Bước 4: Bỏ cyclic prefix và trả về tín hiệu thời gian thu được r.
%% Kênh vô tuyến và nhiễu
L = max(delay_taps);
s = [s(N*M-L+1:N*M);s];%add one cp
s_chan = 0;
for itao = 1:taps
    s_chan = s_chan+chan_coef(itao)*circshift([s.*exp(1j*2*pi/M ...
        *(-L:-L+length(s)-1)*Doppler_taps(itao)/N).';zeros(delay_taps(end),1)],delay_taps(itao));
end
noise = sqrt(sigma_2/2)*(randn(size(s_chan)) + 1i*randn(size(s_chan)));
r = s_chan + noise;
r = r(L+1:L+(N*M));%discard cp
end
