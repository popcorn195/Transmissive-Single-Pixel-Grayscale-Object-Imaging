% recovering grayscale image from nibble matrices.

% O
% Ny
% Nx
% W

function O = binary_to_gray(U,L)

    [Ny,W] = size(U);
    
    Nx = W/4;
    
    O = zeros(Ny,Nx,'uint8');
    
    for y = 1:Ny
        for x = 1:Nx
    
            cols = (x-1)*4 + (1:4);
    
            bits = [ ...
                U(y,cols), ...
                L(y,cols)];
    
            value = uint8(0);
    
            for k = 1:8
                value = bitor(value, bitshift(uint8(bits(k)),8-k));
            end
    
            O(y,x) = value;
    
        end
    end

end