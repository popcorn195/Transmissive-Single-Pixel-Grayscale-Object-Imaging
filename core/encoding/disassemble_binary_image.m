% recovering upper/lower nibble matrices.

% H,W
% Ny,Nx
% Bavg
% B_pre
% U,L

function [U,L] = disassemble_binary_image(Braw)

    [H,W] = size(Braw);

    if mod(H,4)~=0
        error('Invalid binary image size.');
    end

    Ny = H/4;

    % averaging the duplicated row pairs before thresholding to reduce redundancy
    Bavg  = (Braw(1:2:end,:) + Braw(2:2:end,:)) / 2;
    B_pre = Bavg >= 0.5;

    U = B_pre(1:Ny,:);
    L = B_pre(Ny+1:end,:);
end