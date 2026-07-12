% encoding an 8-bit grayscale image into a binary image.

% B
% O
% U,L

function B = encode_grayscale(O)

    if ~isa(O,'uint8')
        O = uint8(round(O));
    end

    % split into upper/lower nibble matrices
    [U, L] = build_bitplane_matrix(O);

    % assemble into binary image
    B = assemble_binary_image(U, L);

    % ensure logical output
    B = logical(B);

end