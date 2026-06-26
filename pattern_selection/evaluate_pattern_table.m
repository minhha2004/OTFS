% Evaluation role: computes pattern-geometry metrics used to explain why
% OHD-selected activation patterns reduce pattern and index errors.
function metrics = evaluate_pattern_table(selected_set, BIN_PATS, D)
% Computes pattern-table diagnostics: pairwise Hamming-distance statistics
% and how often each carrier position is used by the selected patterns.

num_selected_pats = length(selected_set);
dist_list = zeros(1, nchoosek(num_selected_pats, 2));
ipair = 1;

for i = 1:num_selected_pats-1
    for j = i+1:num_selected_pats
        dist_list(ipair) = D(selected_set(i), selected_set(j));
        ipair = ipair + 1;
    end
end

metrics.dist_list = dist_list;
metrics.min_hd = min(dist_list);
metrics.avg_hd = mean(dist_list);
metrics.max_hd = max(dist_list);
metrics.carrier_usage = sum(BIN_PATS(selected_set,:), 1);
end
