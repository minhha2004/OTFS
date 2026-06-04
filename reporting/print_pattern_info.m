function print_pattern_info(pattern_info, label)
% Prints the selected OHD pattern table and its Hamming-distance diagnostics.

if nargin < 2
    label = 'Pattern Selection';
end

fprintf('%s Pattern Set Found\n', label);
fprintf('Minimum Hamming Distance = %d\n', pattern_info.best_dmin);
disp('Selected Pattern Table:')
disp(pattern_info.MAP_TABLE)
fprintf('\n');
fprintf('Minimum HD = %.2f\n', pattern_info.metrics.min_hd);
fprintf('Average HD = %.2f\n', pattern_info.metrics.avg_hd);
fprintf('Maximum HD = %.2f\n', pattern_info.metrics.max_hd);
fprintf('Carrier usage in selected pattern table:\n');
disp(pattern_info.metrics.carrier_usage)
fprintf('\n');
end
