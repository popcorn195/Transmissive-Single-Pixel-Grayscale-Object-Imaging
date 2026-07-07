% decoding reconstructed binary image into grayscale image.

function O = decode_binary(B)

    [U,L] = disassemble_binary_image(B);

    O = binary_to_gray(U,L);

end