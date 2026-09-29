% OTFS_SAMPLE_CODE
% Đọc cấu hình chung của hệ thống.
% Tạo một nhánh OTFS-IM NBC dùng 16-QAM và không dùng two-swap.
% So sánh OTFS-16QAM gốc với full-grid OTFS-IM-16QAM.
% In bảng BER, vẽ hình và lưu toàn bộ kết quả vào thư mục results.
clc; clear; close all; tic;
project_dir = fileparts(mfilename('fullpath'));
addpath(genpath(project_dir));

cfg = config_full_grid_otfs_im();
% K=113 là lựa chọn gần K=16*Ngrid/(16+1) của bài báo cho 16-QAM.
qam16_cfg = build_full_grid_variant(cfg, 'OTFS-IM NBC', ...
    qammod(0:15, 16), cfg.K_active);
qam16_cfg.enable_local_support_refinement = false;

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
% Chạy OTFS-16QAM gốc để làm đường tham chiếu.
otfs_result = simulate_baseline_otfs(cfg);

rng(cfg.rng_seed_im);
qam16_result = simulate_full_grid_otfs_im(qam16_cfg);

print_full_grid_results(cfg, qam16_cfg, otfs_result, qam16_result);
fig = plot_full_grid_ber(cfg, otfs_result, qam16_result);

mat_file = fullfile(results_dir, ...
    sprintf('full_grid_results_%s.mat', run_tag));
png_file = fullfile(results_dir, ...
    sprintf('full_grid_ber_%s.png', run_tag));
save(mat_file, 'cfg', 'qam16_cfg', 'otfs_result', 'qam16_result');
saveas(fig, png_file);
save(fullfile(results_dir, 'full_grid_results_latest.mat'), ...
    'cfg', 'qam16_cfg', 'otfs_result', 'qam16_result');
saveas(fig, fullfile(results_dir, 'full_grid_ber_latest.png'));

fprintf('\nSaved data   : %s\n', mat_file);
fprintf('Saved figure : %s\n', png_file);
toc;
diary off;
copyfile(console_file, fullfile(results_dir, 'full_grid_results_latest.txt'));
