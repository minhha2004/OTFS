clc; clear; close all; tic;
%% =========================================================================
%  1. SYSTEM PARAMETERS & INITIALIZATION
% =========================================================================
N = 10;                     % Number of Doppler bins
M = 12;                     % Number of Delay bins
N_total = N * M;            % Total resource elements per frame
rng(1);                     % Set random seed
N_fram = 1000;               % Number of simulated frames
EbN0_dB = 5:5:30;           % E_b/N_0 range
% --- Baseline OTFS Configuration ---
M_mod_otfs = 4;             % 4-QAM
M_bits_otfs = log2(M_mod_otfs);
total_bits_otfs = N_total * M_bits_otfs; 
se_otfs = total_bits_otfs / N_total;      % SE: 2.0 bits/symbol
% --- OTFS-IM Configuration (n=6, k=3) ---
n = 6;                      % Sub-carriers per block
g = N_total / n;            % g = 20 blocks
k = 3;                      % Active sub-carriers
b1 = floor(log2(nchoosek(n, k)));         % Index bits (4 bits)
M_mod_im = 4;               % 4-QAM for active symbols
M_bits_im = log2(M_mod_im); 
b2 = k * M_bits_im;                       % Symbol bits (6 bits)
lambda = g * (b1 + b2);                   % Total bits (200 bits)
se_im = lambda / N_total;                 % SE: 1.67 bits/symbol
alpha = sqrt(n/k);                        % Power scaling factor
%% =========================================================================
%  2. NOISE POWER CALCULATION
% =========================================================================
EsN0_otfs_dB = EbN0_dB + 10*log10(se_otfs);
EsN0_im_dB   = EbN0_dB + 10*log10(se_im);
eng_sqrt = sqrt((M_mod_otfs-1)/6*(2^2)); 
sigma_2_otfs = abs(eng_sqrt * sqrt(1./ (10.^(EsN0_otfs_dB/10)))).^2;
sigma_2_im   = abs(eng_sqrt * sqrt(1./ (10.^(EsN0_im_dB/10)))).^2;

USE_RANDOM_PATTERN = false;
%% =========================================================================
%  3. OPTIMAL HAMMING DISTANCE PATTERN SELECTION (OHD-PS)
% =========================================================================

ALL_PATS = nchoosek(1:n,k);

num_total_pats = size(ALL_PATS,1);
num_selected_pats = 2^b1;

BIN_PATS = zeros(num_total_pats,n);

for i = 1:num_total_pats
    BIN_PATS(i,ALL_PATS(i,:)) = 1;
end

D = zeros(num_total_pats);

for i = 1:num_total_pats
    for j = i+1:num_total_pats
        D(i,j) = sum(xor(BIN_PATS(i,:),BIN_PATS(j,:)));
        D(j,i) = D(i,j);
    end
end

all_sets = nchoosek(1:num_total_pats,num_selected_pats);

best_dmin = -inf;
best_set = [];

for s = 1:size(all_sets,1)

    candidate = all_sets(s,:);

    dmin = inf;

    for i = 1:length(candidate)-1
        for j = i+1:length(candidate)
            dmin = min(dmin,D(candidate(i),candidate(j)));
        end
    end

    if dmin > best_dmin
        best_dmin = dmin;
        best_set = candidate;
    end

end

%added
if USE_RANDOM_PATTERN

    rng(100);

    idx_rand = randperm(num_total_pats,num_selected_pats);

    MAP_TABLE = ALL_PATS(idx_rand,:);

    fprintf('Random Pattern Selection\n');

else

    MAP_TABLE = ALL_PATS(best_set,:);

    fprintf('Optimal Hamming Distance Pattern Set Found\n');
    fprintf('Minimum Hamming Distance = %d\n',best_dmin);

end

disp('Selected Pattern Table:')
disp(MAP_TABLE)
dist_list = [];

for i = 1:size(MAP_TABLE,1)-1
    for j = i+1:size(MAP_TABLE,1)

        d = sum(xor( ...
            BIN_PATS(best_set(i),:), ...
            BIN_PATS(best_set(j),:) ));

        dist_list = [dist_list d];

    end
end

fprintf('\n');
fprintf('Minimum HD = %.2f\n',min(dist_list));
fprintf('Average HD = %.2f\n',mean(dist_list));
fprintf('Maximum HD = %.2f\n',max(dist_list));
fprintf('\n');
%% =========================================================================
%  4. BASELINE OTFS SIMULATION
% =========================================================================
err_otfs = zeros(length(EbN0_dB),1);
for iesn0 = 1:length(EbN0_dB)
    for ifram = 1:N_fram
        bits = randi([0,1], total_bits_otfs, 1);
        x = qammod(bi2de(reshape(bits, N_total, M_bits_otfs)), M_mod_otfs);
        [t, d, Dop, c] = OTFS_channel_gen(N, M);
        s = OTFS_modulation(N, M, reshape(x, N, M));
        r = OTFS_channel_output(N, M, t, d, Dop, c, sigma_2_otfs(iesn0), s);
        y = OTFS_demodulation(N, M, r);
        x_est = OTFS_mp_detector(N, M, M_mod_otfs, t, d, Dop, c, sigma_2_otfs(iesn0), y);
        bits_est = reshape(de2bi(qamdemod(x_est, M_mod_otfs), M_bits_otfs), [], 1);
        err_otfs(iesn0) = sum(xor(bits, bits_est)) + err_otfs(iesn0);
    end
end
ber_otfs = err_otfs / (total_bits_otfs * N_fram);
%% =========================================================================
%  5. OTFS-IM SIMULATION (TRUE LLR DETECTOR WITH RELIABILITY SCALING)
% =========================================================================
err_im = zeros(length(EbN0_dB),1);
err_idx_bits = zeros(length(EbN0_dB),1);
err_sym_bits = zeros(length(EbN0_dB),1);
for iesn0 = 1:length(EbN0_dB)
    for ifram = 1:N_fram
        bits_im = randi([0,1], lambda, 1);
        x_vec = zeros(N_total, 1); ptr = 1;
        for ib = 1:g
            %m_tx = bi2de(bits_im(ptr:ptr+b1-1).', 'left-msb');
            bin_idx = bi2de(bits_im(ptr:ptr+b1-1).','left-msb');

            m_tx = bitxor(bin_idx,floor(bin_idx/2));
            pos = MAP_TABLE(m_tx + 1, :);
            s_qam = qammod(bi2de(reshape(bits_im(ptr+b1:ptr+b1+b2-1), M_bits_im, []).', 'left-msb'), M_mod_im) * alpha;
            x_vec((ib-1)*n + pos) = s_qam; 
            ptr = ptr + b1 + b2;
        end
        [t, d, Dop, c] = OTFS_channel_gen(N, M);
        s_im = OTFS_modulation(N, M, reshape(x_vec, N, M));
        r_im = OTFS_channel_output(N, M, t, d, Dop, c, sigma_2_im(iesn0), s_im);
        y_im = OTFS_demodulation(N, M, r_im);
        y_norm = y_im / alpha;
        sigma_norm = sigma_2_im(iesn0) / (alpha^2);
        [x_mp, sum_prob] = OTFS_mp_detector(N, M, M_mod_im, t, d, Dop, c, sigma_norm, y_norm);
        bits_rx = zeros(lambda, 1); rx_p = 1;
        for ib = 1:g
            idx_blk = (ib-1)*n + (1:n);
            p_zero = max(sum_prob(idx_blk, M_mod_im+1), 1e-15);
            p_active = max(1 - p_zero, 1e-15);
            score = zeros(2^b1, 1);

            reliability = abs(p_active - 0.5);
            for mc = 1:2^b1
                pat = MAP_TABLE(mc, :);
                inactive = setdiff(1:n, pat);
                score(mc) = sum(reliability(pat).*log(p_active(pat))) + sum(reliability(inactive).*log(p_zero(inactive)));
            end
            [~, b_m] = max(score); b_m = b_m - 1;
            pos_h = MAP_TABLE(b_m + 1, :);
            b_idx_tx = bits_im(rx_p:rx_p+b1-1);
            %b_idx_rx = de2bi(b_m, b1, 'left-msb').';
            gray = b_m;

            bin = gray;
            
            while any(bitshift(gray,-1))
                gray = bitshift(gray,-1);
                bin = bitxor(bin,gray);
            end
            
            b_idx_rx = de2bi(bin,b1,'left-msb').';
            b_sym_tx = bits_im(rx_p+b1:rx_p+b1+b2-1);
            b_sym_rx = reshape(de2bi(qamdemod(x_mp(idx_blk(pos_h)), M_mod_im), M_bits_im, 'left-msb').', [], 1);
            err_idx_bits(iesn0) = err_idx_bits(iesn0) + sum(xor(b_idx_tx, b_idx_rx));
            err_sym_bits(iesn0) = err_sym_bits(iesn0) + sum(xor(b_sym_tx, b_sym_rx));
            bits_rx(rx_p:rx_p+b1-1) = b_idx_rx;
            bits_rx(rx_p+b1:rx_p+b1+b2-1) = b_sym_rx;
            rx_p = rx_p + b1 + b2;
        end
        err_im(iesn0) = sum(xor(bits_im, bits_rx)) + err_im(iesn0);
    end
end
ber_im = err_im / (lambda * N_fram);
ber_idx = err_idx_bits / (g * b1 * N_fram); 
ber_sym = err_sym_bits / (g * b2 * N_fram); 
%% =========================================================================
%  6. RESULTS & VISUALIZATION
% =========================================================================
fprintf('\n========================================================\n');
fprintf('                SPECTRAL EFFICIENCY ANALYSIS            \n');
fprintf('========================================================\n');
fprintf('Baseline OTFS SE: %.2f bits/symbol\n', se_otfs);
fprintf('OTFS-IM SE (n=%d, k=%d): %.2f bits/symbol\n', n, k, se_im);
fprintf('Reduction: %.1f%%\n', (1 - se_im/se_otfs)*100);
fprintf('\n====================================================================\n');
fprintf('Eb/N0 | BER OTFS | BER IM Total | BER Index | BER Symbol\n');
for i = 1:length(EbN0_dB)
    fprintf('%5d | %8.5f | %12.5f | %9.5f | %10.5f\n', ...
        EbN0_dB(i), ber_otfs(i), ber_im(i), ber_idx(i), ber_sym(i));
end

fprintf('\nEb/N0 | BER Index | BER Symbol | Ratio(Index/Symbol)\n');
for i = 1:length(EbN0_dB)
    fprintf('%5d | %9.5f | %10.5f | %8.2f\n', ...
        EbN0_dB(i), ...
        ber_idx(i), ...
        ber_sym(i), ...
        ber_idx(i)/max(ber_sym(i),1e-10));
end
figure('Color', 'w');

semilogy(EbN0_dB, ber_otfs, '-ks', 'LineWidth', 1.5);
hold on;

semilogy(EbN0_dB, ber_im, '-ro', 'LineWidth', 1.5);

semilogy(EbN0_dB, ber_idx, '--b^', 'LineWidth', 1.2);
semilogy(EbN0_dB, ber_sym, '--mv', 'LineWidth', 1.2);

grid on;
xlabel('Eb/N0 (dB)');
ylabel('BER');

legend('OTFS', ...
       'OTFS-IM', ...
       'Index Error', ...
       'Symbol Error');