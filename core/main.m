clear;
clc;
close all;

% O [ Ny * Nx ] uint8 : original grayscale image
% here Ny/Nx is 64

% B [ 4Ny * 4Nx ] : full encoded binary image, logical
% Hhalf : top half U block (b7..b4), bottom L block (b3..b0)
% H (4Ny) : total rows of B
% W (4Nx) : total cols of B

% SR_per_bit : sampling ratio assigned to each of the 8 bit-planes
% B_star [ 4Ny * 4Nx ] : reconstructed binary image

% blk : which nibble block 
% rows : which rows belong to the current nibble
% Bblk : only those rows from the encoded binary image.

% off : each nibble contains four bit-planes
% bit_idx : converts (blk, off) into a number from 1 to 8
% cols : encoded image stores different bit-planes in every fourth column
% plane : single bit-plane extracted
% Ph(2Ny), Pw(Nx) : height/width of the current plane
% P [ SR*Ph*Pw , Ph*Pw ] : measurement pattern matrix for this plane
% Q [ SR*Ph*Pw , 1] : simulated bucket detector readings for this plane
% plane_star [ Ph * Pw ] : reconstructed plane

% U [Ny * 4Nx] : ground-truth upper-nibble matrix
% L [Ny * 4Nx] : ground-truth lower-nibble matrix
% U_star [Ny * 4Nx] : reconstructed upper-nibble matrix
% L_star [Ny * 4Nx] : reconstructed lower-nibble matrix
% O_star [Ny * Nx] : final reconstructed grayscale image

tic

% paths
proj_root = fullfile(fileparts(mfilename('fullpath')), '..');
addpath(genpath(fullfile(proj_root,'core')));
addpath(genpath(fullfile(proj_root,'metrics')));
addpath(genpath(fullfile(proj_root,'TVAL3')));

% image
img_path = fullfile(proj_root,'data','images','cat.jpg');
img=imread(img_path);
if size(img,3)==3
    img = rgb2gray(img);
end
[~, img_name, ~] = fileparts(img_path);   

O = imresize(img,[32 32],'bicubic');
O = imsharpen(O, 'Radius', 1, 'Amount', 1.5);
[sh, ~] = size(O);


% Encoding
B = encode_grayscale(O);          
[H, W] = size(B);
Hhalf = H/2;                      

% MSB gets the most measurements, LSB the fewest 
% [b7 b6 b5 b4 b3 b2 b1 b0]
SR_per_bit = [0.90 0.75 0.55 0.35, 0.20 0.12 0.07 0.04];  

B_star = false(H, W); 

% 1 : U block, 2 : L block
for blk = 1:2 
    rows = (blk-1)*Hhalf + (1:Hhalf);
    Bblk = B(rows, :);

    % each nibble contains 4 bit-planes
    for off = 1:4
        bit_idx = (blk-1)*4 + off; 
        cols = off:4:W;
        plane = Bblk(:, cols); % Hhalf * Nx, one bit per pixel
        [Ph, Pw] = size(plane);
        
        P = build_gcs_patterns(Ph, Pw, SR_per_bit(bit_idx));
        Q = simulate_bucket_signal(P, plane, 0);
        plane_star = recon_tval3(P, Q, Ph, Pw);

        B_star(rows, cols) = plane_star >= 0.5;
    end

end

% ground-truth nibble planes 
[U, L] = disassemble_binary_image(logical(B));

% decoding reconstructed image
[U_star, L_star] = disassemble_binary_image(B_star);
O_star = binary_to_gray(U_star, L_star);

total_time=toc;

% metrics
evaluate_bitplane_accuracy(U, L, U_star, L_star);
[psnr_val, ssim_val] = evaluate_metrics(O, O_star);
display_comparison(O, O_star, psnr_val, ssim_val, total_time);
fprintf('Total time taken: %.2f seconds\n', total_time);

% saving figure
results_dir = fullfile(proj_root, 'results', 'figures');
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

fig_name = sprintf('res_%s_%d.png', img_name, sh);
saveas(gcf, fullfile(results_dir, fig_name));
fprintf('Figure saved to: %s\n', fullfile(results_dir, fig_name));


%% Export for U-Net super-resolution
unet_dir = fullfile(proj_root, 'unet', 'inputs');
if ~exist(unet_dir, 'dir')
    mkdir(unet_dir);
end

O_star_norm = double(O_star) / 255;
O_norm      = double(O) / 255;

save(fullfile(unet_dir, sprintf('unet_input_%d.mat', sh)), ...
    'O_star_norm', 'O_norm', '-v7');

fprintf('Saved U-Net input: %s\n', fullfile(unet_dir, sprintf('unet_input_%d.mat', sh)));