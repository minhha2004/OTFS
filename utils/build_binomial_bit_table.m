function table = build_binomial_bit_table(max_n, width)
% BUILD_BINOMIAL_BIT_TABLE tạo bảng các hệ số tổ hợp dùng cho NBC.
% Bảng chỉ chứa các giá trị C(n,k).
% Dựng tam giác Pascal bằng các vector bit uint8.
% Nếu giá trị vượt chiều rộng bit thì bão hòa thành toàn bit 1.

table = cell(max_n + 1, max_n + 1);
zero = zeros(1, width, 'uint8');
one = zero;
one(1) = 1;

for n = 0:max_n
    for k = 0:n
        if k == 0 || k == n
            table{n + 1, k + 1} = one;
        else
            table{n + 1, k + 1} = add_bits_saturated( ...
                table{n, k}, table{n, k + 1});
        end
    end
end

    function out = add_bits_saturated(a, b)
        % Cộng hai số nhị phân có chiều dài cố định và xử lý tràn.
        out = zero;
        carry = 0;
        for ibit = 1:width
            value = double(a(ibit)) + double(b(ibit)) + carry;
            out(ibit) = uint8(mod(value, 2));
            carry = value >= 2;
        end
        if carry
            out(:) = 1;
        end
    end
end
