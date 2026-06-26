% Evaluation role: prints OHD/B-OHD pattern geometry before simulation so
% BER changes can be connected to minimum Hamming distance and carrier usage.
function print_pattern_info(pattern_info, label, print_table)
% Prints concise Hamming-distance diagnostics. Set print_table=true only when
% the selected activation maps themselves are needed for debugging.

if nargin < 2
    label = 'Pattern Selection';
end
if nargin < 3
    print_table = false;
end

fprintf('%s Pattern Set Found\n', label);
fprintf('Minimum Hamming Distance = %d\n', pattern_info.best_dmin);
if print_table
    disp('Selected Pattern Table:')
    disp(pattern_info.MAP_TABLE)
end
fprintf('\n');
fprintf('Minimum HD = %.2f\n', pattern_info.metrics.min_hd);
fprintf('Average HD = %.2f\n', pattern_info.metrics.avg_hd);
fprintf('Maximum HD = %.2f\n', pattern_info.metrics.max_hd);
if isfield(pattern_info.metrics, 'num_min_pairs')
    fprintf('Minimum-HD pair count = %d\n', pattern_info.metrics.num_min_pairs);
end
if isfield(pattern_info.metrics, 'index_cost')
    fprintf('Normalized index cost = %.4f\n', pattern_info.metrics.index_cost);
end
if isfield(pattern_info.metrics, 'symbol_damage_cost')
    fprintf('Normalized symbol-damage cost = %.4f\n', pattern_info.metrics.symbol_damage_cost);
end
if isfield(pattern_info.metrics, 'hybrid_cost')
    fprintf('Hybrid cost = %.4f\n', pattern_info.metrics.hybrid_cost);
end
fprintf('Carrier usage in selected pattern table:\n');
disp(pattern_info.metrics.carrier_usage)
if isfield(pattern_info.metrics, 'usage_var')
    fprintf('Carrier usage variance metric = %.2f\n', pattern_info.metrics.usage_var);
end
if isfield(pattern_info.metrics, 'usage_span')
    fprintf('Carrier usage span = %.2f\n', pattern_info.metrics.usage_span);
end
if isfield(pattern_info.metrics, 'search_method')
    fprintf('Pattern search method = %s\n', pattern_info.metrics.search_method);
end
fprintf('\n');
end
