% Evaluation role: builds the cross-configuration Chapter 5 figure that
% compares spectral efficiency and BER after several (n,k) OTFS-IM simulations
% have already been saved. This file is a post-processing tool, not part of a
% single-configuration Monte Carlo run.
function fig = plot_se_ber_tradeoff_from_results(result_files, snr_points, output_dir)
% Chapter 5 analysis order:
% 1) Run and save several (n,k) configurations.
% 2) Use this function to compare the saved configurations in the BER-SE plane.
% 3) Discuss which configurations keep the same SE as OTFS and which ones trade
%    rate for reliability.
%
% Usage:
%   plot_se_ber_tradeoff_from_results
%   plot_se_ber_tradeoff_from_results([], [10 15])
%   plot_se_ber_tradeoff_from_results(files, [10 15], 'results')

if nargin < 1 || isempty(result_files)
    result_files = find_result_files('results');
end

if nargin < 2 || isempty(snr_points)
    snr_points = [10 15];
end

if nargin < 3 || isempty(output_dir)
    output_dir = 'results';
end

if isempty(result_files)
    error('No result .mat files found. Run and save at least one OTFS-IM configuration first.');
end

records = load_tradeoff_records(result_files, snr_points);
fig = plot_tradeoff_records(records, snr_points);
summary_fig = plot_configuration_summary(records, snr_points);

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

savefig(fig, fullfile(output_dir, 'fig_se_ber_tradeoff.fig'));
exportgraphics(fig, fullfile(output_dir, 'fig_se_ber_tradeoff.png'), 'Resolution', 300);
fprintf('Saved BER-SE trade-off figure to %s\n', fullfile(output_dir, 'fig_se_ber_tradeoff.png'));

savefig(summary_fig, fullfile(output_dir, 'fig_configuration_ber_summary.fig'));
exportgraphics(summary_fig, fullfile(output_dir, 'fig_configuration_ber_summary.png'), 'Resolution', 300);
fprintf('Saved configuration BER summary figure to %s\n', fullfile(output_dir, 'fig_configuration_ber_summary.png'));
end

function result_files = find_result_files(results_dir)
files = dir(fullfile(results_dir, 'otfs_im_n*_k*_*.mat'));
result_files = fullfile({files.folder}, {files.name});

% Keep only the latest file for each (n,k) pair. This avoids plotting duplicate
% points if the same configuration was rerun many times.
labels = cell(size(result_files));
timestamps = zeros(size(result_files));
for i = 1:numel(result_files)
    data = load(result_files{i}, 'summary');
    labels{i} = sprintf('n%d_k%d', data.summary.n, data.summary.k);
    [~, name, ~] = fileparts(result_files{i});
    tokens = regexp(name, '(\d{8}_\d{6})$', 'tokens', 'once');
    if isempty(tokens)
        timestamps(i) = 0;
    else
        timestamps(i) = datenum(tokens{1}, 'yyyymmdd_HHMMSS');
    end
end

unique_labels = unique(labels);
selected = false(size(result_files));
for i = 1:numel(unique_labels)
    idx = find(strcmp(labels, unique_labels{i}));
    [~, newest_local] = max(timestamps(idx));
    selected(idx(newest_local)) = true;
end

result_files = result_files(selected);
result_files = sort_result_files_by_config(result_files);
end

function result_files = sort_result_files_by_config(result_files)
n_values = zeros(size(result_files));
k_values = zeros(size(result_files));
for i = 1:numel(result_files)
    data = load(result_files{i}, 'summary');
    n_values(i) = data.summary.n;
    k_values(i) = data.summary.k;
end

[~, order] = sortrows([n_values(:), k_values(:)]);
result_files = result_files(order);
end

function records = load_tradeoff_records(result_files, snr_points)
num_files = numel(result_files);
records = struct([]);

for i = 1:num_files
    data = load(result_files{i});
    cfg = data.cfg;
    summary = data.summary;

    records(i).label = sprintf('(%d,%d)', summary.n, summary.k);
    records(i).n = summary.n;
    records(i).k = summary.k;
    records(i).se_im = summary.se_im;
    records(i).se_otfs = summary.se_otfs;
    records(i).equal_se = summary.equal_se;
    records(i).snr = snr_points;
    records(i).ber_otfs = sample_metric(cfg.EbN0_dB, data.otfs_result.ber_otfs, snr_points);
    records(i).ber_ohd = sample_metric(cfg.EbN0_dB, data.im_result.ber_im, snr_points);
    records(i).ber_balanced = sample_optional_metric(cfg.EbN0_dB, data, 'balanced_result', 'ber_im', snr_points);
    records(i).ber_random = sample_optional_metric(cfg.EbN0_dB, data, 'random_result', 'ber_im_avg', snr_points);
end
end

function values = sample_metric(x_snr, metric, snr_points)
values = nan(size(snr_points));
for i = 1:numel(snr_points)
    [~, idx] = min(abs(x_snr - snr_points(i)));
    values(i) = metric(idx);
end
end

function values = sample_optional_metric(x_snr, data, result_name, field_name, snr_points)
values = nan(size(snr_points));
if ~isfield(data, result_name) || isempty(data.(result_name)) || ~isfield(data.(result_name), field_name)
    return;
end

values = sample_metric(x_snr, data.(result_name).(field_name), snr_points);
end

function fig = plot_tradeoff_records(records, snr_points)
fig = figure('Name', 'BER-SE Trade-off Across Configurations', 'Color', 'w');
tiledlayout(1, numel(snr_points), 'TileSpacing', 'compact', 'Padding', 'compact');

for isnr = 1:numel(snr_points)
    nexttile;
    hold on;

    se_otfs = records(1).se_otfs;
    ber_otfs = records(1).ber_otfs(isnr);
    semilogy(se_otfs, log_plot_value(ber_otfs), 'ks', ...
        'LineWidth', 1.8, 'MarkerSize', 9, 'MarkerFaceColor', 'k');

    se_im = [records.se_im];
    ber_ohd = arrayfun(@(r) r.ber_ohd(isnr), records);
    ber_balanced = arrayfun(@(r) r.ber_balanced(isnr), records);

    semilogy(se_im, log_plot_values(ber_ohd), 'ro', ...
        'LineStyle', 'none', 'LineWidth', 1.8, 'MarkerSize', 7);

    valid_balanced = ~isnan(ber_balanced);
    if any(valid_balanced)
        semilogy(se_im(valid_balanced), log_plot_values(ber_balanced(valid_balanced)), 'd', ...
            'Color', [0.00 0.45 0.74], 'LineStyle', 'none', ...
            'LineWidth', 1.8, 'MarkerSize', 7);
    end

    xline(se_otfs, '--k', 'OTFS SE', 'LabelVerticalAlignment', 'bottom', ...
        'LabelHorizontalAlignment', 'left');

    for i = 1:numel(records)
        [x_offset, y_factor, h_align] = label_offset(records(i).n, records(i).k, isnr);
        text(se_im(i) + x_offset, log_plot_value(ber_ohd(i)) * y_factor, ...
            records(i).label, 'FontSize', 8, 'HorizontalAlignment', h_align);
    end

    grid on;
    set(gca, 'YScale', 'log');
    xlabel('Spectral efficiency (bits/symbol)');
    ylabel('BER');
    title(sprintf('E_b/N_0 = %g dB', snr_points(isnr)));
    xlim([min([se_im, se_otfs]) - 0.08, max([se_im, se_otfs]) + 0.12]);
    apply_log_ylim([ber_otfs, ber_ohd, ber_balanced]);

    if isnr == 1
        legend_entries = {'OTFS', 'OHD OTFS-IM'};
        if any(valid_balanced)
            legend_entries{end+1} = 'B-OHD OTFS-IM';
        end
        legend(legend_entries, 'Location', 'southwest');
    end
end

sgtitle('BER-SE Trade-off Across OTFS-IM Configurations');
end

function [x_offset, y_factor, h_align] = label_offset(n, k, snr_index)
% Manual offsets keep labels readable when several configurations have the
% same spectral efficiency, especially the equal-SE group at SE = 2.
x_offset = 0.014;
y_factor = 1.12;
h_align = 'left';

if n == 4 && k == 2
    x_offset = 0.025;
    y_factor = 1.20;
elseif n == 6 && k == 3
    x_offset = 0.010;
    y_factor = 1.28;
elseif n == 6 && k == 4
    x_offset = 0.025;
    y_factor = 1.30;
elseif n == 4 && k == 3
    x_offset = 0.022;
    y_factor = 1.45;
elseif n == 5 && k == 3
    x_offset = 0.018;
    y_factor = 0.78;
elseif n == 5 && k == 4
    x_offset = 0.022;
    y_factor = 1.13;
elseif n == 6 && k == 5
    x_offset = 0.022;
    y_factor = 0.78;
end

if snr_index == 2
    if n == 4 && k == 3
        x_offset = 0.028;
        y_factor = 1.12;
    elseif n == 5 && k == 4
        x_offset = 0.028;
        y_factor = 1.38;
    elseif n == 5 && k == 3
        x_offset = 0.020;
        y_factor = 0.70;
    elseif n == 6 && k == 5
        x_offset = 0.028;
        y_factor = 0.72;
    elseif n == 6 && k == 4
        x_offset = 0.025;
        y_factor = 1.35;
    end
end
end

function fig = plot_configuration_summary(records, snr_points)
fig = figure('Name', 'Configuration BER Summary', 'Color', 'w', ...
    'Position', [100 100 900 720]);
tiledlayout(numel(snr_points), 1, 'TileSpacing', 'compact', 'Padding', 'compact');

labels = cell(1, numel(records));
for i = 1:numel(records)
    labels{i} = records(i).label;
end

for isnr = 1:numel(snr_points)
    nexttile;

    ber_ohd = arrayfun(@(r) r.ber_ohd(isnr), records);
    ber_balanced = arrayfun(@(r) r.ber_balanced(isnr), records);
    ber_otfs = records(1).ber_otfs(isnr);

    y = [log_plot_values(ber_ohd(:)), log_plot_values(ber_balanced(:))];
    b = bar(y, 'grouped');
    b(1).FaceColor = [0.85 0.10 0.10];
    b(2).FaceColor = [0.00 0.45 0.74];
    hold on;
    yline(log_plot_value(ber_otfs), '--k', 'OTFS', 'LineWidth', 1.2, ...
        'LabelHorizontalAlignment', 'left');

    set(gca, 'YScale', 'log');
    grid on;
    xticks(1:numel(records));
    xticklabels(labels);
    xtickangle(0);
    set(gca, 'FontSize', 10);
    xlabel('OTFS-IM configuration (n,k)');
    ylabel('BER');
    title(sprintf('E_b/N_0 = %g dB', snr_points(isnr)));
    apply_log_ylim([ber_otfs, ber_ohd, ber_balanced]);

    yl = ylim;
    se_label_y = 10^(log10(yl(1)) + 0.86 * (log10(yl(2)) - log10(yl(1))));
    for i = 1:numel(records)
        text(i, se_label_y, sprintf('SE=%.2f', records(i).se_im), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 8, ...
            'Color', [0.25 0.25 0.25]);
    end

    if isnr == 1
        legend('OHD OTFS-IM', 'B-OHD OTFS-IM', 'OTFS baseline', 'Location', 'southwest');
    end
end

sgtitle('BER Comparison Across OTFS-IM Configurations');
end

function y = log_plot_value(value)
if isnan(value)
    y = NaN;
elseif value <= 0
    y = 1e-6;
else
    y = value;
end
end

function values = log_plot_values(values)
values(values <= 0 & ~isnan(values)) = 1e-6;
end

function apply_log_ylim(values)
values = values(~isnan(values));
values(values <= 0) = 1e-6;
if isempty(values)
    return;
end

lower = 10^floor(log10(min(values))) / 2;
upper = 10^ceil(log10(max(values))) * 2;
ylim([max(lower, 1e-6), min(upper, 1)]);
end
