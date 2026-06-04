function [MAP_TABLE, info] = select_patterns_ohd(cfg)
% Selects the OTFS-IM activation-pattern table using the current OHD-PS rule.
% The current rule maximizes the minimum pairwise Hamming distance between
% selected constant-weight activation patterns.

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

all_sets = nchoosek(1:num_total_pats, num_selected_pats);
best_dmin = -inf;
best_set = [];

for s = 1:size(all_sets, 1)
    candidate = all_sets(s,:);
    dmin = inf;

    for i = 1:length(candidate)-1
        for j = i+1:length(candidate)
            dmin = min(dmin, D(candidate(i), candidate(j)));
        end
    end

    if dmin > best_dmin
        best_dmin = dmin;
        best_set = candidate;
    end
end

MAP_TABLE = ALL_PATS(best_set,:);
metrics = evaluate_pattern_table(best_set, BIN_PATS, D);

info.ALL_PATS = ALL_PATS;
info.BIN_PATS = BIN_PATS;
info.D = D;
info.best_set = best_set;
info.best_dmin = best_dmin;
info.num_total_pats = num_total_pats;
info.num_selected_pats = num_selected_pats;
info.MAP_TABLE = MAP_TABLE;
info.metrics = metrics;
end
