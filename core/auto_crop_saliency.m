function img_cropped = auto_crop_saliency(img, target_size, margin_frac)
%AUTO_CROP_SALIENCY Automatically crop to the visually "busiest"/most
%salient region of an image, using edge-density as a proxy for interest.
%
% INPUTS:
%   img          : grayscale image (any size)
%   target_size  : [rows cols] final crop-and-resize target, e.g. [64 64]
%   margin_frac  : fraction of bounding box size to pad on each side
%                  (default 0.15 = 15% padding)
%
% OUTPUT:
%   img_cropped  : img cropped to the salient region and resized to target_size

if nargin < 3
    margin_frac = 0.15;
end

img = im2double(img);

%% Step 1: edge map
edges = edge(img, 'Canny');

%% Step 2: smooth to find dense/busy regions (not just single edge pixels)
density = imgaussfilt(double(edges), 15);

%% Step 3: threshold to get a binary mask of "interesting" region
thresh = 0.25 * max(density(:));
mask = density > thresh;

% Safety fallback: if nothing passes threshold (near-blank image), use whole image
if ~any(mask(:))
    img_cropped = imresize(img, target_size, 'bicubic');
    warning('auto_crop_saliency: no salient region found, using full image.');
    return;
end

%% Step 4: clean up mask (remove tiny specks, fill small holes)
mask = imopen(mask, strel('disk', 3));
mask = imclose(mask, strel('disk', 5));
mask = imfill(mask, 'holes');



figure; imshowpair(img, mask, 'montage'); title('Original vs Saliency Mask');


%% Step 5: find bounding box of largest connected salient region
stats = regionprops(mask, 'BoundingBox', 'Area');
if isempty(stats)
    img_cropped = imresize(img, target_size, 'bicubic');
    warning('auto_crop_saliency: no connected region found, using full image.');
    return;
end
[~, idx] = max([stats.Area]);
bbox = stats(idx).BoundingBox;   % [x y width height]

%% Step 6: add margin/padding around the bounding box
[Ny, Nx] = size(img);
pad_x = bbox(3) * margin_frac;
pad_y = bbox(4) * margin_frac;

x1 = max(1,  bbox(1) - pad_x);
y1 = max(1,  bbox(2) - pad_y);
x2 = min(Nx, bbox(1) + bbox(3) + pad_x);
y2 = min(Ny, bbox(2) + bbox(4) + pad_y);

crop_rect = [x1, y1, (x2-x1), (y2-y1)];

%% Step 7: crop and resize to target
img_region = imcrop(img, crop_rect);
img_cropped = imresize(img_region, target_size, 'bicubic');


end