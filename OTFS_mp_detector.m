function [x_est, sum_prob_fin] = OTFS_mp_detector(...
    N,M,alphabet,symbol_prior,taps,delay_taps,Doppler_taps,chan_coef,sigma_2,y,mp_options)
% OTFS_MP_DETECTOR ước lượng giá trị phát tại từng ô bằng Message Passing.
% x_est: symbol được chọn cuối cùng tại từng ô.
% sum_prob_fin: xác suất cuối của từng giá trị có thể có tại từng ô.
% Bước 1: Khởi tạo xác suất ban đầu của các symbol và giá trị 0.
% Bước 2: Ước lượng trung bình/phương sai của nhiễu giao thoa từ các ô khác.
% Bước 3: Cập nhật xác suất symbol qua từng path và lặp đến khi hội tụ.
% Bước 4: Kết hợp thông tin từ mọi path để tạo xác suất cuối và x_est.
yv = reshape(y,N*M,1);
n_ite = mp_options.mp_iterations;
delta_fra = mp_options.mp_damping;
if n_ite < 1 || n_ite ~= floor(n_ite)
    error('mp_iterations must be a positive integer.');
end
if delta_fra <= 0 || delta_fra > 1
    error('mp_damping must be in the interval (0,1].');
end

% Tập giá trị có thể phát và xác suất ban đầu được truyền từ hàm mô phỏng.
alphabet = reshape(alphabet, 1, []);
M_mod_all = numel(alphabet);
symbol_prior = reshape(symbol_prior, 1, []);
if numel(symbol_prior) ~= M_mod_all || any(symbol_prior <= 0)
    error('symbol_prior must contain one positive probability per alphabet symbol.');
end
symbol_prior = symbol_prior / sum(symbol_prior);
log_prior = log(max(symbol_prior, 1e-15));

mean_int = zeros(N*M,taps);
var_int = zeros(N*M,taps);
p_map = repmat(reshape(symbol_prior, 1, 1, M_mod_all), N*M, taps, 1);

conv_rate_prev = -0.1;
for ite=1:n_ite
    %% Bước MP 1: Cập nhật trung bình và phương sai của giao thoa
    for ele1=1:M
        for ele2=1:N
            mean_int_hat = zeros(taps,1);
            var_int_hat = zeros(taps,1);
            for tap_no=1:taps
                m = ele1-1-delay_taps(tap_no)+1;
                add_term = exp(1i*2*(pi/M)*(m-1)*(Doppler_taps(tap_no)/N));
                add_term1 = 1;
                if ele1-1<delay_taps(tap_no)
                    n = mod(ele2-1-Doppler_taps(tap_no),N) + 1;
                    add_term1 = exp(-1i*2*pi*((n-1)/N));
                end
                new_chan = add_term * add_term1 * chan_coef(tap_no);
                
                for i2=1:M_mod_all
                    mean_int_hat(tap_no) = mean_int_hat(tap_no) + p_map(N*(ele1-1)+ele2,tap_no,i2) * alphabet(i2);
                    var_int_hat(tap_no)  = var_int_hat(tap_no)  + p_map(N*(ele1-1)+ele2,tap_no,i2) * abs(alphabet(i2))^2;
                end
                mean_int_hat(tap_no) = mean_int_hat(tap_no) * new_chan;
                var_int_hat(tap_no)  = var_int_hat(tap_no) * abs(new_chan)^2;
                var_int_hat(tap_no)  = var_int_hat(tap_no) - abs(mean_int_hat(tap_no))^2;
            end
            
            mean_int_sum = sum(mean_int_hat);
            var_int_sum  = sum(var_int_hat) + sigma_2;
            
            for tap_no=1:taps
                mean_int(N*(ele1-1)+ele2,tap_no) = mean_int_sum - mean_int_hat(tap_no);
                var_int(N*(ele1-1)+ele2,tap_no)  = var_int_sum  - var_int_hat(tap_no);
            end
        end
    end
    
    %% Bước MP 2: Dùng tín hiệu thu để cập nhật xác suất của từng symbol
    sum_prob_comp = zeros(N*M,M_mod_all);
    dum_eff_ele1 = zeros(taps,1);
    dum_eff_ele2 = zeros(taps,1);
    for ele1=1:M
        for ele2=1:N
            dum_sum_prob = zeros(M_mod_all,1);
            log_te_var   = zeros(taps,M_mod_all);
            for tap_no=1:taps
                if ele1+delay_taps(tap_no)<=M
                    eff_ele1 = ele1 + delay_taps(tap_no);
                    add_term = exp(1i*2*(pi/M)*(ele1-1)*(Doppler_taps(tap_no)/N));
                    int_flag = 0;
                else
                    eff_ele1 = ele1 + delay_taps(tap_no)- M;
                    add_term = exp(1i*2*(pi/M)*(ele1-1-M)*(Doppler_taps(tap_no)/N));
                    int_flag = 1;
                end
                add_term1 = 1;
                if int_flag==1
                    add_term1 = exp(-1i*2*pi*((ele2-1)/N));
                end
                eff_ele2 = mod(ele2-1+Doppler_taps(tap_no),N) + 1;
                new_chan = add_term * add_term1 * chan_coef(tap_no);
                
                dum_eff_ele1(tap_no) = eff_ele1;
                dum_eff_ele2(tap_no) = eff_ele2;
                for i2=1:M_mod_all
                    dum_sum_prob(i2) = abs(yv(N*(eff_ele1-1)+eff_ele2) ...
                        - mean_int(N*(eff_ele1-1)+eff_ele2,tap_no) ...
                        - new_chan * alphabet(i2))^2;
                    dum_sum_prob(i2)= -(dum_sum_prob(i2)/var_int(N*(eff_ele1-1)+eff_ele2,tap_no));
                end
                dum_sum = dum_sum_prob - max(dum_sum_prob);
                dum1 = sum(exp(dum_sum));
                log_te_var(tap_no,:) = dum_sum - log(dum1);
            end
            ln_qi = log_prior + sum(log_te_var, 1);
            dum_sum = exp(ln_qi - max(ln_qi));
            dum1 = sum(dum_sum);
            sum_prob_comp(N*(ele1-1)+ele2,:) = dum_sum/dum1;
            for tap_no=1:taps
                eff_ele1 = dum_eff_ele1(tap_no);
                eff_ele2 = dum_eff_ele2(tap_no);
                
                dum_sum = log_te_var(tap_no,:);
                ln_qi_loc = ln_qi - dum_sum;
                dum_sum = exp(ln_qi_loc - max(ln_qi_loc));
                dum1 = sum(dum_sum);
                p_map(N*(eff_ele1-1)+eff_ele2,tap_no,:) = ...
                    (dum_sum/dum1)*delta_fra + ...
                    (1-delta_fra)*reshape(p_map(N*(eff_ele1-1)+eff_ele2,tap_no,:),1,M_mod_all);
            end
        end
    end

    conv_rate = sum(max(sum_prob_comp,[],2)>0.99)/(N*M);
    if conv_rate==1
        sum_prob_fin = sum_prob_comp;
        break;
    elseif conv_rate > conv_rate_prev
        conv_rate_prev = conv_rate;
        sum_prob_fin = sum_prob_comp;
    elseif (conv_rate < conv_rate_prev - 0.2) && conv_rate_prev > 0.95
        break;
    end
end

% Chọn giá trị có xác suất lớn nhất làm kết quả cứng tại mỗi ô.
x_est = zeros(N,M);
for ele1=1:M
    for ele2=1:N
        [~,pos] = max(sum_prob_fin(N*(ele1-1)+ele2,:));
        x_est(ele2,ele1) = alphabet(pos);
    end
end
