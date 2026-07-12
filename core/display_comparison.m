function display_comparison(img,O,O_star,psnr_val,ssim_val, total_time)

    figure('Color','w');

    subplot(1,3,1)
    imshow(uint8(img),[]);
    title('Original');
    
    subplot(1,3,2)
    imshow(uint8(O),[]);
    title('Original');
    
    subplot(1,3,3)
    imshow(uint8(O_star),[]);
    title(sprintf('Reconstructed\nPSNR = %.2f dB, SSIM = %.4f\nTime = %0.2f s', psnr_val, ssim_val, total_time));

end