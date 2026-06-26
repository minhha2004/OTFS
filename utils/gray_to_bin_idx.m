% Evaluation role: converts detected Gray-coded pattern labels back to binary
% index bits so OTFS-IM index BER can be measured separately from symbol BER.
function bin = gray_to_bin_idx(gray)
% Converts one Gray-coded integer index to the corresponding binary integer.
% This is used to recover OTFS-IM index bits after pattern detection.

bin = gray;
while any(bitshift(gray, -1))
    gray = bitshift(gray, -1);
    bin = bitxor(bin, gray);
end
end
