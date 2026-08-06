function alphabet = modified_4ask_alphabet(spacing_ratio, target_energy)
% MODIFIED_4ASK_ALPHABET tạo tập 4-ASK không đều và gán bit Gray.
% Dùng spacing_ratio để tăng khoảng cách từ symbol nhỏ nhất tới zero.
% Tạo hai mức biên độ trong và ngoài ở hai phía âm/dương.
% Chuẩn hóa lại để công suất trung bình không đổi.

if spacing_ratio <= 0
    error('spacing_ratio must be positive.');
end
inner = spacing_ratio / 2;
outer = inner + 1;

% Nhãn thập phân 00,01,10,11; thứ tự vật lý theo Gray là 00,01,11,10.
alphabet = [-outer, -inner, outer, inner];
alphabet = alphabet * sqrt(target_energy / mean(abs(alphabet).^2));
end
