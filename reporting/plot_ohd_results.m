function plot_ohd_results(cfg, otfs_result, im_result, pattern_info)
% Plots report figures for the final OHD OTFS-IM setup.

plot_total_ber(cfg, otfs_result, im_result);
plot_error_components(cfg, im_result);
plot_pattern_heatmap(cfg, pattern_info);
plot_hamming_matrix(pattern_info);
plot_carrier_usage(pattern_info);
plot_ber_se_tradeoff(cfg, otfs_result, im_result);
end

function plot_total_ber(cfg, otfs_result, im_result)
figure('Name', 'OTFS vs OHD OTFS-IM BER', 'Color', 'w');
semilogy(cfg.EbN0_dB, otfs_result.ber_otfs, '-ks', 'LineWidth', 1.5, 'MarkerSize', 6);
hold on;
semilogy(cfg.EbN0_dB, im_result.ber_im, '-ro', 'LineWidth', 1.5, 'MarkerSize', 6);
grid on;
xlabel('E_b/N_0 (dB)');
ylabel('BER');
title('OTFS vs OHD OTFS-IM BER');
legend('OTFS', sprintf('OHD OTFS-IM n=%d,k=%d', cfg.n, cfg.k), 'Location', 'southwest');
end

function plot_error_components(cfg, im_result)
figure('Name', 'OHD OTFS-IM Error Components', 'Color', 'w');
semilogy(cfg.EbN0_dB, im_result.ber_im, '-ko', 'LineWidth', 1.5, 'MarkerSize', 6);
hold on;
semilogy(cfg.EbN0_dB, im_result.ber_idx, '--r^', 'LineWidth', 1.5, 'MarkerSize', 6);
semilogy(cfg.EbN0_dB, im_result.ber_sym, '--bv', 'LineWidth', 1.5, 'MarkerSize', 6);
semilogy(cfg.EbN0_dB, im_result.per_pattern, '--md', 'LineWidth', 1.5, 'MarkerSize', 6);
grid on;
xlabel('E_b/N_0 (dB)');
ylabel('Error rate');
title('OHD OTFS-IM Error Components');
legend('Total BER', 'Index BER', 'Symbol BER', 'Pattern ER', 'Location', 'southwest');
end

function plot_pattern_heatmap(cfg, pattern_info)
figure('Name', 'OHD Pattern Table', 'Color', 'w');
imagesc(pattern_binary_table(pattern_info.MAP_TABLE, cfg.n));
colormap(gca, [0.92 0.92 0.92; 0.1 0.35 0.8]);
colorbar('Ticks', [0 1], 'TickLabels', {'Inactive', 'Active'});
xlabel('Position in IM block');
ylabel('Pattern index');
title('OHD Selected Pattern Table');
set(gca, 'XTick', 1:cfg.n, 'YTick', 1:size(pattern_info.MAP_TABLE, 1));
end

function plot_hamming_matrix(pattern_info)
figure('Name', 'OHD Hamming Distance Matrix', 'Color', 'w');
D_selected = pattern_info.D(pattern_info.best_set, pattern_info.best_set);
imagesc(D_selected);
axis square;
colorbar;
xlabel('Pattern index');
ylabel('Pattern index');
title('OHD Hamming Distance Matrix');
set(gca, 'XTick', 1:size(D_selected, 1), 'YTick', 1:size(D_selected, 1));
end

function plot_carrier_usage(pattern_info)
figure('Name', 'OHD Carrier Usage', 'Color', 'w');
bar(pattern_info.metrics.carrier_usage);
grid on;
xlabel('Position in IM block');
ylabel('Number of selected patterns using position');
title('OHD Carrier Usage');
set(gca, 'XTick', 1:length(pattern_info.metrics.carrier_usage));
end

function plot_ber_se_tradeoff(cfg, otfs_result, im_result)
target_snr = 10;
[~, snr_idx] = min(abs(cfg.EbN0_dB - target_snr));
used_snr = cfg.EbN0_dB(snr_idx);

figure('Name', 'OHD BER-SE Trade-off', 'Color', 'w');
semilogy(cfg.se_otfs, otfs_result.ber_otfs(snr_idx), 'ks', 'LineWidth', 1.5, 'MarkerSize', 8);
hold on;
semilogy(cfg.se_im, im_result.ber_im(snr_idx), 'ro', 'LineWidth', 1.5, 'MarkerSize', 8);
grid on;
xlabel('Spectral efficiency (bits/symbol)');
ylabel('BER');
title(sprintf('BER-SE Trade-off at E_b/N_0 = %g dB', used_snr));
legend('OTFS', 'OHD OTFS-IM', 'Location', 'best');
end

function bin_table = pattern_binary_table(map_table, n)
bin_table = zeros(size(map_table, 1), n);
for i = 1:size(map_table, 1)
    bin_table(i, map_table(i, :)) = 1;
end
end
