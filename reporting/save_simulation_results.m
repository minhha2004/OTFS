% Evaluation role: saves reproducible Chapter 5 evidence, including BER,
% error decomposition, pattern tables, and summary points for SE-BER trade-off
% plots without rerunning Monte Carlo simulation.
function save_simulation_results(cfg, MAP_TABLE, MAP_TABLE_BAL, ...
    pattern_info, balanced_pattern_info, ...
    ofdm_result, otfs_result, im_result, balanced_result, random_result)
% Saves one complete simulation run for later plotting without re-running
% Monte Carlo simulation.

if ~exist(cfg.results_dir, 'dir')
    mkdir(cfg.results_dir);
end

timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
filename = sprintf('otfs_im_n%d_k%d_%s.mat', cfg.n, cfg.k, timestamp);
filepath = fullfile(cfg.results_dir, filename);

summary = build_result_summary(cfg, ofdm_result, otfs_result, im_result, balanced_result);
saved_data.cfg = cfg;
saved_data.MAP_TABLE = MAP_TABLE;
saved_data.MAP_TABLE_BAL = MAP_TABLE_BAL;
saved_data.pattern_info = pattern_info;
saved_data.balanced_pattern_info = balanced_pattern_info;
saved_data.ofdm_result = ofdm_result;
saved_data.otfs_result = otfs_result;
saved_data.im_result = im_result;
saved_data.balanced_result = balanced_result;
saved_data.random_result = random_result;
saved_data.summary = summary;
save(filepath, '-struct', 'saved_data');

latest_path = fullfile(cfg.results_dir, 'latest_results.mat');
save(latest_path, '-struct', 'saved_data');

fprintf('Saved results to %s\n', filepath);
fprintf('Updated latest result file: %s\n', latest_path);
end

function summary = build_result_summary(cfg, ofdm_result, otfs_result, im_result, balanced_result)
target_snr = 10;
[~, snr_idx] = min(abs(cfg.EbN0_dB - target_snr));

summary.n = cfg.n;
summary.k = cfg.k;
summary.M_mod_im = cfg.M_mod_im;
summary.se_otfs = cfg.se_otfs;
summary.se_im = cfg.se_im;
summary.snr_ref = cfg.EbN0_dB(snr_idx);
summary.ber_ofdm_ref = ofdm_result.ber_ofdm(snr_idx);
summary.ber_otfs_ref = otfs_result.ber_otfs(snr_idx);
summary.ber_ohd_ref = im_result.ber_im(snr_idx);
summary.ber_balanced_ref = get_optional_metric(balanced_result, 'ber_im', snr_idx);
summary.index_ohd_ref = im_result.ber_idx(snr_idx);
summary.index_balanced_ref = get_optional_metric(balanced_result, 'ber_idx', snr_idx);
summary.symbol_ohd_ref = im_result.ber_sym(snr_idx);
summary.symbol_balanced_ref = get_optional_metric(balanced_result, 'ber_sym', snr_idx);
summary.pattern_ohd_ref = im_result.per_pattern(snr_idx);
summary.pattern_balanced_ref = get_optional_metric(balanced_result, 'per_pattern', snr_idx);
summary.equal_se = abs(cfg.se_im - cfg.se_otfs) < 1e-12;
summary.ohd_gain_vs_otfs_db = safe_ratio_db(summary.ber_otfs_ref, summary.ber_ohd_ref);
summary.balanced_gain_vs_otfs_db = safe_ratio_db(summary.ber_otfs_ref, summary.ber_balanced_ref);
summary.label = sprintf('n=%d,k=%d', cfg.n, cfg.k);
end

function value = get_optional_metric(result, field_name, idx)
if isempty(result) || ~isfield(result, field_name)
    value = NaN;
else
    values = result.(field_name);
    value = values(idx);
end
end

function value_db = safe_ratio_db(reference_ber, test_ber)
if reference_ber <= 0 || test_ber <= 0
    value_db = NaN;
else
    value_db = 10 * log10(reference_ber / test_ber);
end
end
