% Evaluation role: defines the thesis-grade experiment setup. The default
% configuration keeps OTFS and OTFS-IM at equal spectral efficiency so BER,
% index-error, and OHD pattern-selection conclusions are fair.
function cfg = config_otfs_im()
% Edit this file when changing frame count, SNR range, modulation order,
% IM block size, or diagnostic options.

cfg.N = 10;                     % Number of Doppler bins
cfg.M = 12;                     % Number of Delay bins
cfg.N_total = cfg.N * cfg.M;    % Total resource elements per frame
cfg.rng_seed = 1;               % Main random seed
cfg.rng_seed_baseline = 11;     % Seed for baseline OTFS simulation
cfg.rng_seed_im_compare = 22;   % Shared seed for OHD/proposed comparison
cfg.rng_seed_random_patterns = 101; % Seed for random-pattern baseline
cfg.N_fram = 1000;                % Number of OTFS/OTFS-IM simulated frames
cfg.N_fram_ofdm = 1000;            % OFDM frames; full-frame LMMSE is heavier.
cfg.EbN0_dB = 0:5:20;              % E_b/N_0 range for clean BER curves.
cfg.use_adaptive_frames = false; % Fixed-frame simulation.
cfg.enable_random_compare = true;
cfg.num_random_tables = 5;
cfg.N_fram_random = 100;
cfg.report_snr_points = [10 20]; % SNR points used in thesis summary tables.
cfg.print_full_tables = true;    % Print full BER tables across all SNR points.
cfg.print_pattern_tables = false; % Set true only when debugging selected pattern maps.
cfg.apply_display_error_floor = false; % Replace zero-error display points by Monte Carlo resolution.
cfg.save_results = true;
cfg.results_dir = 'results';

% Baseline OTFS configuration.
cfg.M_mod_otfs = 4;             % 4-QAM
cfg.M_bits_otfs = log2(cfg.M_mod_otfs);
cfg.total_bits_otfs = cfg.N_total * cfg.M_bits_otfs;
cfg.se_otfs = cfg.total_bits_otfs / cfg.N_total;

% OTFS-IM configuration.
% Recommended Chapter 5 runs:
% 1) n=4,k=3: main equal-SE case against OTFS.
% 2) n=4,k=2: lower-SE reliability trade-off case.
% 3) n=6,k=5 or n=6,k=4: larger-block validation or random-pattern validation.
cfg.n = 5;                      % Sub-carriers per IM block
cfg.g = cfg.N_total / cfg.n;    % Number of IM blocks per frame
cfg.k = 3;                      % Active sub-carriers per IM block
cfg.b1 = floor(log2(nchoosek(cfg.n, cfg.k)));
cfg.M_mod_im = 4;               % 4-QAM for active IM symbols
cfg.M_bits_im = log2(cfg.M_mod_im);
cfg.b2 = cfg.k * cfg.M_bits_im;
cfg.lambda = cfg.g * (cfg.b1 + cfg.b2);
cfg.se_im = cfg.lambda / cfg.N_total;
cfg.alpha = sqrt(cfg.n/cfg.k);

% Noise power calculation.
cfg.EsN0_otfs_dB = cfg.EbN0_dB + 10*log10(cfg.se_otfs);
cfg.EsN0_im_dB = cfg.EbN0_dB + 10*log10(cfg.se_im);
eng_sqrt = sqrt((cfg.M_mod_otfs-1)/6*(2^2));
cfg.sigma_2_otfs = abs(eng_sqrt * sqrt(1./(10.^(cfg.EsN0_otfs_dB/10)))).^2;
cfg.sigma_2_im = abs(eng_sqrt * sqrt(1./(10.^(cfg.EsN0_im_dB/10)))).^2;
end
