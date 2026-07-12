% one 8-bit grayscale pixel to an 8-bit binary vector.

% pixel : uint8 scalar (0-255)
% bits : 1x8 logical vector [b7 b6 b5 b4 b3 b2 b1 b0]

function bits = gray_to_binary(pixel)  

    if ~isa(pixel,'uint8')
        pixel = uint8(round(pixel));
    end
    
    bits = false(1,8);
    
    for k = 1:8
        bits(k) = bitget(pixel, 9-k);
    end

end