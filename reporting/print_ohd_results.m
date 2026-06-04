function print_ohd_results(cfg, otfs_result, im_result)
% Prints the final OHD OTFS-IM result table.

fprintf('\n========================================================\n');
fprintf('                 OHD OTFS-IM RESULT ANALYSIS            \n');
fprintf('========================================================\n');
fprintf('Baseline OTFS SE: %.2f bits/symbol\n', cfg.se_otfs);
fprintf('OHD OTFS-IM SE (n=%d,k=%d): %.2f bits/symbol\n', cfg.n, cfg.k, cfg.se_im);
fprintf('Reduction: %.1f%%\n', (1 - cfg.se_im/cfg.se_otfs)*100);

fprintf('\n=====================================================================\n');
fprintf('Eb/N0 | BER OTFS | BER OTFS-IM | Index BER | Symbol BER | Pattern ER\n');
for i = 1:length(cfg.EbN0_dB)
    fprintf('%5d | %8.5f | %11.5f | %9.5f | %10.5f | %10.5f\n', ...
        cfg.EbN0_dB(i), ...
        otfs_result.ber_otfs(i), ...
        im_result.ber_im(i), ...
        im_result.ber_idx(i), ...
        im_result.ber_sym(i), ...
        im_result.per_pattern(i));
end
end
