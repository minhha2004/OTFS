function fig = plot_full_grid_ber(cfg, otfs_result, qpsk_result, ...
    conventional_ask_result, ask_result)
% PLOT_FULL_GRID_BER vẽ một hình so sánh Total BER của các hệ thống.
% Hình gồm OTFS-QPSK, QPSK-NBC đã refinement, 4-ASK thường và 4-ASK cải tiến.
% BER được vẽ theo thang log và fig được trả ra để file chính lưu ảnh.

fig = figure('Name', 'BER: OTFS vs Full-grid OTFS-IM', 'Color', 'w');
semilogy(cfg.EbN0_dB, log_plot_values(otfs_result.ber_total), ...
    '-ks', 'LineWidth', 1.8, 'MarkerSize', 7);
hold on;
semilogy(cfg.EbN0_dB, log_plot_values(qpsk_result.ber_total), ...
    '-ro', 'LineWidth', 1.8, 'MarkerSize', 7);
semilogy(cfg.EbN0_dB, log_plot_values(conventional_ask_result.ber_total), ...
    '--m^', 'LineWidth', 1.8, 'MarkerSize', 7);
semilogy(cfg.EbN0_dB, log_plot_values(ask_result.ber_total), ...
    '-bd', 'LineWidth', 1.8, 'MarkerSize', 7);
grid on;
xlabel('E_b/N_0 (dB)');
ylabel('Total BER');
title(sprintf('Full-grid OTFS-IM: N=%d, K=%d', ...
    cfg.N_grid, cfg.K_active));
legend('OTFS-QPSK', 'Full-grid QPSK-NBC + up-to-two-swap', ...
    'Full-grid Conventional 4-ASK', ...
    sprintf('Full-grid Modified 4-ASK (ratio %.1f)', cfg.ask_ratio), ...
    'Location', 'southwest');
xlim([min(cfg.EbN0_dB), max(cfg.EbN0_dB)]);
end

function values = log_plot_values(values)
% Thay BER bằng 0 bằng một số rất nhỏ chỉ để có thể hiển thị trên trục log.
positive = values(values > 0);
if isempty(positive)
    values(:) = 1e-8;
else
    values(values == 0) = min(positive) / 10;
end
end
