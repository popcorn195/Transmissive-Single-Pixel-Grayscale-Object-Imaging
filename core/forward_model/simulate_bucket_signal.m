% P
% B
% x
% Q_pos
% Q_neg
% Q

function Q = simulate_bucket_signal(P, B, noise_std)

    if nargin < 3
        noise_std = 0;
    end
    
    x = double(B(:));
    
    Q_pos = P * x;
    Q_neg = (1-P) * x;
    
    Q = Q_pos - Q_neg;
    
    if noise_std > 0
        Q = Q + noise_std * randn(size(Q));
    end

end