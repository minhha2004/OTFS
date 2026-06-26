% Evaluation role: prints thesis-focused numerical evidence. The tables show
% equal-SE fairness, OHD gains, index/symbol/PER decomposition, and optional
% random-pattern validation instead of reporting only raw BER curves.
function print_pattern_method_results(cfg, ofdm_result, otfs_result, ohd_result, balanced_result, random_result)
% Chapter 5 analysis order:
% 1) Confirm rate fairness using spectral efficiency.
% 2) Compare OFDM, OTFS, OHD OTFS-IM, and B-OHD at reference SNR points.
% 3) Explain OHD total BER using index BER, symbol BER, and pattern error rate.
% 4) Use full SNR tables only for debugging by setting cfg.print_full_tables=true.

if nargin < 6
    random_result = [];
end
has_balanced = ~isempty(balanced_result);
has_random = ~isempty(random_result) && isfield(random_result, 'applicable') && random_result.applicable;

fprintf('\n========================================================\n');
fprintf('          OTFS-IM PATTERN-SELECTION RESULT ANALYSIS     \n');
fprintf('========================================================\n');
fprintf('Baseline OTFS SE: %.2f bits/symbol\n', cfg.se_otfs);
fprintf('Baseline OFDM-LMMSE SE: %.2f bits/symbol\n', cfg.se_otfs);
if isfield(cfg, 'use_adaptive_frames') && cfg.use_adaptive_frames
    fprintf('Adaptive frames: min %d, max %d, target errors %d\n', ...
        cfg.min_frames_per_snr, cfg.max_frames_per_snr, cfg.target_bit_errors);
elseif isfield(cfg, 'N_fram_ofdm')
    fprintf('OFDM-LMMSE frames: %d, OTFS/OTFS-IM frames: %d\n', cfg.N_fram_ofdm, cfg.N_fram);
end
fprintf('OTFS-IM SE (n=%d,k=%d): %.2f bits/symbol\n', cfg.n, cfg.k, cfg.se_im);
fprintf('Reduction: %.1f%%\n', (1 - cfg.se_im/cfg.se_otfs)*100);
if abs(cfg.se_im - cfg.se_otfs) < 1e-12
    fprintf('Fairness note: OTFS and OTFS-IM have equal SE, so BER comparison is rate-fair.\n');
else
    fprintf('Fairness note: OTFS and OTFS-IM have different SE; interpret BER as a BER-SE trade-off.\n');
end
if isfield(cfg, 'apply_display_error_floor') && cfg.apply_display_error_floor
    fprintf('Zero-error display floor: enabled using Monte Carlo resolution\n');
end

print_thesis_summary(cfg, ofdm_result, otfs_result, ohd_result, balanced_result, random_result, has_balanced, has_random);

if ~isfield(cfg, 'print_full_tables') || ~cfg.print_full_tables
    return;
end

if has_random
    fprintf('Random baseline: %d tables, %d frames/table\n', cfg.num_random_tables, cfg.N_fram_random);
    fprintf('\n================================================================================\n');
    fprintf('Eb/N0 | BER OFDM-LMMSE | BER OTFS | BER OHD-IM | BER B-OHD | BER Random-IM(avg)\n');
    for i = 1:length(cfg.EbN0_dB)
        fprintf('%5d | %8.5f | %8.5f | %10.5f | %9.5f | %18.5f\n', ...
            cfg.EbN0_dB(i), ...
            ofdm_result.ber_ofdm(i), ...
            otfs_result.ber_otfs(i), ...
            ohd_result.ber_im(i), ...
            optional_metric(balanced_result, 'ber_im', i), ...
            random_result.ber_im_avg(i));
    end

    fprintf('\n');
    fprintf('========================================================================================\n');
    fprintf('Eb/N0 | OHD Idx | B-OHD Idx | Rand Idx | OHD Sym | B-OHD Sym | Rand Sym | OHD PER | B-OHD PER | Rand PER\n');
    for i = 1:length(cfg.EbN0_dB)
        fprintf('%5d | %7.5f | %9.5f | %8.5f | %7.5f | %9.5f | %8.5f | %7.5f | %9.5f | %8.5f\n', ...
            cfg.EbN0_dB(i), ...
            ohd_result.ber_idx(i), ...
            optional_metric(balanced_result, 'ber_idx', i), ...
            random_result.ber_idx_avg(i), ...
            ohd_result.ber_sym(i), ...
            optional_metric(balanced_result, 'ber_sym', i), ...
            random_result.ber_sym_avg(i), ...
            ohd_result.per_pattern(i), ...
            optional_metric(balanced_result, 'per_pattern', i), ...
            random_result.per_pattern_avg(i));
    end
else
    if ~isempty(random_result) && isfield(random_result, 'reason')
        fprintf('Random baseline: not applicable. %s\n', random_result.reason);
    end

    fprintf('\n=====================================================================================\n');
    fprintf('Eb/N0 | BER OFDM-LMMSE | BER OTFS | BER OHD-IM | BER B-OHD | OHD Index | B-OHD Index\n');
    for i = 1:length(cfg.EbN0_dB)
        fprintf('%5d | %8.5f | %8.5f | %10.5f | %9.5f | %9.5f | %11.5f\n', ...
            cfg.EbN0_dB(i), ...
            ofdm_result.ber_ofdm(i), ...
            otfs_result.ber_otfs(i), ...
            ohd_result.ber_im(i), ...
            optional_metric(balanced_result, 'ber_im', i), ...
            ohd_result.ber_idx(i), ...
            optional_metric(balanced_result, 'ber_idx', i));
    end
end

if isfield(cfg, 'use_adaptive_frames') && cfg.use_adaptive_frames
    fprintf('\n==============================================================\n');
    fprintf('Adaptive frame count per Eb/N0 point\n');
    fprintf('Eb/N0 | OFDM-LMMSE frames | OTFS frames | OHD frames | B-OHD frames\n');
    for i = 1:length(cfg.EbN0_dB)
        fprintf('%5d | %11d | %11d | %10d | %10d\n', ...
            cfg.EbN0_dB(i), ...
            ofdm_result.frames_used(i), ...
            otfs_result.frames_used(i), ...
            ohd_result.frames_used(i), ...
            balanced_result.frames_used(i));
    end
end
end

function print_thesis_summary(cfg, ofdm_result, otfs_result, ohd_result, balanced_result, random_result, has_balanced, has_random)
fprintf('\n========================================================\n');
fprintf('          THESIS-FOCUSED OHD EVALUATION SUMMARY         \n');
fprintf('========================================================\n');

snr_points = get_report_snr_points(cfg);
fprintf('Reference SNR points: %s dB\n', mat2str(snr_points));
fprintf('OHD interpretation chain: larger pattern separation -> lower PER -> lower index BER -> lower total BER.\n');

fprintf('\nRate-fair BER comparison at reference SNR points\n');
if has_random
    if has_balanced
        fprintf('Eb/N0 | OFDM-LMMSE BER | OTFS BER | OHD BER | B-OHD BER | Random avg | OHD/OTFS gain | B-OHD/OTFS gain\n');
    else
        fprintf('Eb/N0 | OFDM-LMMSE BER | OTFS BER | OHD BER | Random avg | OHD/OTFS gain | OHD/Random gain\n');
    end
else
    if has_balanced
        fprintf('Eb/N0 | OFDM-LMMSE BER | OTFS BER | OHD BER | B-OHD BER | OHD/OTFS gain | B-OHD/OTFS gain\n');
    else
        fprintf('Eb/N0 | OFDM-LMMSE BER | OTFS BER | OHD BER | OHD/OTFS gain\n');
    end
end

for isnr = 1:length(snr_points)
    idx = nearest_snr_index(cfg.EbN0_dB, snr_points(isnr));
    gain_otfs = safe_ratio_db(otfs_result.ber_otfs(idx), ohd_result.ber_im(idx));
    gain_balanced = NaN;
    if has_balanced
        gain_balanced = safe_ratio_db(otfs_result.ber_otfs(idx), balanced_result.ber_im(idx));
    end

    if has_random
        if has_balanced
            fprintf('%5g | %s | %s | %s | %s | %s | %+7.2f dB | %+9.2f dB\n', ...
                cfg.EbN0_dB(idx), ...
                format_ber(ofdm_result.ber_ofdm(idx)), ...
                format_ber(otfs_result.ber_otfs(idx)), ...
                format_ber(ohd_result.ber_im(idx)), ...
                format_ber(balanced_result.ber_im(idx)), ...
                format_ber(random_result.ber_im_avg(idx)), ...
                gain_otfs, ...
                gain_balanced);
        else
            gain_random = safe_ratio_db(random_result.ber_im_avg(idx), ohd_result.ber_im(idx));
            fprintf('%5g | %s | %s | %s | %s | %+7.2f dB | %+9.2f dB\n', ...
                cfg.EbN0_dB(idx), ...
                format_ber(ofdm_result.ber_ofdm(idx)), ...
                format_ber(otfs_result.ber_otfs(idx)), ...
                format_ber(ohd_result.ber_im(idx)), ...
                format_ber(random_result.ber_im_avg(idx)), ...
                gain_otfs, ...
                gain_random);
        end
    else
        if has_balanced
            fprintf('%5g | %s | %s | %s | %s | %+7.2f dB | %+9.2f dB\n', ...
                cfg.EbN0_dB(idx), ...
                format_ber(ofdm_result.ber_ofdm(idx)), ...
                format_ber(otfs_result.ber_otfs(idx)), ...
                format_ber(ohd_result.ber_im(idx)), ...
                format_ber(balanced_result.ber_im(idx)), ...
                gain_otfs, ...
                gain_balanced);
        else
            fprintf('%5g | %s | %s | %s | %+7.2f dB\n', ...
                cfg.EbN0_dB(idx), ...
                format_ber(ofdm_result.ber_ofdm(idx)), ...
                format_ber(otfs_result.ber_otfs(idx)), ...
                format_ber(ohd_result.ber_im(idx)), ...
                gain_otfs);
        end
    end
end

fprintf('\nOHD error-component decomposition\n');
fprintf('Eb/N0 | Total BER | Index BER | Symbol BER | Pattern ER | Index share | Symbol share\n');
for isnr = 1:length(snr_points)
    idx = nearest_snr_index(cfg.EbN0_dB, snr_points(isnr));
    component_errors = ohd_result.err_idx_bits(idx) + ohd_result.err_sym_bits(idx);
    idx_share = error_share(ohd_result.err_idx_bits(idx), component_errors);
    sym_share = error_share(ohd_result.err_sym_bits(idx), component_errors);

    fprintf('%5g | %s | %s | %s | %s | %10.1f%% | %11.1f%%\n', ...
        cfg.EbN0_dB(idx), ...
        format_ber(ohd_result.ber_im(idx)), ...
        format_ber(ohd_result.ber_idx(idx)), ...
        format_ber(ohd_result.ber_sym(idx)), ...
        format_ber(ohd_result.per_pattern(idx)), ...
        100 * idx_share, ...
        100 * sym_share);
end

% Report-writing note:
% Low SNR: noise dominates, so pattern errors explain most OTFS-IM penalties.
% Medium SNR: OHD separation should reduce PER and index BER.
% High SNR: if PER is small, remaining BER is mainly QAM/residual MP error.
end

function snr_points = get_report_snr_points(cfg)
if isfield(cfg, 'report_snr_points') && ~isempty(cfg.report_snr_points)
    snr_points = cfg.report_snr_points;
else
    mid_idx = ceil(numel(cfg.EbN0_dB) / 2);
    snr_points = [cfg.EbN0_dB(mid_idx), cfg.EbN0_dB(end)];
end
end

function idx = nearest_snr_index(snr_grid, target_snr)
[~, idx] = min(abs(snr_grid - target_snr));
end

function value_db = safe_ratio_db(reference_ber, test_ber)
if reference_ber <= 0 || test_ber <= 0
    value_db = NaN;
else
    value_db = 10 * log10(reference_ber / test_ber);
end
end

function share = error_share(error_count, total_component_errors)
if total_component_errors <= 0
    share = 0;
    return;
end

share = error_count / total_component_errors;
end

function text_value = format_ber(value)
if isnan(value)
    text_value = '   n/a ';
else
    text_value = sprintf('%.5f', value);
end
end

function value = optional_metric(result, field_name, idx)
if isempty(result) || ~isfield(result, field_name)
    value = NaN;
else
    values = result.(field_name);
    value = values(idx);
end
end
