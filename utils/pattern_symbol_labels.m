function labels = pattern_symbol_labels(active_positions, n, k)
% PATTERN_SYMBOL_LABELS xác định symbol logic được đặt vào từng ô active.
% Ưu tiên nhãn theo vị trí của ô active như Algorithm 1
% Nếu hai ô muốn dùng cùng nhãn, giữ nhãn cho ô gặp trước.
% Gán các nhãn còn thừa cho những ô chưa có nhãn.

active_positions = sort(active_positions(:));
if numel(active_positions) ~= k || any(active_positions < 1) ...
        || any(active_positions > n) || numel(unique(active_positions)) ~= k
    error('active_positions must contain K unique positions in the range 1:N.');
end

label_at_position = zeros(n, 1);
label_used = false(k, 1);

% Ưu tiên nhãn mod(position-1,K)+1 nếu nhãn đó chưa được dùng.
for i = 1:k
    position = active_positions(i);
    candidate_label = mod(position - 1, k) + 1;
    if ~label_used(candidate_label)
        label_at_position(position) = candidate_label;
        label_used(candidate_label) = true;
    end
end

% Xử lý các nhãn bị trùng bằng danh sách nhãn còn lại.
unassigned_positions = active_positions(label_at_position(active_positions) == 0);
unused_labels = find(~label_used);
label_at_position(unassigned_positions) = unused_labels;

labels = label_at_position(active_positions);
end
