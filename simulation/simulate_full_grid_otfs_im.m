function result = simulate_full_grid_otfs_im(cfg)
% SIMULATE_FULL_GRID_OTFS_IM mô phỏng một nhánh full-grid OTFS-IM.
% Đổi bit index thành K vị trí active bằng NBC, không lưu LUT pattern.
% Điều chế bit symbol và đặt symbol vào các vị trí active.
% Điều chế OTFS, truyền qua kênh và giải điều chế OTFS.
% MP trả xác suất symbol/zero tại cả 120 vị trí.
% Chọn K vị trí có điểm active lớn nhất.
% Nếu bật refinement, thử đổi một hoặc hai vị trí đang nghi ngờ.
% Đổi pattern thu về bit index, giải bit symbol và tính các BER.

data_alphabet = cfg.data_alphabet;

num_snr = numel(cfg.EbN0_dB);
err_index = zeros(num_snr, 1);
err_symbol = zeros(num_snr, 1);
err_total = zeros(num_snr, 1);
invalid_patterns = zeros(num_snr, 1);
support_errors = zeros(num_snr, 1);
support_swaps = zeros(num_snr, 1);
initial_support_errors = zeros(num_snr, 1);
initial_support_swaps = zeros(num_snr, 1);
initial_index_errors = zeros(num_snr, 1);
refinement_fixed = zeros(num_snr, 1);
refinement_broken = zeros(num_snr, 1);
refinement_improved = zeros(num_snr, 1);
refinement_worsened = zeros(num_snr, 1);
activity_margin_sum = zeros(num_snr, 1);
oracle_symbol_errors = zeros(num_snr, 1);
frames_used = zeros(num_snr, 1);

active_prior = cfg.K_active / cfg.N_grid;
% Xác suất ban đầu: một ô active với xác suất K/N, còn lại là ô zero.
symbol_prior = [repmat(active_prior / cfg.M_mod_im, 1, cfg.M_mod_im), ...
    1 - active_prior];
bit_width = cfg.b_index + 1;
persistent cached_table cached_n cached_width
% Chỉ lưu bảng hệ số tổ hợp C(n,k), không lưu danh sách các pattern.
if isempty(cached_table) || cached_n ~= cfg.N_grid || cached_width ~= bit_width
    cached_table = build_binomial_bit_table(cfg.N_grid, bit_width);
    cached_n = cfg.N_grid;
    cached_width = bit_width;
end
binom_table = cached_table;

for iesn0 = 1:num_snr
    for ifram = 1:cfg.N_fram
        % ----- Máy phát: tạo bit index và bit symbol -----
        rank_bits_tx = randi([0, 1], cfg.b_index, 1);
        index_bits_tx = rank_bits_tx;
        symbol_bits_tx = randi([0, 1], cfg.b_symbol, 1);

        % NBC biến bit index thành đúng K vị trí active trên toàn lưới.
        active_tx = combination_unrank_bits(rank_bits_tx, ...
            cfg.N_grid, cfg.K_active, binom_table);
        symbol_idx_tx = bi2de(reshape(symbol_bits_tx, ...
            cfg.M_bits_im, []).', 'left-msb');
        symbols_tx = reshape(data_alphabet(symbol_idx_tx + 1), [], 1) ...
            * cfg.power_scale_im;

        x_vec = zeros(cfg.N_grid, 1);
        % Quy tắc phụ thuộc pattern quyết định symbol logic nằm ở ô active nào.
        tx_labels = pattern_symbol_labels(active_tx, ...
            cfg.N_grid, cfg.K_active);
        x_vec(active_tx) = symbols_tx(tx_labels);

        [t, d, Dop, c] = OTFS_channel_gen(cfg.N, cfg.M);
        % ----- Chuỗi truyền OTFS qua kênh -----
        s = OTFS_modulation(cfg.N, cfg.M, reshape(x_vec, cfg.N, cfg.M));
        r = OTFS_channel_output(cfg.N, cfg.M, t, d, Dop, c, ...
            cfg.sigma_2_im(iesn0), s);
        y = OTFS_demodulation(cfg.N, cfg.M, r);

        y_norm = y / cfg.power_scale_im;
        % ----- Máy thu MP: tính xác suất symbol và zero cho từng ô -----
        sigma_norm = cfg.sigma_2_im(iesn0) / cfg.power_scale_im^2;
        im_alphabet = [data_alphabet, 0];
        [~, posterior] = OTFS_mp_detector(cfg.N, cfg.M, im_alphabet, symbol_prior, ...
            t, d, Dop, c, sigma_norm, y_norm, cfg);

        p_active = max(sum(posterior(:, 1:cfg.M_mod_im), 2), 1e-15);
        % Điểm active = log(P ô active) - log(P ô bằng zero).
        p_zero = max(posterior(:, cfg.M_mod_im + 1), 1e-15);
        activity_llr = log(p_active) - log(p_zero);
        [~, order] = sort(activity_llr, 'descend');
        active_rx = sort(order(1:cfg.K_active));
        % Chọn đúng K ô có điểm active cao nhất làm pattern ban đầu.

        active_mask_tx = false(cfg.N_grid, 1);
        active_mask_tx(active_tx) = true;
        initial_support_wrong = ~isequal(active_tx(:), active_rx(:));
        initial_swap_count = sum(~ismember(active_tx, active_rx));
        initial_support_errors(iesn0) = initial_support_errors(iesn0) ...
            + initial_support_wrong;
        initial_support_swaps(iesn0) = initial_support_swaps(iesn0) ...
            + initial_swap_count;
        [initial_rank_bits, initial_is_valid] = combination_rank_bits( ...
            active_rx, cfg.N_grid, cfg.K_active, cfg.b_index, binom_table);
        if ~initial_is_valid
            initial_rank_bits = zeros(cfg.b_index, 1);
        end
        initial_index_errors(iesn0) = initial_index_errors(iesn0) ...
            + sum(xor(index_bits_tx, initial_rank_bits));

        if cfg.enable_local_support_refinement
            % Thử sửa một/hai ô active sai bằng cách so sánh tín hiệu dư.
            active_rx = refine_support_by_residual(active_rx, activity_llr, ...
                posterior, data_alphabet, y_norm, cfg, t, d, Dop, c, ...
                binom_table);
        end

        final_support_wrong = ~isequal(active_tx(:), active_rx(:));
        final_swap_count = sum(~ismember(active_tx, active_rx));
        refinement_fixed(iesn0) = refinement_fixed(iesn0) ...
            + (initial_support_wrong && ~final_support_wrong);
        refinement_broken(iesn0) = refinement_broken(iesn0) ...
            + (~initial_support_wrong && final_support_wrong);
        refinement_improved(iesn0) = refinement_improved(iesn0) ...
            + (final_swap_count < initial_swap_count);
        refinement_worsened(iesn0) = refinement_worsened(iesn0) ...
            + (final_swap_count > initial_swap_count);

        activity_margin_sum(iesn0) = activity_margin_sum(iesn0) ...
            + min(activity_llr(active_tx)) - max(activity_llr(~active_mask_tx));
        support_swaps(iesn0) = support_swaps(iesn0) ...
            + final_swap_count;

        support_errors(iesn0) = support_errors(iesn0) ...
            + final_support_wrong;

        % NBC đổi K vị trí active máy thu tìm được trở lại bit index.
        [rank_bits_rx, is_valid] = combination_rank_bits(active_rx, ...
            cfg.N_grid, cfg.K_active, cfg.b_index, binom_table);
        if ~is_valid
            invalid_patterns(iesn0) = invalid_patterns(iesn0) + 1;
            index_bits_rx = zeros(cfg.b_index, 1);
        else
            index_bits_rx = rank_bits_rx;
        end

        [~, symbol_idx_rx] = max(posterior(active_rx, 1:cfg.M_mod_im), [], 2);
        % Tại mỗi ô active, chọn symbol có xác suất lớn nhất rồi khôi phục thứ tự.
        symbol_idx_rx = symbol_idx_rx - 1;
        rx_labels = pattern_symbol_labels(active_rx, ...
            cfg.N_grid, cfg.K_active);
        symbol_idx_logical = zeros(cfg.K_active, 1);
        symbol_idx_logical(rx_labels) = symbol_idx_rx;
        symbol_bits_rx = reshape(de2bi(symbol_idx_logical, ...
            cfg.M_bits_im, 'left-msb').', [], 1);

        % Phép thử oracle: dùng đúng pattern phát để đo riêng lỗi nhận symbol.
        [~, oracle_symbol_idx] = max( ...
            posterior(active_tx, 1:cfg.M_mod_im), [], 2);
        oracle_symbol_idx = oracle_symbol_idx - 1;
        oracle_symbol_logical = zeros(cfg.K_active, 1);
        oracle_symbol_logical(tx_labels) = oracle_symbol_idx;
        oracle_symbol_bits = reshape(de2bi(oracle_symbol_logical, ...
            cfg.M_bits_im, 'left-msb').', [], 1);
        oracle_symbol_errors(iesn0) = oracle_symbol_errors(iesn0) ...
            + sum(xor(symbol_bits_tx, oracle_symbol_bits));

        index_bit_errors = sum(xor(index_bits_tx, index_bits_rx));
        % Đếm riêng lỗi index, lỗi symbol và tổng lỗi của frame.
        symbol_bit_errors = sum(xor(symbol_bits_tx, symbol_bits_rx));
        err_index(iesn0) = err_index(iesn0) + index_bit_errors;
        err_symbol(iesn0) = err_symbol(iesn0) + symbol_bit_errors;
        err_total(iesn0) = err_total(iesn0) ...
            + index_bit_errors + symbol_bit_errors;
        frames_used(iesn0) = ifram;
    end
end

result.err_index = err_index;
result.err_symbol = err_symbol;
result.err_total = err_total;
result.frames_used = frames_used;
result.ber_index = err_index ./ (cfg.b_index * frames_used);
result.ber_symbol = err_symbol ./ (cfg.b_symbol * frames_used);
result.ber_total = err_total ./ (cfg.lambda * frames_used);
result.invalid_pattern_rate = invalid_patterns ./ frames_used;
result.support_error_rate = support_errors ./ frames_used;
result.avg_support_swaps = support_swaps ./ frames_used;
result.initial_index_ber = initial_index_errors ...
    ./ (cfg.b_index * frames_used);
result.initial_support_error_rate = initial_support_errors ./ frames_used;
result.initial_avg_support_swaps = initial_support_swaps ./ frames_used;
result.refinement_fixed = refinement_fixed;
result.refinement_broken = refinement_broken;
result.refinement_improved = refinement_improved;
result.refinement_worsened = refinement_worsened;
result.avg_activity_margin = activity_margin_sum ./ frames_used;
result.oracle_symbol_ber = oracle_symbol_errors ...
    ./ (cfg.b_symbol * frames_used);
result.name = cfg.name;
result.data_alphabet = data_alphabet;
end

function best_support = refine_support_by_residual(initial_support, activity_llr, ...
    posterior, alphabet, y_norm, cfg, taps, delays, dopplers, coefficients, ...
    binom_table)
% REFINE_SUPPORT_BY_RESIDUAL sửa các vị trí active mà MP còn phân vân.
% Bước 1: Lấy vài ô yếu nhất trong nhóm đã chọn và vài ô mạnh nhất ngoài nhóm.
% Bước 2: Tạo các pattern thử bằng cách đổi một hoặc hai cặp vị trí.
% Bước 3: Bỏ pattern không ánh xạ được về b_index bit hợp lệ.
% Bước 4: Dựng lại tín hiệu thu của từng pattern và chọn sai số nhỏ nhất.

active_mask = false(cfg.N_grid, 1);
active_mask(initial_support) = true;
active_positions = find(active_mask);
inactive_positions = find(~active_mask);
[~, weak_order] = sort(activity_llr(active_positions), 'ascend');
[~, strong_order] = sort(activity_llr(inactive_positions), 'descend');
boundary = min(cfg.refinement_boundary_size, ...
    min(numel(active_positions), numel(inactive_positions)));
weak_active = active_positions(weak_order(1:boundary));
strong_inactive = inactive_positions(strong_order(1:boundary));

best_support = initial_support;
best_score = support_residual(initial_support, posterior, alphabet, ...
    y_norm, cfg, taps, delays, dopplers, coefficients);

for i_active = 1:boundary
    for i_inactive = 1:boundary
        candidate = initial_support;
        candidate(candidate == weak_active(i_active)) = strong_inactive(i_inactive);
        candidate = sort(candidate);
        [~, is_valid] = combination_rank_bits(candidate, cfg.N_grid, ...
            cfg.K_active, cfg.b_index, binom_table);
        if ~is_valid
            continue;
        end
        score = support_residual(candidate, posterior, alphabet, ...
            y_norm, cfg, taps, delays, dopplers, coefficients);
        if score < best_score
            best_score = score;
            best_support = candidate;
        end
    end
end

if cfg.refinement_max_swaps >= 2 && boundary >= 2
    active_pairs = nchoosek(weak_active, 2);
    inactive_pairs = nchoosek(strong_inactive, 2);
    for i_active = 1:size(active_pairs, 1)
        for i_inactive = 1:size(inactive_pairs, 1)
            candidate = initial_support;
            candidate(ismember(candidate, active_pairs(i_active, :))) = [];
            candidate = sort([candidate(:); inactive_pairs(i_inactive, :).']);
            [~, is_valid] = combination_rank_bits(candidate, cfg.N_grid, ...
                cfg.K_active, cfg.b_index, binom_table);
            if ~is_valid
                continue;
            end
            score = support_residual(candidate, posterior, alphabet, ...
                y_norm, cfg, taps, delays, dopplers, coefficients);
            if score < best_score
                best_score = score;
                best_support = candidate;
            end
        end
    end
end
end

function score = support_residual(support, posterior, alphabet, y_norm, ...
    cfg, taps, delays, dopplers, coefficients)
% SUPPORT_RESIDUAL chấm điểm một pattern active đang được thử.
% Bước 1: Chọn symbol có xác suất lớn nhất tại các vị trí của pattern.
% Bước 2: Điều chế và truyền lại qua đúng kênh nhưng không cộng nhiễu.
% Bước 3: Tính độ lệch bình phương với tín hiệu thực; nhỏ hơn nghĩa là hợp lý hơn.

[~, symbol_indices] = max(posterior(support, 1:numel(alphabet)), [], 2);
x_candidate = zeros(cfg.N_grid, 1);
x_candidate(support) = alphabet(symbol_indices);
s_candidate = OTFS_modulation(cfg.N, cfg.M, ...
    reshape(x_candidate, cfg.N, cfg.M));
r_candidate = OTFS_channel_noiseless_output(cfg.N, cfg.M, taps, ...
    delays, dopplers, coefficients, s_candidate);
y_candidate = OTFS_demodulation(cfg.N, cfg.M, r_candidate);
residual = y_norm(:) - y_candidate(:);
score = real(residual' * residual);
end
