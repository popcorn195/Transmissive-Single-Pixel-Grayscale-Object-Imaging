% per-nibble-block bit error rate after recon.
% U, L : ground-truth logical nibble matrices (Ny x 4*Nx)
% U_star, L_star : reconstructed logical nibble matrices, same size

function report = evaluate_bitplane_accuracy(U, L, U_star, L_star)

    ber_U = mean(U(:) ~= U_star(:));
    ber_L = mean(L(:) ~= L_star(:));
    
    report.BER_upper_nibble = ber_U;   % b7 b6 b5 b4
    report.BER_lower_nibble = ber_L;   % b3 b2 b1 b0
    
    fprintf('Bit error rate - upper nibble (b7-b4): %.4f\n', ber_U);
    fprintf('Bit error rate - lower nibble (b3-b0): %.4f\n', ber_L);
end