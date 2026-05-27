function idx = all_combinations(A, k)
if k == 0
    idx = zeros(1,0);
    return;
end
grids = cell(1,k);
[grids{:}] = ndgrid(1:A);
mat = zeros(numel(grids{1}), k);
for j = 1:k
    mat(:,j) = grids{j}(:);
end
idx = mat;
end
