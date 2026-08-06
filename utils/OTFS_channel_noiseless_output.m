function r = OTFS_channel_noiseless_output(N, M, taps, delay_taps, ...
    Doppler_taps, chan_coef, s)
% OTFS_CHANNEL_NOISELESS_OUTPUT truyền tín hiệu thử qua kênh nhưng không có AWGN.
% Hàm này dùng trong refinement để dựng lại tín hiệu nhận của một pattern thử.
% Các bước thêm CP, áp dụng delay-Doppler và bỏ CP giống hệt kênh chính.

L = max(delay_taps);
s_cp = [s(N*M-L+1:N*M); s];
s_chan = zeros(length(s_cp) + delay_taps(end), 1);
for itap = 1:taps
    phase = exp(1j*2*pi/M * (-L:-L+length(s_cp)-1) ...
        * Doppler_taps(itap)/N).';
    delayed = [s_cp .* phase; zeros(delay_taps(end), 1)];
    s_chan = s_chan + chan_coef(itap) ...
        * circshift(delayed, delay_taps(itap));
end
r = s_chan(L+1:L+N*M);
end
