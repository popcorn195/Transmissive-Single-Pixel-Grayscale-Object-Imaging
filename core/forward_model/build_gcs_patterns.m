% selected_rows
% Ny, Nx : height/width of the plane 
% SR

% N
% M : gray-code value for each index 0..N-1
% gray

function selected_rows = build_gcs_patterns(Ny, Nx, SR)

    N = Ny * Nx;

    if abs(log2(N)-round(log2(N))) > eps
        error('Ny*Nx must be a power of two.');
    end

    M = round(SR * N);
    gray = bitxor((0:N-1)', floor((0:N-1)'/2));
    [~, order] = sort(gray);
    
    selected_rows = order(1:M);

end