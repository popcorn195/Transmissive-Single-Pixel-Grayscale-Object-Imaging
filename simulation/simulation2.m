%% pipeline_animation.m
% Renders the O -> bit-planes -> B -> measure -> reconstruct -> O_star
% pipeline as an animated GIF, using the toy example O = [[150,45],[200,15]].

clear; clc; close all;

proj_root = fullfile(fileparts(mfilename('fullpath')), '..');
out_dir = fullfile(proj_root, 'results', 'figures');
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
gif_path = fullfile(out_dir, 'pipeline_animation.gif');

%% ---------- Build the toy example ----------
O = uint8([150 45; 200 15]);
B = encode_grayscale(O);
[H, W] = size(B);
Hhalf = H/2;

planes = cell(8,1);
for bit_idx = 1:8
    blk = ceil(bit_idx/4);
    off = mod(bit_idx-1,4) + 1;
    rows = (blk-1)*Hhalf + (1:Hhalf);
    cols = off:4:W;
    planes{bit_idx} = B(rows, cols);
end

[U_star, L_star] = disassemble_binary_image(B);   % exact round-trip for this noiseless demo
O_star = binary_to_gray(U_star, L_star);

%% ---------- Frame rendering ----------
fig = figure('Color','w','Position',[100 100 500 500], 'Visible','off');
delay_time = 1.5;
labels = {'b7','b6','b5','b4','b3','b2','b1','b0'};

titles = {'1. Original image O', '2. Split into 8 bit-planes', ...
          '3. Assembled into B', '4. Measured with FWHT patterns', ...
          '5. Reconstructed (TVAL3)', '6. Decoded back to grayscale'};

for k = 1:6
    clf(fig);

    if k == 2
        for i = 1:8
            subplot(1,8,i);
            imshow(imresize(double(planes{i}), 8, 'nearest'), [0 1]);
            title(labels{i}, 'FontSize', 9);
        end
    elseif k == 1
        imshow(imresize(double(O)/255, 40, 'nearest'), [0 1]);
    elseif k == 6
        imshow(imresize(double(O_star)/255, 40, 'nearest'), [0 1]);
    else
        imshow(imresize(double(B), 16, 'nearest'), [0 1]);
    end

    sgtitle(titles{k}, 'FontSize', 13);
    drawnow;

    frame = getframe(fig);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);

    if k == 1
        imwrite(imind, cm, gif_path, 'gif', 'Loopcount', inf, 'DelayTime', delay_time);
    else
        imwrite(imind, cm, gif_path, 'gif', 'WriteMode', 'append', 'DelayTime', delay_time);
    end
end

close(fig);
fprintf('Saved animation: %s\n', gif_path);