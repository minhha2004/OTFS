function active_positions = combination_unrank_bits(rank_bits, n, k, binom_table)
% COMBINATION_UNRANK_BITS đổi bit index thành K vị trí active, không dùng LUT.
% Coi chuỗi bit đầu vào là thứ hạng của pattern cần tìm.
% Tại từng vị trí, tính số pattern nếu vị trí đó được chọn active.
% So sánh thứ hạng với số pattern trên để quyết định bật hay tắt.
% Nếu bỏ qua một nhóm pattern thì trừ kích thước nhóm khỏi thứ hạng.

width = numel(binom_table{1, 1});
rank_value = zeros(1, width, 'uint8');
rank_value(1:numel(rank_bits)) = uint8(flip(rank_bits(:).'));
active_positions = zeros(k, 1);
num_active = 0;
remaining_active = k;

for position = 1:n
    if remaining_active == 0
        break;
    end
    remaining_positions = n - position;
    if remaining_active > remaining_positions
        choose_active = true;
    else
        first_block_size = binom_table{remaining_positions + 1, remaining_active};
        choose_active = bits_less_than(rank_value, first_block_size);
        if ~choose_active
            rank_value = subtract_bits(rank_value, first_block_size);
        end
    end

    if choose_active
        num_active = num_active + 1;
        active_positions(num_active) = position;
        remaining_active = remaining_active - 1;
    end
end

if num_active ~= k || any(rank_value)
    error('Invalid combinatorial rank for N=%d, K=%d.', n, k);
end
end

function tf = bits_less_than(a, b)
% So sánh hai số nhị phân lưu theo thứ tự bit thấp trước.
idx = find(a ~= b, 1, 'last');
tf = ~isempty(idx) && a(idx) < b(idx);
end

function out = subtract_bits(a, b)
% Trừ hai số nhị phân có chiều dài cố định.
out = a;
borrow = 0;
for ibit = 1:numel(a)
    value = double(a(ibit)) - double(b(ibit)) - borrow;
    if value < 0
        value = value + 2;
        borrow = 1;
    else
        borrow = 0;
    end
    out(ibit) = uint8(value);
end
if borrow
    error('Bit-vector subtraction underflow.');
end
end
