% Main experiment runner for the final OHD OTFS-IM setup.
% It compares conventional OTFS with OHD-selected OTFS-IM and reports the
% pattern geometry needed for the simulation-results section.
clc; clear; close all; tic;
addpath(genpath(fileparts(mfilename('fullpath'))));

cfg = config_otfs_im();
rng(cfg.rng_seed);

[MAP_TABLE, pattern_info] = select_patterns_ohd(cfg);
print_pattern_info(pattern_info, sprintf('OHD (n=%d,k=%d)', cfg.n, cfg.k));

rng(cfg.rng_seed_baseline);
otfs_result = simulate_baseline_otfs(cfg);

rng(cfg.rng_seed_im_compare);
im_result = simulate_otfs_im(cfg, MAP_TABLE);

print_ohd_results(cfg, otfs_result, im_result);
plot_ohd_results(cfg, otfs_result, im_result, pattern_info);
toc;
