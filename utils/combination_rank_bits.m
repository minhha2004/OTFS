function [rank_bits, is_valid] = combination_rank_bits(active_positions, n, k, num_bits, binom_table)
% COMBINATION_RANK_BITS đổi K vị trí active trở lại chuỗi bit index.
% Quét lần lượt N vị trí của pattern nhận được.
% Cộng số pattern của các nhóm đã bị bỏ qua để tìm thứ hạng.
% Đổi thứ hạng thành b_index bit và báo pattern có hợp lệ hay không.

width = numel(binom_table{1, 1});
rank_value = zeros(1, width, 'uint8');
active_mask = false(1, n);
active_mask(active_positions) = true;
remaining_active = k;

for position = 1:n
    if remaining_active == 0
        break;
    end
    if active_mask(position)
        remaining_active = remaining_active - 1;
    else
        remaining_positions = n - position;
        if remaining_active <= remaining_positions
            first_block_size = binom_table{remaining_positions + 1, remaining_active};
            rank_value = add_bits_saturated(rank_value, first_block_size);
        end
    end
end

is_valid = remaining_active == 0 && ~any(rank_value(num_bits + 1:end));
rank_bits = double(flip(rank_value(1:num_bits))).';
end

function out = add_bits_saturated(a, b)
% Cộng hai thứ hạng nhị phân; nếu tràn thì bão hòa thành toàn bit 1.
out = zeros(size(a), 'uint8');
carry = 0;
for ibit = 1:numel(a)
    value = double(a(ibit)) + double(b(ibit)) + carry;
    out(ibit) = uint8(mod(value, 2));
    carry = value >= 2;
end
if carry
    out(:) = 1;
end
end
