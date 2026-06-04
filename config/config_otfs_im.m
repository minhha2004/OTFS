function cfg = config_otfs_im()
% Stores all system parameters used by the OTFS/OTFS-IM experiment.
% Edit this file when changing frame count, SNR range, modulation order,
% IM block size, or diagnostic options.

cfg.N = 10;                     % Number of Doppler bins
cfg.M = 12;                     % Number of Delay bins
cfg.N_total = cfg.N * cfg.M;    % Total resource elements per frame
cfg.rng_seed = 1;               % Main random seed
cfg.rng_seed_baseline = 11;     % Seed for baseline OTFS simulation
cfg.rng_seed_im_compare = 22;   % Shared seed for OHD/proposed comparison
cfg.N_fram = 1000;                % Number of simulated frames
cfg.EbN0_dB = 5:5:30;            % E_b/N_0 range

% Baseline OTFS configuration.
cfg.M_mod_otfs = 4;             % 4-QAM
cfg.M_bits_otfs = log2(cfg.M_mod_otfs);
cfg.total_bits_otfs = cfg.N_total * cfg.M_bits_otfs;
cfg.se_otfs = cfg.total_bits_otfs / cfg.N_total;

% OTFS-IM configuration.
cfg.n = 4;                      % Sub-carriers per IM block
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
