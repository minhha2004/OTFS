% Evaluation role: OFDM reference baseline for Chapter 5. This uses the same
% time-varying channel and a strong perfect-CSI full-frame LMMSE equalizer,
% so OTFS/OHD gains are compared against a meaningful OFDM benchmark.
function result = simulate_baseline_ofdm(cfg)
% Runs a conventional OFDM baseline over the same time-varying channel used
% by the OTFS simulations. The receiver uses a perfect-CSI full-frame LMMSE
% equalizer in the TF domain so Doppler-induced ICI is handled explicitly.

err_ofdm = zeros(length(cfg.EbN0_dB), 1);
frames_used = zeros(length(cfg.EbN0_dB), 1);

for iesn0 = 1:length(cfg.EbN0_dB)
    target_frames = get_target_frames(cfg);

    for ifram = 1:target_frames
        bits = randi([0,1], cfg.total_bits_otfs, 1);
        x = qammod(bi2de(reshape(bits, cfg.N_total, cfg.M_bits_otfs)), cfg.M_mod_otfs);
        x_tf = reshape(x, cfg.N, cfg.M);

        [t, d, Dop, c] = OTFS_channel_gen(cfg.N, cfg.M);
        s = OFDM_modulation(cfg.M, x_tf);
        r = OTFS_channel_output(cfg.N, cfg.M, t, d, Dop, c, cfg.sigma_2_otfs(iesn0), s);
        y_tf = OFDM_demodulation(cfg.N, cfg.M, r);
        H_tf = OFDM_effective_channel_matrix(cfg.N, cfg.M, t, d, Dop, c);
        y_vec = y_tf(:);
        x_est_vec = (H_tf' * H_tf + cfg.sigma_2_otfs(iesn0) * eye(cfg.N_total)) \ (H_tf' * y_vec);
        x_est_tf = reshape(x_est_vec, cfg.N, cfg.M);
        bits_est = reshape(de2bi(qamdemod(x_est_tf(:), cfg.M_mod_otfs), cfg.M_bits_otfs), [], 1);
        err_ofdm(iesn0) = err_ofdm(iesn0) + sum(xor(bits, bits_est));
        frames_used(iesn0) = ifram;

        if should_stop_adaptive(cfg, ifram, err_ofdm(iesn0))
            break;
        end
    end
end

result.err_ofdm = err_ofdm;
result.frames_used = frames_used;
result.ber_ofdm = err_ofdm ./ (cfg.total_bits_otfs * frames_used);
end

function target_frames = get_target_frames(cfg)
if isfield(cfg, 'use_adaptive_frames') && cfg.use_adaptive_frames
    target_frames = cfg.max_frames_per_snr;
else
    target_frames = cfg.N_fram_ofdm;
end
end

function tf = should_stop_adaptive(cfg, frames_done, error_count)
tf = false;
if ~isfield(cfg, 'use_adaptive_frames') || ~cfg.use_adaptive_frames
    return;
end

tf = frames_done >= cfg.min_frames_per_snr && error_count >= cfg.target_bit_errors;
end

function s = OFDM_modulation(M, x_tf)
s_mat = ifft(x_tf.', M) * sqrt(M);
s = s_mat(:);
end

function y_tf = OFDM_demodulation(N, M, r)
r_mat = reshape(r, M, N);
y_tf = (fft(r_mat, M) / sqrt(M)).';
end

function H_tf = OFDM_effective_channel_matrix(N, M, taps, delay_taps, Doppler_taps, chan_coef)
num_re = N * M;
H_tf = zeros(num_re, num_re);

for icol = 1:num_re
    x_probe = zeros(N, M);
    x_probe(icol) = 1;
    s_probe = OFDM_modulation(M, x_probe);
    r_probe = OFDM_channel_noiseless(N, M, taps, delay_taps, Doppler_taps, chan_coef, s_probe);
    y_probe = OFDM_demodulation(N, M, r_probe);
    H_tf(:, icol) = y_probe(:);
end
end

function r = OFDM_channel_noiseless(N, M, taps, delay_taps, Doppler_taps, chan_coef, s)
L = max(delay_taps);
s = [s(N*M-L+1:N*M); s];
s_chan = 0;

for itao = 1:taps
    doppler_phase = exp(1j*2*pi/M*(-L:-L+length(s)-1)*Doppler_taps(itao)/N).';
    delayed_signal = [s .* doppler_phase; zeros(delay_taps(end), 1)];
    s_chan = s_chan + chan_coef(itao) * circshift(delayed_signal, delay_taps(itao));
end

r = s_chan(L+1:L+(N*M));
end
