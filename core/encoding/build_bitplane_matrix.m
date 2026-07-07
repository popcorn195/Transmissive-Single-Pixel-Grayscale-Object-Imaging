% splitting grayscale image into upper and lower nibble bit-plane matrices

% O [ Ny * Nx ] : grayscale image 
% U [ Ny * 4Nx ] : logical matrix containing b7 b6 b5 b4 (upper nibble)
% L [ Ny * 4Nx ] : logical matrix containing b3 b2 b1 b0 (lower nibble)

function [U, L] = build_bitplane_matrix(O)

    if ~isa(O,'uint8')
        O = uint8(round(O));
    end

    [Ny, Nx] = size(O);

    U = false(Ny, 4*Nx);
    L = false(Ny, 4*Nx);

    for y = 1:Ny
        for x = 1:Nx

            bits = gray_to_binary(O(y,x));

            cols = (x-1)*4 + (1:4);

            U(y, cols) = bits(1:4);

            L(y, cols) = bits(5:8);

        end
    end

end