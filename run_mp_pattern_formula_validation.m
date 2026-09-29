function result = run_mp_pattern_formula_validation(num_frames, ebn0_db)
% RUN_MP_PATTERN_FORMULA_VALIDATION kiem chung truc tiep cong thuc (15).
% Buoc 1: Mo phong OTFS-IM, MP va Top-K de lay P_pattern thuc te.
% Buoc 2: Uoc luong p_A, nu_A, p_0, nu_0 cua mo hinh Bernoulli-Gaussian
%          tu sai lech mem sau MP: w_MP = y_tilde - x.
% Buoc 3: Dung (4)--(12) trong bao cao de sinh F_X va F_Z theo mo hinh BG.
% Buoc 4: The F_X, F_Z vao cong thuc (15) de tinh P_pattern ly thuyet.
%
% Cach chay de kiem chung vung SNR cao:
%   run_mp_pattern_formula_validation(5000, [20 25 30])

if nargin < 1 || isempty(num_frames)
    num_frames = 1000;
end
if nargin < 2 || isempty(ebn0_db)
    ebn0_db = 20:5:30;
end
validateattributes(num_frames, {'numeric'}, {'scalar', 'integer', 'positive'});

clc;
project_dir = fileparts(mfilename('fullpath'));
addpath(genpath(project_dir));
rng(2032);

base_cfg = config_full_grid_otfs_im();
base_cfg.EbN0_dB = ebn0_db(:).';
base_cfg.N_fram = num_frames;
base_cfg.mp_iterations = 10;
base_cfg.mp_damping = 0.60;
base_cfg.enable_local_support_refinement = false;
cfg = build_full_grid_variant(base_cfg, 'OTFS-IM NBC 16-QAM', ...
    qammod(0:15, 16), base_cfg.K_active);

results_dir = fullfile(project_dir, cfg.results_dir);
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end
run_tag = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
console_file = fullfile(results_dir, ...
    ['mp_bg_formula_validation_' run_tag '.txt']);
diary(console_file);

num_snr = numel(cfg.EbN0_dB);
num_bg_samples = 200000; % Tich phan so hoc cua (11), (12), (15).
result = struct();
result.ebn0_db = cfg.EbN0_dB(:);
result.num_frames = num_frames;
result.num_bg_samples = num_bg_samples;
result.direct_pattern_error = zeros(num_snr, 1);
result.bg_formula_pattern_error = zeros(num_snr, 1);
result.relative_error = zeros(num_snr, 1);
result.p_active_bg = zeros(num_snr, 1);
result.nu_active_bg = zeros(num_snr, 1);
result.p_inactive_bg = zeros(num_snr, 1);
result.nu_inactive_bg = zeros(num_snr, 1);
result.posterior_sum_error = zeros(num_snr, 1);

alphabet = cfg.data_alphabet(:);
num_symbols = cfg.M_mod_im;
rho = cfg.K_active / cfg.N_grid;
symbol_prior = [repmat(rho / num_symbols, 1, num_symbols), 1-rho];

fprintf('\nBG FORMULA VALIDATION: 16-QAM OTFS-IM, Ngrid=%d, K=%d\n', ...
    cfg.N_grid, cfg.K_active);
fprintf('MP: %d iterations, damping %.2f, %d frames/SNR\n', ...
    cfg.mp_iterations, cfg.mp_damping, num_frames);
fprintf('Formula: BG parameters -> F_X, F_Z -> equation (15).\n');
fprintf('Numerical samples for equation (15): %d per SNR.\n', num_bg_samples);
fprintf('====================================================================================================\n');
fprintf(' Eb/N0 | Simulated Ppat | BG formula Ppat | Relative error | p_A | nu_A | p_0 | nu_0\n');
fprintf('----------------------------------------------------------------------------------------------------\n');

for isnr = 1:num_snr
    residual_active = zeros(num_frames * cfg.K_active, 1);
    residual_inactive = zeros(num_frames * (cfg.N_grid-cfg.K_active), 1);
    active_offset = 0;
    inactive_offset = 0;
    wrong_patterns = 0;
    posterior_sum_error = 0;

    for iframe = 1:num_frames
        % Tao pattern NBC va 16-QAM dung nhu he mo phong chinh.
        rank_bits = randi([0, 1], cfg.b_index, 1);
        active_tx = combination_unrank_bits(rank_bits, cfg.N_grid, ...
            cfg.K_active, get_binom_table(cfg));
        active_mask = false(cfg.N_grid, 1);
        active_mask(active_tx) = true;
        symbol_indices = randi([0, num_symbols-1], cfg.K_active, 1);
        x_true = zeros(cfg.N_grid, 1);
        tx_labels = pattern_symbol_labels(active_tx, cfg.N_grid, cfg.K_active);
        x_true(active_tx) = alphabet(symbol_indices(tx_labels) + 1);

        x_tx = x_true * cfg.power_scale_im;
        [taps, delays, dopplers, coefficients] = OTFS_channel_gen(cfg.N, cfg.M);
        tx_time = OTFS_modulation(cfg.N, cfg.M, reshape(x_tx, cfg.N, cfg.M));
        rx_time = OTFS_channel_output(cfg.N, cfg.M, taps, delays, dopplers, ...
            coefficients, cfg.sigma_2_im(isnr), tx_time);
        y = OTFS_demodulation(cfg.N, cfg.M, rx_time);

        % y_tilde la dau ra mem cua MP: ky vong cua symbol tai tung o.
        y_norm = y / cfg.power_scale_im;
        sigma_norm = cfg.sigma_2_im(isnr) / cfg.power_scale_im^2;
        [~, posterior] = OTFS_mp_detector(cfg.N, cfg.M, [alphabet.' 0], ...
            symbol_prior, taps, delays, dopplers, coefficients, ...
            sigma_norm, y_norm, cfg);
        posterior_sum_error = max(posterior_sum_error, ...
            max(abs(sum(posterior, 2)-1)));
        y_tilde = posterior(:, 1:num_symbols) * alphabet;
        w_mp = y_tilde - x_true;

        % P(active) cua MP va quy tac Top-K dung nhu may thu chinh.
        p_active = sum(posterior(:, 1:num_symbols), 2);
        [~, order] = sort(p_active, 'descend');
        active_rx = sort(order(1:cfg.K_active));
        wrong_patterns = wrong_patterns + ~isequal(active_tx(:), active_rx(:));

        active_indices = active_offset + (1:cfg.K_active);
        inactive_indices = inactive_offset + (1:(cfg.N_grid-cfg.K_active));
        residual_active(active_indices) = w_mp(active_mask);
        residual_inactive(inactive_indices) = w_mp(~active_mask);
        active_offset = active_offset + cfg.K_active;
        inactive_offset = inactive_offset + (cfg.N_grid-cfg.K_active);
    end

    % Uoc luong tham so cua (4), (5) tu output MP thuc te.
    active_fit = fit_pure_bg(residual_active);
    inactive_fit = fit_pure_bg(residual_inactive);
    bg_parameters = struct('p_A', active_fit.p, 'nu_A', active_fit.nu, ...
        'p_0', inactive_fit.p, 'nu_0', inactive_fit.nu, 'rho', rho);

    % Tinh F_X, F_Z theo (11), (12), roi dung (15).
    formula_error = calculate_bg_pattern_formula(alphabet, bg_parameters, ...
        cfg.K_active, cfg.N_grid-cfg.K_active, num_bg_samples);
    direct_error = wrong_patterns / num_frames;

    result.direct_pattern_error(isnr) = direct_error;
    result.bg_formula_pattern_error(isnr) = formula_error;
    result.relative_error(isnr) = abs(formula_error-direct_error) / ...
        max(direct_error, 1/num_frames);
    result.p_active_bg(isnr) = active_fit.p;
    result.nu_active_bg(isnr) = active_fit.nu;
    result.p_inactive_bg(isnr) = inactive_fit.p;
    result.nu_inactive_bg(isnr) = inactive_fit.nu;
    result.posterior_sum_error(isnr) = posterior_sum_error;

    fprintf(' %5.1f |   %10.4e |    %10.4e |    %8.2f %% | %.3f | %.3e | %.3f | %.3e\n', ...
        cfg.EbN0_dB(isnr), direct_error, formula_error, ...
        100*result.relative_error(isnr), active_fit.p, active_fit.nu, ...
        inactive_fit.p, inactive_fit.nu);
end

fprintf('====================================================================================================\n');
fprintf('Ppat simulated: support Top-K sai trong mo phong OTFS-IM.\n');
fprintf('Ppat BG formula: tinh tu cac phuong trinh (4)--(15) cua ban bao cao.\n');
fprintf('Luu y: cong thuc (15) van co gia dinh doc lap giua cac diem sau MP.\n');
fprintf('Max posterior row-sum error: %.3e\n', max(result.posterior_sum_error));

result.cfg = cfg;
mat_file = fullfile(results_dir, ['mp_bg_formula_validation_' run_tag '.mat']);
png_file = fullfile(results_dir, ['mp_bg_formula_validation_' run_tag '.png']);
save(mat_file, 'result');
save(fullfile(results_dir, 'mp_bg_formula_validation_latest.mat'), 'result');

fig = figure('Color', 'w', 'Name', 'BG formula validation');
semilogy(cfg.EbN0_dB, max(result.direct_pattern_error, 1/(2*num_frames)), ...
    '-o', 'LineWidth', 1.8, 'MarkerSize', 7); hold on;
semilogy(cfg.EbN0_dB, max(result.bg_formula_pattern_error, 1/(2*num_frames)), ...
    '--s', 'LineWidth', 1.8, 'MarkerSize', 7);
grid on; box on;
xlabel('E_b/N_0 (dB)'); ylabel('P_{pattern}');
title(sprintf('Kiem chung cong thuc (15): N=%d, K=%d', cfg.N_grid, cfg.K_active));
legend('Mo phong OTFS-IM: MP + Top-K', 'Cong thuc BG (4)--(15)', ...
    'Location', 'southwest');
saveas(fig, png_file);
saveas(fig, fullfile(results_dir, 'mp_bg_formula_validation_latest.png'));
fprintf('Saved data   : %s\n', mat_file);
fprintf('Saved figure : %s\n', png_file);
fprintf('Saved table  : %s\n', console_file);
diary off;
copyfile(console_file, fullfile(results_dir, ...
    'mp_bg_formula_validation_latest.txt'));
end

function pattern_error = calculate_bg_pattern_formula(alphabet, parameters, k, n_zero, num_samples)
% Tinh so hoc cong thuc (15). X va Z duoc sinh dung tu PDF (11), (12).
% Khoi luong delta tai 1 va 0 duoc giu dung theo Bernoulli-Gaussian.

x_scores = draw_bg_activity_scores(alphabet, parameters, true, num_samples);
z_scores = draw_bg_activity_scores(alphabet, parameters, false, num_samples);
x_scores = sort(x_scores);
z_scores = sort(z_scores);
[z_values, ~, group] = unique(z_scores);
counts = accumarray(group, 1);
fz_previous = [0; cumsum(counts(1:end-1))] / num_samples;
fz_current = cumsum(counts) / num_samples;
prob_zmax = fz_current.^n_zero - fz_previous.^n_zero;
fx = arrayfun(@(z) sum(x_scores <= z) / num_samples, z_values);
fxmin = 1-(1-fx).^k;
pattern_error = sum(fxmin .* prob_zmax);
end

function scores = draw_bg_activity_scores(alphabet, parameters, is_active, num_samples)
% Sinh output MP tu PDF cua y_tilde roi tinh P(x_i ~= 0 | y_tilde).
num_symbols = numel(alphabet);
if is_active
    impulse = rand(num_samples, 1) < parameters.p_A;
    symbol_index = randi(num_symbols, num_samples, 1);
    y = alphabet(symbol_index);
    y(impulse) = y(impulse) + sqrt(parameters.nu_A/2) * ...
        (randn(sum(impulse), 1) + 1i*randn(sum(impulse), 1));
    scores = zeros(num_samples, 1);
    % Khi w_MP=0, y=s_q va state active co khoi luong delta nen P(active)=1.
    scores(~impulse) = 1;
    scores(impulse) = activity_probability_bg(y(impulse), alphabet, parameters);
else
    impulse = rand(num_samples, 1) < parameters.p_0;
    y = zeros(num_samples, 1);
    y(impulse) = sqrt(parameters.nu_0/2) * ...
        (randn(sum(impulse), 1) + 1i*randn(sum(impulse), 1));
    scores = zeros(num_samples, 1);
    % Khi w_MP=0, y=0 va state inactive co khoi luong delta nen P(active)=0.
    scores(impulse) = activity_probability_bg(y(impulse), alphabet, parameters);
end
scores = min(max(real(scores), 0), 1);
end

function probability = activity_probability_bg(y, alphabet, parameters)
% Cong thuc (10) tai nhung diem lien tuc: p*f_A/(p*f_A+(1-p)*f_0).
y = y(:);
nu_a = max(parameters.nu_A, 1e-12);
nu_0 = max(parameters.nu_0, 1e-12);
distance_a = abs(y - alphabet.').^2;
gaussian_a = exp(-distance_a/nu_a) / (pi*nu_a);
f_a = parameters.p_A * mean(gaussian_a, 2);
f_0 = parameters.p_0 * exp(-abs(y).^2/nu_0) / (pi*nu_0);
numerator = parameters.rho * f_a;
probability = numerator ./ max(numerator + (1-parameters.rho)*f_0, 1e-300);
end

function table = get_binom_table(cfg)
% Chi luu bang he so to hop, khong luu toan bo pattern.
persistent cached_table cached_n cached_width
bit_width = cfg.b_index + 1;
if isempty(cached_table) || cached_n ~= cfg.N_grid || cached_width ~= bit_width
    cached_table = build_binomial_bit_table(cfg.N_grid, bit_width);
    cached_n = cfg.N_grid;
    cached_width = bit_width;
end
table = cached_table;
end

function fit = fit_pure_bg(samples)
% Uoc luong e=cg, c la Bernoulli va g~CN(0,nu), bang EM hai trang thai.
samples = samples(:);
r2 = abs(samples).^2;
epsilon = 1e-12;
p = 0.5;
nu_zero = max(median(r2)/100, epsilon);
nu = max(mean(r2), 10*nu_zero);
for iteration = 1:150
    log_zero = log(max(1-p, epsilon)) - log(pi*nu_zero) - r2/nu_zero;
    log_nonzero = log(max(p, epsilon)) - log(pi*nu) - r2/nu;
    maximum = max(log_zero, log_nonzero);
    weight = exp(log_nonzero-maximum) ./ ...
        (exp(log_zero-maximum) + exp(log_nonzero-maximum));
    p = min(max(mean(weight), 1e-6), 1-1e-6);
    nu_zero = max(sum((1-weight).*r2) / max(sum(1-weight), epsilon), epsilon);
    nu = max(sum(weight.*r2) / max(sum(weight), epsilon), epsilon);
    if nu < nu_zero
        temporary = nu;
        nu = nu_zero;
        nu_zero = temporary;
        p = 1-p;
    end
end
fit.p = p;
fit.nu = nu;
fit.nu_zero = nu_zero;
end
