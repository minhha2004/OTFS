% Evaluation role: main thesis experiment runner. It compares OFDM, OTFS,
% OHD-selected OTFS-IM, Balanced-OHD, and random-pattern diagnostics so
% Chapter 5 can analyze BER, index reliability, pattern errors, and SE fairness.
% Run this once per selected (n,k). After saving 2-3 configurations, use
% plot_se_ber_tradeoff_from_results to generate the final BER-SE trade-off figure.
clc; clear; close all; tic;
addpath(genpath(fileparts(mfilename('fullpath'))));

cfg = config_otfs_im();
rng(cfg.rng_seed);

[MAP_TABLE, pattern_info] = select_patterns_ohd(cfg);
print_pattern_info(pattern_info, sprintf('OHD (n=%d,k=%d)', cfg.n, cfg.k), cfg.print_pattern_tables);

[MAP_TABLE_BAL, balanced_pattern_info] = select_patterns_balanced_ohd(cfg);
print_pattern_info(balanced_pattern_info, sprintf('B-OHD (n=%d,k=%d)', cfg.n, cfg.k), cfg.print_pattern_tables);

rng(cfg.rng_seed_baseline);
ofdm_result = simulate_baseline_ofdm(cfg);
rng(cfg.rng_seed_baseline);
otfs_result = simulate_baseline_otfs(cfg);

rng(cfg.rng_seed_im_compare);
im_result = simulate_otfs_im(cfg, MAP_TABLE);

rng(cfg.rng_seed_im_compare);
balanced_result = simulate_otfs_im(cfg, MAP_TABLE_BAL);

if cfg.enable_random_compare
    random_result = compare_random_patterns(cfg);
else
    random_result = [];
end

if cfg.apply_display_error_floor
    ofdm_result = apply_display_error_floor(cfg, ofdm_result, 'ofdm', cfg.N_fram_ofdm);
    otfs_result = apply_display_error_floor(cfg, otfs_result, 'otfs', cfg.N_fram);
    im_result = apply_display_error_floor(cfg, im_result, 'im', cfg.N_fram);
    balanced_result = apply_display_error_floor(cfg, balanced_result, 'im', cfg.N_fram);
    random_result = apply_display_error_floor(cfg, random_result, 'random', cfg.N_fram_random);
end

if cfg.save_results
    save_simulation_results(cfg, MAP_TABLE, MAP_TABLE_BAL, ...
        pattern_info, balanced_pattern_info, ...
        ofdm_result, otfs_result, im_result, balanced_result, random_result);
end

print_pattern_method_results(cfg, ofdm_result, otfs_result, im_result, balanced_result, random_result);
plot_pattern_method_results(cfg, ofdm_result, otfs_result, im_result, balanced_result, pattern_info, random_result);
toc;
