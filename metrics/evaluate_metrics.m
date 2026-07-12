function [psnr_val, ssim_val] = evaluate_metrics(O, O_star)
%EVALUATE_METRICS  Compute and display PSNR and SSIM between the
%   original object O and reconstructed estimate O_star.
%
%   [psnr_val, ssim_val] = EVALUATE_METRICS(O, O_star)
%
%   INPUT
%     O      : original grayscale image
%     O_star : reconstructed grayscale image (same size as O)
%
%   OUTPUT
%     psnr_val : PSNR in dB (compute_psnr.m)
%     ssim_val : SSIM in [-1, 1] (compute_ssim.m, typically [0,1])

    if ~isequal(size(O), size(O_star))
        error('O and O_star must be the same size (got %s vs %s).', ...
            mat2str(size(O)), mat2str(size(O_star)));
    end

    O      = uint8(round(double(O)));
    O_star = uint8(round(double(O_star)));

    fprintf("O      : min=%d max=%d\n", min(O(:)),      max(O(:)));
    fprintf("O_star : min=%d max=%d\n", min(O_star(:)), max(O_star(:)));

    psnr_val = psnr(O, O_star);
    ssim_val = ssim(O, O_star);

    fprintf('--- Reconstruction Metrics ---\n');
    fprintf('PSNR : %.2f dB\n', psnr_val);
    fprintf('SSIM : %.4f\n', ssim_val);
end