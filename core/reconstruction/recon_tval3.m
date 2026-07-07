% tval3 reconstruction of binary image

% P
% Q
% Ny,Nx
% user_opts
% B_star
% A

function B_star = recon_tval3(P, Q, Ny, Nx, user_opts)

    if exist('TVAL3','file') ~= 2
        error('TVAL3 not found.');
    end

    opts.mu = 256;
    opts.beta = 32;
    opts.tol = 1e-6;
    opts.maxit = 2000;
    opts.TVnorm = 1;
    opts.nonneg = true;

    if nargin >= 5 && ~isempty(user_opts)

        fn = fieldnames(user_opts);

        for k = 1:numel(fn)
            opts.(fn{k}) = user_opts.(fn{k});
        end

    end

    A = 2*P - 1;
    [x,~] = TVAL3(A,Q,Ny,Nx,opts);

    B_star = reshape(x,Ny,Nx);

    % clipped to valid range
    B_star = max(min(B_star,1),0);

end