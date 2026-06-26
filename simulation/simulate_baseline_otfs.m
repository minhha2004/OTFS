% Evaluation role: conventional OTFS baseline for Chapter 5. This isolates
% the benefit of OTFS modulation before adding Index Modulation and OHD
% activation-pattern selection.
function result = simulate_baseline_otfs(cfg)
% Runs the baseline OTFS Monte Carlo BER simulation using the existing
% OTFS channel, modulation, demodulation, and MP detector functions.

err_otfs = zeros(length(cfg.EbN0_dB), 1);
frames_used = zeros(length(cfg.EbN0_dB), 1);

for iesn0 = 1:length(cfg.EbN0_dB)
    target_frames = get_target_frames(cfg);

    for ifram = 1:target_frames
        bits = randi([0,1], cfg.total_bits_otfs, 1);
        x = qammod(bi2de(reshape(bits, cfg.N_total, cfg.M_bits_otfs)), cfg.M_mod_otfs);
        [t, d, Dop, c] = OTFS_channel_gen(cfg.N, cfg.M);
        s = OTFS_modulation(cfg.N, cfg.M, reshape(x, cfg.N, cfg.M));
        r = OTFS_channel_output(cfg.N, cfg.M, t, d, Dop, c, cfg.sigma_2_otfs(iesn0), s);
        y = OTFS_demodulation(cfg.N, cfg.M, r);
        x_est = OTFS_mp_detector(cfg.N, cfg.M, cfg.M_mod_otfs, t, d, Dop, c, cfg.sigma_2_otfs(iesn0), y);
        bits_est = reshape(de2bi(qamdemod(x_est, cfg.M_mod_otfs), cfg.M_bits_otfs), [], 1);
        err_otfs(iesn0) = sum(xor(bits, bits_est)) + err_otfs(iesn0);
        frames_used(iesn0) = ifram;

        if should_stop_adaptive(cfg, ifram, err_otfs(iesn0))
            break;
        end
    end
end

result.err_otfs = err_otfs;
result.frames_used = frames_used;
result.ber_otfs = err_otfs ./ (cfg.total_bits_otfs * frames_used);
end

function target_frames = get_target_frames(cfg)
if isfield(cfg, 'use_adaptive_frames') && cfg.use_adaptive_frames
    target_frames = cfg.max_frames_per_snr;
else
    target_frames = cfg.N_fram;
end
end

function tf = should_stop_adaptive(cfg, frames_done, error_count)
tf = false;
if ~isfield(cfg, 'use_adaptive_frames') || ~cfg.use_adaptive_frames
    return;
end

tf = frames_done >= cfg.min_frames_per_snr && error_count >= cfg.target_bit_errors;
end
