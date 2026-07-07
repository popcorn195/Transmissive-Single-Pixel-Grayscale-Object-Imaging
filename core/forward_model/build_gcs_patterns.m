% generating gray-code ordered hadamard patterns (GCS+S)

% P
% Ny/Nx
% SR
% M
% H
% gray

function P = build_gcs_patterns(Ny, Nx, SR)

    N = Ny * Nx;

    % hadamard requires power-of-two dimensions
    if abs(log2(N)-round(log2(N))) > eps
        error('Ny*Nx must be a power of two.');
    end

    M = round(SR * N);

    % full Hadamard basis (+1/-1)
    H = hadamard(N);

    % gray-code ordering 
    gray = bitxor((0:N-1)', floor((0:N-1)'/2));

    [~, order] = sort(gray);

    H = H(order, :);

    % select first M patterns
    H = H(1:M, :);

    % convert to binary illumination
    P = (H + 1) / 2;

end