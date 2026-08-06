function variant = build_full_grid_variant(base_cfg, name, alphabet, k_active)
% BUILD_FULL_GRID_VARIANT tạo cấu hình cho một nhánh full-grid OTFS-IM.
% Đầu vào gồm cấu hình chung, tên nhánh, tập symbol và số vị trí active K.
% Tính số bit index bằng floor(log2(nchoosek(N,K))).
% Tính bit symbol, tổng bit mỗi frame và hiệu suất phổ.
% Chuẩn hóa công suất vì chỉ có K trong N vị trí được bật.
% Tính phương sai nhiễu tương ứng để so sánh công bằng theo Eb/N0.

variant = base_cfg;
variant.name = name;
variant.data_alphabet = reshape(alphabet, 1, []);
variant.M_mod_im = numel(variant.data_alphabet);
variant.M_bits_im = log2(variant.M_mod_im);
variant.K_active = k_active;
variant.b_index = floor((gammaln(variant.N_grid + 1) ...
    - gammaln(k_active + 1) ...
    - gammaln(variant.N_grid - k_active + 1)) / log(2));
variant.b_symbol = k_active * variant.M_bits_im;
variant.lambda = variant.b_index + variant.b_symbol;
variant.se_im = variant.lambda / variant.N_grid;
variant.power_scale_im = sqrt(variant.N_grid / k_active);
variant.EsN0_im_dB = variant.EbN0_dB + 10*log10(variant.se_im);
variant.symbol_energy = mean(abs(variant.data_alphabet).^2);
variant.sigma_2_im = variant.symbol_energy ./ (10.^(variant.EsN0_im_dB/10));
end
