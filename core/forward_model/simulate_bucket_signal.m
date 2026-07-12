% Q
% selected_rows
% B
% N

% x
% full_transform

function Q = simulate_bucket_signal(selected_rows, B, noise_std, N)
    
    if nargin < 3
        noise_std = 0;
    end

    x = double(B(:));
    full_transform = fwht(x, N) * N;
    Q = full_transform(selected_rows);

    if noise_std > 0
        Q = Q + noise_std * randn(size(Q));
    end
    
end