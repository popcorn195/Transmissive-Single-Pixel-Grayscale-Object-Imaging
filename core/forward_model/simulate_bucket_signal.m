% P [Ph , Pw]
% B [Ph , Pw] : plane
% x [Ph , 1] : flattened version of B
% Q_pos : readings for the projected pattern P
% Q_neg : readings for the complementary pattern (1-P)
% Q : Q_pos - Q_neg

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