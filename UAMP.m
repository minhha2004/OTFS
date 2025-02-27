function [x_est, p_final] = UAMP(y, H, maxIte)
[U, D, V] = svd(H);
H1 = D*V';
y1 = U'*y;
MN = length(y);
mean_mat = zeros(MN, MN);
var_mat = zero(MN, MN);
for c=1:MN
   for d = 1:MN
       
   end
end