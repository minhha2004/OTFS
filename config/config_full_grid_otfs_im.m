function cfg = config_full_grid_otfs_im()
% CONFIG_FULL_GRID_OTFS_IM khai báo các tham số dùng chung của mô phỏng.
% Khai báo lưới 10 x 12, số frame và dải Eb/N0.
% Khai báo số vòng lặp MP và tham số của bộ sửa vị trí active.
% Khai báo tỉ lệ của 4-ASK thường và 4-ASK cải tiến.
% Tính tốc độ và phương sai nhiễu cho hệ OTFS-QPSK gốc.

cfg.N = 10;                     % Doppler bins
cfg.M = 12;                     % Delay bins
cfg.N_grid = cfg.N * cfg.M;     % Full delay-Doppler grid size
cfg.K_active = 96;              % Rate-oriented choice for M=4: M*N/(M+1)
cfg.N_fram = 1000;
cfg.EbN0_dB = 0:5:20;
cfg.rng_seed_baseline = 11;
cfg.rng_seed_im = 22;
cfg.mp_iterations = 10;
cfg.mp_damping = 0.6;
cfg.enable_local_support_refinement = false;
cfg.refinement_boundary_size = 4;
cfg.refinement_max_swaps = 1;
cfg.ask_conventional_ratio = 1.0;
cfg.ask_ratio = 4.0;
cfg.results_dir = 'results';

% Các thông số tốc độ của hệ OTFS-QPSK gốc.
cfg.M_mod_otfs = 4;
cfg.M_bits_otfs = log2(cfg.M_mod_otfs);
cfg.total_bits_otfs = cfg.N_grid * cfg.M_bits_otfs;
cfg.se_otfs = cfg.total_bits_otfs / cfg.N_grid;

% Phương sai nhiễu của OTFS gốc để so sánh tại cùng Eb/N0.
cfg.EsN0_otfs_dB = cfg.EbN0_dB + 10*log10(cfg.se_otfs);
qam_energy_sqrt = sqrt((cfg.M_mod_otfs - 1)/6 * 4);
cfg.sigma_2_otfs = abs(qam_energy_sqrt * sqrt(1./(10.^(cfg.EsN0_otfs_dB/10)))).^2;
end
