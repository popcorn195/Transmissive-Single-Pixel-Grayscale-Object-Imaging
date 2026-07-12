function B_star = recon_tval3(selected_rows, Q, Ny, Nx, user_opts)
%RECON_TVAL3 Reconstruct binary image using TVAL3, via fast Hadamard
%transform instead of an explicit dense measurement matrix.
%
% selected_rows : indices (into the full N-length Gray-code-ordered
%                 Hadamard basis) of which coefficients were measured
% Q             : bucket measurements, length = numel(selected_rows)

if exist('TVAL3','file') ~= 2
    error('TVAL3 not found.');
end

opts.mu      = 256;
opts.beta    = 32;
opts.tol     = 1e-3;
opts.maxit   = 300;
opts.TVnorm  = 1;
opts.nonneg  = true;
if nargin >= 5 && ~isempty(user_opts)
    fn = fieldnames(user_opts);
    for k = 1:numel(fn)
        opts.(fn{k}) = user_opts.(fn{k});
    end
end

N = Ny*Nx;

% TVAL3 calls A(x,1) for A*x and A(x,2) for A'*x
A = @(x, mode) fwht_operator(x, mode, selected_rows, N);

[x,~] = TVAL3(A, Q, Ny, Nx, opts);
B_star = reshape(x, Ny, Nx);
B_star = max(min(B_star,1),0);
end

function y = fwht_operator(x, mode, selected_rows, N)
    if mode == 1
        % Forward: full FWHT of x, keep only measured coefficients
        full_transform = fwht(x(:), N) * N;
        y = full_transform(selected_rows);
    else
        % Adjoint: zero-pad measured coefficients back to full length,
        % then inverse FWHT (Hadamard transform is self-inverse up to
        % scaling, since H*H = N*I)
        full_vec = zeros(N,1);
        full_vec(selected_rows) = x;
        y = ifwht(full_vec, N) * N;
    end
end