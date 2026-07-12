clear;
clc;
close all;

% O [ Ny * Nx ] uint8 : original grayscale image
% here Ny/Nx is 64

% B [ 4Ny * 4Nx ] : full encoded binary image, logical
% Hhalf : top half U block (b7..b4), bottom L block (b3..b0)
% H (4Ny) : total rows of B
% W (4Nx) : total cols of B

% Ph(Hhalf), Pw(W/4) : height/width of the current plane
% N (Ph*Pw) :

% SR_per_bit : sampling ratio assigned to each of the 8 bit-planes

% cell [ M,1 ]
% rows_idx_all (cell[8,1]) : list of Hadamard/Gray-code row indices that were measured
% Q_all (cell[8,1]) : simulated bucket detector readings per bit plane
% rows_all (cell[8,1]) : which rows of B that plane occupies
% cols_all (cell[8,1]) : which columns of B that plane occupies

% bit_idx : from 1 to 8 bit plane
% blk : bit_idx 1=b7, bit_idx 8=b0
% rows : 
% off : which block bit_idx belongs to
% cols : encoded image stores different bit-planes in every fourth column
% plane : single bit-plane extracted
% selected_rows :
% Q [ SR*Ph*Pw , 1] : simulated bucket detector readings for this plane

% results :
% user_opts :
% plane_star [ Ph * Pw ] : reconstructed plane

% % B_star [ 4Ny * 4Nx ] : reconstructed binary image

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
img_path = fullfile(proj_root,'data','images','lena512.jpg');
img=imread(img_path);
if size(img,3)==3
    img = rgb2gray(img);
end
[~, img_name, ~] = fileparts(img_path);  

O = auto_crop_saliency(img, [64 64], 0.15);   % auto-crop + resize, replaces manual crop
O = uint8(O * 255);                           
O = imsharpen(O, 'Radius', 1, 'Amount', 1.5);
[sh, ~] = size(O);




% Encoding
B = encode_grayscale(O);          
[H, W] = size(B);
Hhalf = H/2; 



Ph = Hhalf;
Pw = W/4;
N  = Ph*Pw;



% MSB gets the most measurements, LSB the fewest 
% [b7 b6 b5 b4 b3 b2 b1 b0]
SR_per_bit = [0.90 0.75 0.55 0.35, 0.20 0.12 0.07 0.04];  






rows_idx_all = cell(8,1);   
Q_all    = cell(8,1);
rows_all = cell(8,1);
cols_all = cell(8,1);

for bit_idx = 1:8
    blk = ceil(bit_idx/4);
    off = mod(bit_idx-1,4) + 1;
    rows = (blk-1)*Hhalf + (1:Hhalf);
    cols = off:4:W;
    plane = B(rows, cols);

    selected_rows = build_gcs_patterns(Ph, Pw, SR_per_bit(bit_idx));   % now returns indices
    Q = simulate_bucket_signal(selected_rows, plane, 0, N);             % N passed explicitly

    rows_idx_all{bit_idx} = selected_rows;
    Q_all{bit_idx} = Q;
    rows_all{bit_idx} = rows;
    cols_all{bit_idx} = cols;
end


clear Hfull   


% reconstructing all 8 bit-planes in parallel 
results = cell(8,1);

parfor bit_idx = 1:8
    if bit_idx <= 4
        user_opts = struct('tol', 1e-4, 'maxit', 500);
    else
        user_opts = struct('tol', 1e-2, 'maxit', 100);
    end

    t_plane = tic;
    plane_star = recon_tval3(rows_idx_all{bit_idx}, Q_all{bit_idx}, Ph, Pw, user_opts);
    fprintf('TVAL3 (bit %d): %.2fs\n', bit_idx, toc(t_plane));

    results{bit_idx} = struct('rows', rows_all{bit_idx}, 'cols', cols_all{bit_idx}, 'plane_star', plane_star);
end

% stitching the 8 independently-reconstructed planes
B_star = false(H, W);
for bit_idx = 1:8
    r = results{bit_idx};
    B_star(r.rows, r.cols) = r.plane_star >= 0.5;
end






% decoding reconstructed image
[U_star, L_star] = disassemble_binary_image(B_star);
O_star = binary_to_gray(U_star, L_star);

total_time=toc;

% metrics
[psnr_val, ssim_val] = evaluate_metrics(O, O_star);
display_comparison(img, O, O_star, psnr_val, ssim_val, total_time);
fprintf('Total time taken: %.2f seconds\n', total_time);

% saving figure
results_dir = fullfile(proj_root, 'results', 'figures');
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

fig_name = sprintf('res_%s_%d.png', img_name, sh);
saveas(gcf, fullfile(results_dir, fig_name));
fprintf('Figure saved to: %s\n', fullfile(results_dir, fig_name));


% Export for U-Net super-resolution
unet_dir = fullfile(proj_root, 'unet', 'inputs');
if ~exist(unet_dir, 'dir')
    mkdir(unet_dir);
end

O_star_norm = double(O_star) / 255;
O_norm      = double(O) / 255;

save(fullfile(unet_dir, sprintf('un_ip_%s_%d.mat', img_name, sh)), 'O_star_norm', 'O_norm', '-v7');

fprintf('Saved U-Net input: %s\n', fullfile(unet_dir, sprintf('un_in_%s_%d.mat', img_name, sh)));