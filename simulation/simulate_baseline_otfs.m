function result = simulate_baseline_otfs(cfg)
% SIMULATE_BASELINE_OTFS mô phỏng hệ OTFS-QPSK gốc để làm đường chuẩn.
% Trong mỗi frame:
% Bước 1: Sinh bit ngẫu nhiên và điều chế QPSK cho toàn bộ 120 ô.
% Bước 2: Sinh kênh, điều chế OTFS, truyền qua kênh và giải điều chế OTFS.
% Bước 3: Dùng MP để ước lượng QPSK tại mỗi ô.
% Bước 4: Đổi symbol về bit, đếm lỗi và tính BER tổng.

err_otfs = zeros(length(cfg.EbN0_dB), 1);
frames_used = zeros(length(cfg.EbN0_dB), 1);

for iesn0 = 1:length(cfg.EbN0_dB)
    for ifram = 1:cfg.N_fram
        bits = randi([0,1], cfg.total_bits_otfs, 1);
        data_alphabet = qammod(0:cfg.M_mod_otfs-1, cfg.M_mod_otfs);
        symbol_prior = ones(1, cfg.M_mod_otfs) / cfg.M_mod_otfs;
        x = qammod(bi2de(reshape(bits, cfg.N_grid, cfg.M_bits_otfs)), cfg.M_mod_otfs);
        [t, d, Dop, c] = OTFS_channel_gen(cfg.N, cfg.M);
        s = OTFS_modulation(cfg.N, cfg.M, reshape(x, cfg.N, cfg.M));
        r = OTFS_channel_output(cfg.N, cfg.M, t, d, Dop, c, cfg.sigma_2_otfs(iesn0), s);
        y = OTFS_demodulation(cfg.N, cfg.M, r);
        x_est = OTFS_mp_detector(cfg.N, cfg.M, data_alphabet, symbol_prior, ...
            t, d, Dop, c, cfg.sigma_2_otfs(iesn0), y, cfg);
        bits_est = reshape(de2bi(qamdemod(x_est, cfg.M_mod_otfs), cfg.M_bits_otfs), [], 1);
        err_otfs(iesn0) = sum(xor(bits, bits_est)) + err_otfs(iesn0);
        frames_used(iesn0) = ifram;

    end
end

result.err_otfs = err_otfs;
result.frames_used = frames_used;
result.ber_otfs = err_otfs ./ (cfg.total_bits_otfs * frames_used);
result.ber_symbol = result.ber_otfs;
result.ber_total = result.ber_otfs;
end
