% assembles upper/lower nibble matrices into final binary image

% B_pre [ 2Ny * 4Nx ] : stacked upper and lower planes
% B [ 4Ny * 4Nx ] : final binary image
% Ny
% W

function B = assemble_binary_image(U, L)

    [Ny, W] = size(U);
    
    if ~isequal(size(U), size(L))
        error('U and L must have the same size.');
    end
    
    B_pre = [U; L]; 
    
    B = false(2*size(B_pre,1), W); 
    
    % checkerboard-style vertical duplication
    B(1:2:end,:) = B_pre;
    B(2:2:end,:) = B_pre;

end