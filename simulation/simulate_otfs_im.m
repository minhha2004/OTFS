% Evaluation role: core OTFS-IM simulation. It produces total BER plus
% index BER, symbol BER, pattern error rate, and true-pattern rank so the
% thesis can explain why OHD affects performance.
function result = simulate_otfs_im(cfg, MAP_TABLE)
% Runs the OTFS-IM Monte Carlo simulation for one supplied pattern table.
% It also computes index-detector diagnostics: pattern error rate,
% and true-pattern rank.

err_im = zeros(length(cfg.EbN0_dB), 1);
err_idx_bits = zeros(length(cfg.EbN0_dB), 1);
err_sym_bits = zeros(length(cfg.EbN0_dB), 1);
err_pattern = zeros(length(cfg.EbN0_dB), 1);
rank_sum = zeros(length(cfg.EbN0_dB), 1);
frames_used = zeros(length(cfg.EbN0_dB), 1);
symbol_combos = symbol_index_combinations(cfg.M_mod_im, cfg.k);

for iesn0 = 1:length(cfg.EbN0_dB)
    target_frames = get_target_frames(cfg);

    for ifram = 1:target_frames
        bits_im = randi([0,1], cfg.lambda, 1);
        x_vec = zeros(cfg.N_total, 1);
        ptr = 1;
        tx_pattern_idx = zeros(cfg.g, 1);

        for ib = 1:cfg.g
            bin_idx = bi2de(bits_im(ptr:ptr+cfg.b1-1).', 'left-msb');
            m_tx = bitxor(bin_idx, floor(bin_idx/2));
            pos = MAP_TABLE(m_tx + 1, :);
            tx_pattern_idx(ib) = m_tx;
            s_qam = qammod(bi2de(reshape(bits_im(ptr+cfg.b1:ptr+cfg.b1+cfg.b2-1), cfg.M_bits_im, []).', 'left-msb'), cfg.M_mod_im) * cfg.alpha;
            x_vec((ib-1)*cfg.n + pos) = s_qam;
            ptr = ptr + cfg.b1 + cfg.b2;
        end

        [t, d, Dop, c] = OTFS_channel_gen(cfg.N, cfg.M);
        s_im = OTFS_modulation(cfg.N, cfg.M, reshape(x_vec, cfg.N, cfg.M));
        r_im = OTFS_channel_output(cfg.N, cfg.M, t, d, Dop, c, cfg.sigma_2_im(iesn0), s_im);
        y_im = OTFS_demodulation(cfg.N, cfg.M, r_im);
        y_norm = y_im / cfg.alpha;
        sigma_norm = cfg.sigma_2_im(iesn0) / (cfg.alpha^2);
        [~, sum_prob] = OTFS_mp_detector(cfg.N, cfg.M, cfg.M_mod_im, t, d, Dop, c, sigma_norm, y_norm);
        bits_rx = zeros(cfg.lambda, 1);
        rx_p = 1;

        for ib = 1:cfg.g
            idx_blk = (ib-1)*cfg.n + (1:cfg.n);
            p_zero = max(sum_prob(idx_blk, cfg.M_mod_im+1), 1e-15);
            p_symbol = max(sum_prob(idx_blk, 1:cfg.M_mod_im), 1e-15);
            score = zeros(2^cfg.b1, 1);
            best_symbol_idx = zeros(2^cfg.b1, cfg.k);

            for mc = 1:2^cfg.b1
                pat = MAP_TABLE(mc, :);
                inactive = setdiff(1:cfg.n, pat);
                inactive_score = sum(log(p_zero(inactive)));
                combo_score = zeros(size(symbol_combos, 1), 1);

                for icombo = 1:size(symbol_combos, 1)
                    active_score = 0;
                    for iactive = 1:cfg.k
                        active_score = active_score + log(p_symbol(pat(iactive), symbol_combos(icombo, iactive) + 1));
                    end
                    combo_score(icombo) = inactive_score + active_score;
                end

                [score(mc), best_combo_idx] = max(combo_score);
                best_symbol_idx(mc, :) = symbol_combos(best_combo_idx, :);
            end

            [~, b_m] = max(score);
            b_m = b_m - 1;
            b_idx_tx = bits_im(rx_p:rx_p+cfg.b1-1);
            b_idx_rx = de2bi(gray_to_bin_idx(b_m), cfg.b1, 'left-msb').';
            b_sym_tx = bits_im(rx_p+cfg.b1:rx_p+cfg.b1+cfg.b2-1);
            b_sym_rx = reshape(de2bi(best_symbol_idx(b_m + 1, :), cfg.M_bits_im, 'left-msb').', [], 1);

            err_idx_bits(iesn0) = err_idx_bits(iesn0) + sum(xor(b_idx_tx, b_idx_rx));
            err_sym_bits(iesn0) = err_sym_bits(iesn0) + sum(xor(b_sym_tx, b_sym_rx));
            err_pattern(iesn0) = err_pattern(iesn0) + (b_m ~= tx_pattern_idx(ib));

            [~, rank_order] = sort(score, 'descend');
            true_rank = find(rank_order == tx_pattern_idx(ib) + 1, 1);
            rank_sum(iesn0) = rank_sum(iesn0) + true_rank;

            bits_rx(rx_p:rx_p+cfg.b1-1) = b_idx_rx;
            bits_rx(rx_p+cfg.b1:rx_p+cfg.b1+cfg.b2-1) = b_sym_rx;
            rx_p = rx_p + cfg.b1 + cfg.b2;
        end

        err_im(iesn0) = sum(xor(bits_im, bits_rx)) + err_im(iesn0);
        frames_used(iesn0) = ifram;

        if should_stop_adaptive(cfg, ifram, err_im(iesn0))
            break;
        end
    end
end

result.err_im = err_im;
result.err_idx_bits = err_idx_bits;
result.err_sym_bits = err_sym_bits;
result.err_pattern = err_pattern;
result.rank_sum = rank_sum;
result.frames_used = frames_used;
result.ber_im = err_im ./ (cfg.lambda * frames_used);
result.ber_idx = err_idx_bits ./ (cfg.g * cfg.b1 * frames_used);
result.ber_sym = err_sym_bits ./ (cfg.g * cfg.b2 * frames_used);
result.per_pattern = err_pattern ./ (cfg.g * frames_used);
result.avg_true_rank = rank_sum ./ (cfg.g * frames_used);
end

function target_frames = get_target_frames(cfg)
if isfield(cfg, 'use_adaptive_frames') && cfg.use_adaptive_frames
    target_frames = cfg.max_frames_per_snr;
else
    target_frames = cfg.N_fram;
end
end

function tf = should_stop_adaptive(cfg, frames_done, error_count)
tf = false;
if ~isfield(cfg, 'use_adaptive_frames') || ~cfg.use_adaptive_frames
    return;
end

tf = frames_done >= cfg.min_frames_per_snr && error_count >= cfg.target_bit_errors;
end

function combos = symbol_index_combinations(M_mod, k)
% Enumerates all k-symbol index combinations for block-wise MAP detection.

num_combos = M_mod^k;
combos = zeros(num_combos, k);

for icombo = 0:num_combos-1
    value = icombo;
    for ipos = k:-1:1
        combos(icombo + 1, ipos) = mod(value, M_mod);
        value = floor(value / M_mod);
    end
end
end
