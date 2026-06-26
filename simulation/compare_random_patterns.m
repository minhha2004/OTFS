% Evaluation role: random-pattern diagnostic baseline. It is not a proposed
% method; it proves whether OHD selection is better than arbitrary activation
% pattern choices under the same OTFS-IM receiver.
function random_result = compare_random_patterns(cfg)
% Compares OHD against random activation-pattern tables.
% This is a diagnostic baseline only; random tables are not part of the
% proposed method.

ALL_PATS = nchoosek(1:cfg.n, cfg.k);
num_total_pats = size(ALL_PATS, 1);
num_selected_pats = 2^cfg.b1;

random_result.applicable = num_total_pats > num_selected_pats;
random_result.num_total_pats = num_total_pats;
random_result.num_selected_pats = num_selected_pats;

if ~random_result.applicable
    random_result.reason = 'All valid patterns are already selected, so random and OHD use the same pattern set.';
    return;
end

BIN_PATS = zeros(num_total_pats, cfg.n);
for i = 1:num_total_pats
    BIN_PATS(i, ALL_PATS(i, :)) = 1;
end

D = zeros(num_total_pats);
for i = 1:num_total_pats
    for j = i+1:num_total_pats
        D(i, j) = sum(xor(BIN_PATS(i, :), BIN_PATS(j, :)));
        D(j, i) = D(i, j);
    end
end

cfg_random = cfg;
cfg_random.N_fram = cfg.N_fram_random;
cfg_random.use_adaptive_frames = false;
num_tables = cfg.num_random_tables;

random_result.ber_im = zeros(length(cfg.EbN0_dB), num_tables);
random_result.ber_idx = zeros(length(cfg.EbN0_dB), num_tables);
random_result.ber_sym = zeros(length(cfg.EbN0_dB), num_tables);
random_result.per_pattern = zeros(length(cfg.EbN0_dB), num_tables);
random_result.min_hd = zeros(num_tables, 1);
random_result.avg_hd = zeros(num_tables, 1);
random_result.carrier_usage = zeros(num_tables, cfg.n);

rng(cfg.rng_seed_random_patterns);
for itable = 1:num_tables
    selected_set = randperm(num_total_pats, num_selected_pats);
    MAP_RANDOM = ALL_PATS(selected_set, :);
    metrics = evaluate_pattern_table(selected_set, BIN_PATS, D);

    random_result.min_hd(itable) = metrics.min_hd;
    random_result.avg_hd(itable) = metrics.avg_hd;
    random_result.carrier_usage(itable, :) = metrics.carrier_usage;

    rng(cfg.rng_seed_random_patterns + itable);
    sim_result = simulate_otfs_im(cfg_random, MAP_RANDOM);
    random_result.ber_im(:, itable) = sim_result.ber_im;
    random_result.ber_idx(:, itable) = sim_result.ber_idx;
    random_result.ber_sym(:, itable) = sim_result.ber_sym;
    random_result.per_pattern(:, itable) = sim_result.per_pattern;
end

random_result.ber_im_avg = mean(random_result.ber_im, 2);
random_result.ber_idx_avg = mean(random_result.ber_idx, 2);
random_result.ber_sym_avg = mean(random_result.ber_sym, 2);
random_result.per_pattern_avg = mean(random_result.per_pattern, 2);
random_result.ber_im_best = min(random_result.ber_im, [], 2);
random_result.ber_idx_best = min(random_result.ber_idx, [], 2);
random_result.ber_sym_best = min(random_result.ber_sym, [], 2);
random_result.per_pattern_best = min(random_result.per_pattern, [], 2);
end
