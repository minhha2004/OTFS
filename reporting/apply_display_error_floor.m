% Evaluation role: optional plotting utility for zero-error Monte Carlo
% points. It makes semilog figures readable without claiming true BER is zero.
function result = apply_display_error_floor(cfg, result, result_type, num_frames)
% Applies Monte Carlo display floors to zero-valued error-rate fields.
% This prevents semilogy plots from dropping to zero while preserving a
% defensible upper-bound-style value based on the simulated sample count.

if isempty(result)
    return;
end

switch result_type
    case 'ofdm'
        result.ber_ofdm = floor_zero_values(result.ber_ofdm, 1/(cfg.total_bits_otfs*num_frames));

    case 'otfs'
        result.ber_otfs = floor_zero_values(result.ber_otfs, 1/(cfg.total_bits_otfs*num_frames));

    case 'im'
        result.ber_im = floor_zero_values(result.ber_im, 1/(cfg.lambda*num_frames));
        result.ber_idx = floor_zero_values(result.ber_idx, 1/(cfg.g*cfg.b1*num_frames));
        result.ber_sym = floor_zero_values(result.ber_sym, 1/(cfg.g*cfg.b2*num_frames));
        result.per_pattern = floor_zero_values(result.per_pattern, 1/(cfg.g*num_frames));

    case 'random'
        if ~isfield(result, 'applicable') || ~result.applicable
            return;
        end

        avg_frames = num_frames * cfg.num_random_tables;
        result.ber_im_avg = floor_zero_values(result.ber_im_avg, 1/(cfg.lambda*avg_frames));
        result.ber_idx_avg = floor_zero_values(result.ber_idx_avg, 1/(cfg.g*cfg.b1*avg_frames));
        result.ber_sym_avg = floor_zero_values(result.ber_sym_avg, 1/(cfg.g*cfg.b2*avg_frames));
        result.per_pattern_avg = floor_zero_values(result.per_pattern_avg, 1/(cfg.g*avg_frames));
        result.ber_im_best = floor_zero_values(result.ber_im_best, 1/(cfg.lambda*num_frames));
        result.ber_idx_best = floor_zero_values(result.ber_idx_best, 1/(cfg.g*cfg.b1*num_frames));
        result.ber_sym_best = floor_zero_values(result.ber_sym_best, 1/(cfg.g*cfg.b2*num_frames));
        result.per_pattern_best = floor_zero_values(result.per_pattern_best, 1/(cfg.g*num_frames));
end
end

function values = floor_zero_values(values, floor_value)
values(values == 0) = floor_value;
end
