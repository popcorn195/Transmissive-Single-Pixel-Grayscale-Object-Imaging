function display_comparison(O,O_star,psnr_val,ssim_val, total_time)

    figure('Color','w');
    
    subplot(1,2,1)
    imshow(uint8(O),[]);
    title('Original');
    
    subplot(1,2,2)
    imshow(uint8(O_star),[]);
    title(sprintf('Reconstructed\nPSNR = %.2f dB, SSIM = %.4f\nTime = %0.2f s', psnr_val, ssim_val, total_time));

end