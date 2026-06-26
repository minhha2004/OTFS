% Evaluation role: experimental OHD tie-breaker method. It keeps the primary
% OHD objective, then resolves equal-minimum-distance candidates using average
% Hamming distance, number of closest pairs, and carrier-usage balance.
function [MAP_TABLE, info] = select_patterns_balanced_ohd(cfg)
ALL_PATS = nchoosek(1:cfg.n, cfg.k);
num_total_pats = size(ALL_PATS, 1);
num_selected_pats = 2^cfg.b1;

BIN_PATS = zeros(num_total_pats, cfg.n);
for i = 1:num_total_pats
    BIN_PATS(i, ALL_PATS(i,:)) = 1;
end

D = zeros(num_total_pats);
for i = 1:num_total_pats
    for j = i+1:num_total_pats
        D(i,j) = sum(xor(BIN_PATS(i,:), BIN_PATS(j,:)));
        D(j,i) = D(i,j);
    end
end

num_candidate_sets = nchoosek(num_total_pats, num_selected_pats);
if num_candidate_sets > 1e6
    error(['Exact Balanced-OHD search is too large for n=%d,k=%d: C(%d,%d)=%.0f candidate sets. ', ...
           'Use a smaller configuration or add a greedy selector.'], ...
        cfg.n, cfg.k, num_total_pats, num_selected_pats, num_candidate_sets);
end

all_sets = nchoosek(1:num_total_pats, num_selected_pats);
best_set = [];
best_metrics = [];

for iset = 1:size(all_sets, 1)
    candidate = all_sets(iset,:);
    metrics = balanced_metrics(candidate, BIN_PATS, D);

    if isempty(best_set) || is_better_balanced(metrics, best_metrics)
        best_set = candidate;
        best_metrics = metrics;
    end
end

MAP_TABLE = ALL_PATS(best_set,:);

info.ALL_PATS = ALL_PATS;
info.BIN_PATS = BIN_PATS;
info.D = D;
info.best_set = best_set;
info.best_dmin = best_metrics.min_hd;
info.num_total_pats = num_total_pats;
info.num_selected_pats = num_selected_pats;
info.MAP_TABLE = MAP_TABLE;
info.metrics = best_metrics;
end

function metrics = balanced_metrics(selected_set, BIN_PATS, D)
metrics = evaluate_pattern_table(selected_set, BIN_PATS, D);
metrics.num_min_pairs = sum(metrics.dist_list == metrics.min_hd);
metrics.usage_var = sum((metrics.carrier_usage - mean(metrics.carrier_usage)).^2);
metrics.usage_span = max(metrics.carrier_usage) - min(metrics.carrier_usage);
end

function tf = is_better_balanced(metrics, best_metrics)
tf = metrics.min_hd > best_metrics.min_hd;
tf = tf || (metrics.min_hd == best_metrics.min_hd && metrics.avg_hd > best_metrics.avg_hd);
tf = tf || (metrics.min_hd == best_metrics.min_hd && metrics.avg_hd == best_metrics.avg_hd && metrics.num_min_pairs < best_metrics.num_min_pairs);
tf = tf || (metrics.min_hd == best_metrics.min_hd && metrics.avg_hd == best_metrics.avg_hd && metrics.num_min_pairs == best_metrics.num_min_pairs && metrics.usage_var < best_metrics.usage_var);
tf = tf || (metrics.min_hd == best_metrics.min_hd && metrics.avg_hd == best_metrics.avg_hd && metrics.num_min_pairs == best_metrics.num_min_pairs && metrics.usage_var == best_metrics.usage_var && metrics.usage_span < best_metrics.usage_span);
end
