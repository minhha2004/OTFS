% OTFS_SAMPLE_CODE
% Đọc cấu hình chung của hệ thống.
% Tạo ba nhánh OTFS-IM: QPSK, 4-ASK thường và 4-ASK cải tiến.
% Chạy mô phỏng OTFS gốc và từng nhánh OTFS-IM.
% In bảng BER, vẽ hình và lưu toàn bộ kết quả vào thư mục results.
clc; clear; close all; tic;
project_dir = fileparts(mfilename('fullpath'));
addpath(genpath(project_dir));

cfg = config_full_grid_otfs_im();
% Tạo nhánh QPSK và bật bộ sửa tối đa hai vị trí active bị chọn sai.
qpsk_cfg = build_full_grid_variant(cfg, 'Full-grid QPSK-NBC', ...
    qammod(0:3, 4), 96);
qpsk_cfg.enable_local_support_refinement = true;
qpsk_cfg.refinement_boundary_size = 4;
qpsk_cfg.refinement_max_swaps = 2;
conventional_ask_alphabet = modified_4ask_alphabet( ...
    cfg.ask_conventional_ratio, mean(abs(qammod(0:3, 4)).^2));
conventional_ask_cfg = build_full_grid_variant(cfg, ...
    'Full-grid Conventional 4-ASK-NBC', conventional_ask_alphabet, 96);
ask_alphabet = modified_4ask_alphabet(cfg.ask_ratio, ...
    mean(abs(qammod(0:3, 4)).^2));
ask_cfg = build_full_grid_variant(cfg, ...
    sprintf('Full-grid Modified 4-ASK-NBC (ratio %.1f)', cfg.ask_ratio), ...
    ask_alphabet, 96);

results_dir = fullfile(project_dir, cfg.results_dir);
% Tạo thư mục kết quả trước khi bật diary để tránh lỗi không tìm thấy file.
if ~exist(results_dir, 'dir')
    [created, message] = mkdir(results_dir);
    if ~created
        error('Cannot create results directory "%s": %s', ...
            results_dir, message);
    end
end
run_tag = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
console_file = fullfile(results_dir, ...
    sprintf('full_grid_results_%s.txt', run_tag));
diary(console_file);

rng(cfg.rng_seed_baseline);
% Chạy OTFS-QPSK gốc để làm đường tham chiếu.
otfs_result = simulate_baseline_otfs(cfg);

rng(cfg.rng_seed_im);
% Các nhánh IM dùng cùng seed để được so sánh trên cùng chuỗi kênh/ngẫu nhiên.
qpsk_result = simulate_full_grid_otfs_im(qpsk_cfg);

rng(cfg.rng_seed_im);
conventional_ask_result = simulate_full_grid_otfs_im(conventional_ask_cfg);

rng(cfg.rng_seed_im);
ask_result = simulate_full_grid_otfs_im(ask_cfg);

print_full_grid_results(cfg, qpsk_cfg, conventional_ask_cfg, ask_cfg, ...
    otfs_result, qpsk_result, conventional_ask_result, ask_result);
fig = plot_full_grid_ber(cfg, otfs_result, qpsk_result, ...
    conventional_ask_result, ask_result);

mat_file = fullfile(results_dir, ...
    sprintf('full_grid_results_%s.mat', run_tag));
png_file = fullfile(results_dir, ...
    sprintf('full_grid_ber_%s.png', run_tag));
save(mat_file, 'cfg', 'qpsk_cfg', 'conventional_ask_cfg', 'ask_cfg', ...
    'otfs_result', 'qpsk_result', 'conventional_ask_result', 'ask_result');
saveas(fig, png_file);
save(fullfile(results_dir, 'full_grid_results_latest.mat'), ...
    'cfg', 'qpsk_cfg', 'conventional_ask_cfg', 'ask_cfg', ...
    'otfs_result', 'qpsk_result', 'conventional_ask_result', 'ask_result');
saveas(fig, fullfile(results_dir, 'full_grid_ber_latest.png'));

fprintf('\nSaved data   : %s\n', mat_file);
fprintf('Saved figure : %s\n', png_file);
toc;
diary off;
copyfile(console_file, fullfile(results_dir, 'full_grid_results_latest.txt'));
