% Visual walkthrough of the full grayscale SPI reconstruction pipeline:
% auto-crop -> encode -> bit-planes -> FWHT spectrum/selection -> parallel reconstruction -> reassembly -> decode

clear; clc; close all;

proj_root = fullfile(fileparts(mfilename('fullpath')), '..');
addpath(genpath(fullfile(proj_root,'core')));
addpath(genpath(fullfile(proj_root,'metrics')));
addpath(genpath(fullfile(proj_root,'TVAL3')));

out_dir = fullfile(proj_root, 'results', 'figures', 'pipeline');
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

% Stage 0: Load image 
img_path = fullfile(proj_root,'data','images','lena512.jpg');
img = imread(img_path);
if size(img,3)==3, img = rgb2gray(img); end

% Stage 1: Auto-crop 
edges   = edge(img, 'Canny');
density = imgaussfilt(double(edges), 15);
thresh  = 0.25 * max(density(:));
mask    = density > thresh;
mask    = imopen(mask, strel('disk',3));
mask    = imclose(mask, strel('disk',5));
mask    = imfill(mask, 'holes');

O = auto_crop_saliency(img, [64 64], 0.15);
O = uint8(O * 255);
O = imsharpen(O, 'Radius', 1, 'Amount', 1.5);
[sh, ~] = size(O);

f1 = figure('Color','w','Position',[100 100 1100 350]);
subplot(1,3,1); imshow(img); title('Original image');
subplot(1,3,2); imshowpair(img, mask, 'montage'); title('Saliency mask (edge density)');
subplot(1,3,3); imshow(O); title(sprintf('Auto-cropped + resized (%dx%d)', sh, sh));
sgtitle('Stage 1: Auto-Crop to Salient Region');
saveas(f1, fullfile(out_dir, '1_autocrop.png'));

% Stage 2: Encode O -> B 
B = encode_grayscale(O);
[H, W] = size(B);
Hhalf = H/2; Ph = Hhalf; Pw = W/4; N = Ph*Pw;

f2 = figure('Color','w','Position',[100 100 800 400]);
subplot(1,2,1); imshow(O); title(sprintf('O (%dx%d grayscale)', sh, sh));
subplot(1,2,2); imshow(B); title(sprintf('B (%dx%d binary, bit-plane encoded)', H, W));
sgtitle('Stage 2: Bit-Plane Encoding (O \rightarrow B)');
saveas(f2, fullfile(out_dir, '2_encode.png'));

% Stage 3: Extract & display all 8 bit-planes 
bit_labels = {'b7 (MSB)','b6','b5','b4','b3','b2','b1','b0 (LSB)'};
SR_per_bit = [0.90 0.75 0.55 0.35, 0.20 0.12 0.07 0.04];

planes = cell(8,1);
f3 = figure('Color','w','Position',[100 100 1400 700]);
for bit_idx = 1:8
    blk = ceil(bit_idx/4);
    off = mod(bit_idx-1,4) + 1;
    rows = (blk-1)*Hhalf + (1:Hhalf);
    cols = off:4:W;
    planes{bit_idx} = B(rows, cols);

    subplot(2,4,bit_idx);
    imshow(planes{bit_idx});
    title(sprintf('%s  |  SR=%.2f', bit_labels{bit_idx}, SR_per_bit(bit_idx)));
end
sgtitle('Stage 3: 8 Individual Bit-Planes (extracted from B)');
saveas(f3, fullfile(out_dir, '3_bitplanes.png'));

% Stage 4: FWHT spectrum + Gray-code selection (illustrative, bit 1 & bit 8) 
f4 = figure('Color','w','Position',[100 100 1200 500]);
demo_bits = [1, 8];   % show highest-SR and lowest-SR planes for contrast
for k = 1:2
    bit_idx = demo_bits(k);
    x = double(planes{bit_idx}(:));
    full_spec = fwht_local(x, N);

    selected_rows = build_gcs_patterns(Ph, Pw, SR_per_bit(bit_idx));
    M = numel(selected_rows);

    subplot(2,2,(k-1)*2+1);
    stem(abs(full_spec), 'Marker','none'); hold on;
    stem(selected_rows, abs(full_spec(selected_rows)), 'r', 'Marker','none');
    title(sprintf('%s: full FWHT spectrum (N=%d)', bit_labels{bit_idx}, N));
    xlabel('Coefficient index'); ylabel('|magnitude|');
    legend('unmeasured','measured (Gray-code selected)','Location','best');

    subplot(2,2,(k-1)*2+2);
    sel_mask = false(N,1); sel_mask(selected_rows) = true;
    imagesc(reshape(sel_mask, Ph, Pw)); colormap(gca, gray); axis image off;
    title(sprintf('%s: which pixels measured (M=%d / N=%d = %.0f%%)', ...
        bit_labels{bit_idx}, M, N, 100*M/N));
end
sgtitle('Stage 4: FWHT Spectrum & Gray-Code Coefficient Selection');
saveas(f4, fullfile(out_dir, '4_fwht_spectrum.png'));

% Stage 5: Parallel reconstruction (timed)
rows_idx_all = cell(8,1); Q_all = cell(8,1);
rows_all = cell(8,1); cols_all = cell(8,1);

for bit_idx = 1:8
    blk = ceil(bit_idx/4);
    off = mod(bit_idx-1,4) + 1;
    rows = (blk-1)*Hhalf + (1:Hhalf);
    cols = off:4:W;
    selected_rows = build_gcs_patterns(Ph, Pw, SR_per_bit(bit_idx));
    Q = simulate_bucket_signal(selected_rows, planes{bit_idx}, 0, N);
    rows_idx_all{bit_idx} = selected_rows;
    Q_all{bit_idx} = Q;
    rows_all{bit_idx} = rows;
    cols_all{bit_idx} = cols;
end

results = cell(8,1);
plane_times = zeros(8,1);

t_total = tic;
parfor bit_idx = 1:8
    if bit_idx <= 4
        user_opts = struct('tol', 1e-4, 'maxit', 500);
    else
        user_opts = struct('tol', 1e-2, 'maxit', 100);
    end
    t_plane = tic;
    plane_star = recon_tval3(rows_idx_all{bit_idx}, Q_all{bit_idx}, Ph, Pw, user_opts);
    plane_times(bit_idx) = toc(t_plane);
    results{bit_idx} = struct('rows', rows_all{bit_idx}, 'cols', cols_all{bit_idx}, ...
                               'plane_star', plane_star >= 0.5);
end
total_parallel_time = toc(t_total);

f5 = figure('Color','w','Position',[100 100 700 400]);
bar(plane_times);
set(gca,'XTickLabel', bit_labels);
ylabel('Reconstruction time (s)');
title(sprintf('Stage 5: Per-Bit-Plane Reconstruction Time (parfor)\nTotal wall-clock: %.2fs (vs sum=%.2fs sequential-equivalent)', ...
    total_parallel_time, sum(plane_times)));
grid on;
saveas(f5, fullfile(out_dir, '5_parallel_timing.png'));

% Stage 6: Reassemble B_star 
B_star = false(H, W);
for bit_idx = 1:8
    r = results{bit_idx};
    B_star(r.rows, r.cols) = r.plane_star;
end

f6 = figure('Color','w','Position',[100 100 800 400]);
subplot(1,2,1); imshow(B);      title('B (ground truth)');
subplot(1,2,2); imshow(B_star); title('B\_star (reassembled from 8 planes)');
sgtitle('Stage 6: Reassembly of Reconstructed Bit-Planes');
saveas(f6, fullfile(out_dir, '6_reassembly.png'));

% Stage 7: Decode + final comparison 
[U_star, L_star] = disassemble_binary_image(B_star);
O_star = binary_to_gray(U_star, L_star);
[psnr_val, ssim_val] = evaluate_metrics(O, O_star);

f7 = figure('Color','w','Position',[100 100 1000 400]);
subplot(1,3,1); imshow(img);    title('Original (pre-crop)');
subplot(1,3,2); imshow(O);      title('O (target, cropped+resized)');
subplot(1,3,3); imshow(O_star); title(sprintf('O\\_star (reconstructed)\nPSNR=%.2fdB  SSIM=%.4f', psnr_val, ssim_val));
sgtitle('Stage 7: Final Decode & Comparison');
saveas(f7, fullfile(out_dir, '7_final_comparison.png'));

fprintf('\nAll pipeline stage figures saved to: %s\n', out_dir);
fprintf('Total parallel reconstruction time: %.2fs\n', total_parallel_time);
fprintf('Final PSNR: %.2f dB | SSIM: %.4f\n', psnr_val, ssim_val);


%  Local FWHT helper (mirrors what's used in simulate_bucket_signal)
function y = fwht_local(x, N)
    if exist('fwht','file') == 2
        y = fwht(x, N) * N;
    else
        x = x(:); y = x; h = 1;
        while h < N
            for i = 1:2*h:N
                for j = i:(i+h-1)
                    a = y(j); b = y(j+h);
                    y(j) = a+b; y(j+h) = a-b;
                end
            end
            h = h*2;
        end
    end
end