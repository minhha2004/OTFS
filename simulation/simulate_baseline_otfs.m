function result = simulate_baseline_otfs(cfg)
% Runs the baseline OTFS Monte Carlo BER simulation using the existing
% OTFS channel, modulation, demodulation, and MP detector functions.

err_otfs = zeros(length(cfg.EbN0_dB), 1);

for iesn0 = 1:length(cfg.EbN0_dB)
    for ifram = 1:cfg.N_fram
        bits = randi([0,1], cfg.total_bits_otfs, 1);
        x = qammod(bi2de(reshape(bits, cfg.N_total, cfg.M_bits_otfs)), cfg.M_mod_otfs);
        [t, d, Dop, c] = OTFS_channel_gen(cfg.N, cfg.M);
        s = OTFS_modulation(cfg.N, cfg.M, reshape(x, cfg.N, cfg.M));
        r = OTFS_channel_output(cfg.N, cfg.M, t, d, Dop, c, cfg.sigma_2_otfs(iesn0), s);
        y = OTFS_demodulation(cfg.N, cfg.M, r);
        x_est = OTFS_mp_detector(cfg.N, cfg.M, cfg.M_mod_otfs, t, d, Dop, c, cfg.sigma_2_otfs(iesn0), y);
        bits_est = reshape(de2bi(qamdemod(x_est, cfg.M_mod_otfs), cfg.M_bits_otfs), [], 1);
        err_otfs(iesn0) = sum(xor(bits, bits_est)) + err_otfs(iesn0);
    end
end

result.err_otfs = err_otfs;
result.ber_otfs = err_otfs / (cfg.total_bits_otfs * cfg.N_fram);
end
