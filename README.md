# Transmissive Single-Pixel Grayscale Object Imaging with Physics-Driven U-Net Refinement

Reconstruction of grayscale objects from single-pixel (bucket) measurements using bit-plane-encoded Hadamard sampling, per-bitplane compressive-sensing reconstruction, and a physics-driven U-Net refinement stage. Implemented in MATLAB (measurement + reconstruction) and PyTorch (U-Net refinement).

ground truth VS reconstructed image VS U-Net output
<img width="938" height="341" alt="image" src="https://github.com/user-attachments/assets/9cc53b06-18e6-4c49-941d-8aa4ec45f6b5" />



## Overview

Single-pixel imaging (SPI) recovers a 2D scene using a single photodetector by sequentially projecting known patterns and recording only the total ("bucket") intensity for each. This project targets **grayscale** object reconstruction by decomposing the target into 8 binary bit-planes, measuring and reconstructing each independently, then refining the recombined result with a learned, physics-consistent U-Net.

Core contributions:
- Bit-plane decomposition with Gray-code-ordered Hadamard sampling
- Per-bitplane TVAL3 reconstruction with an MSB-heavy tapered sampling-ratio schedule
- A physics-driven U-Net (composite loss: data fidelity + total variation + energy penalty) reused as a post-processing refinement stage to further improve SSIM

## Pipeline

```
Grayscale object (O)
      │
      ▼
Saliency-based auto-crop  (auto_crop_saliency.m)
      │
      ▼
Bit-plane decomposition   (disassemble_binary_image)  →  8 bit-planes: b7 (MSB) ... b0 (LSB)
      │
      ▼
Gray-code Hadamard measurement (per bit-plane, MSB-heavy sampling ratio)
      │
      ▼
Per-bitplane TVAL3 reconstruction  →  B_star (per-plane) → recombined O_star
      │
      ▼
Physics-driven U-Net refinement  →  final reconstruction
```

<img width="938" height="470" alt="image" src="https://github.com/user-attachments/assets/ff4e85a8-82d8-4640-a629-b0d770ac3f66" />
<img width="937" height="502" alt="image" src="https://github.com/user-attachments/assets/414b43f2-b91a-4f59-9427-39b7eb2a77bf" />
<img width="937" height="390" alt="image" src="https://github.com/user-attachments/assets/38524103-ef3f-4c9c-8ce6-a6342939f60d" />


# Optimisation
Used the following for decreasing manual and time overhead-
- Saliency-based auto-cropping utility
- Parallelisation for bit planes computation
- Tiered TVAL3 convergence
- Replaced Hadamard transform with Fast Walsh-Hadamard Transform (FWHT)


## Results
Saliency mask <br>
<img width="650" height="353" alt="image" src="https://github.com/user-attachments/assets/574a4895-93dc-40fa-8d65-d245a21fd397" />

Grayscale to binary encoding
<img width="838" height="365" alt="image" src="https://github.com/user-attachments/assets/f272d5d6-22cf-4000-b495-a9a5c66494a1" />

Extracted bit planes
<img width="938" height="537" alt="image" src="https://github.com/user-attachments/assets/13249e5f-0ba5-4208-8ec9-f0f70f4c4046" />

Binary image reconstruction
<img width="938" height="423" alt="image" src="https://github.com/user-attachments/assets/74b780dd-7cc9-4b30-90a2-c6fffa64fc55" />

Binary to grayscale decoding to get grayscale reconstructed image
<img width="937" height="320" alt="image" src="https://github.com/user-attachments/assets/9cd12818-009d-43d0-a0b3-cd8bd3dec3a7" />


## Physics-Driven U-Net

A U-Net (encoder–bottleneck–decoder with skip connections) trained with a composite loss rather than a pixel-only loss, so its output stays consistent with the imaging forward model:

- **MSE** — data fidelity to the measurement model
- **Total variation (TV)** — piecewise-smooth, natural-image prior
- **Energy penalty** — keeps output intensity consistent with the measured bucket signal

It is applied as a refinement stage on top of the per-bitplane TVAL3 output to remove residual reconstruction artefacts, particularly in the less significant bit-planes.

<img width="938" height="418" alt="image" src="https://github.com/user-attachments/assets/6c444d14-6323-4293-b5eb-cdc5485e7194" />


## Requirements
```bash
pip install torch torchvision numpy scipy matplotlib scikit-image imageio
```

## Usage

```bash
# run in matlab
core/main.m
```

```bash
# Python: U-Net refinement
python unet\untrained\train_unet.py
```

## References

- Guo et al., *Transmissive Single-Pixel Grayscale Object Imaging*, 2025
- Y. Zhang et al., TVAL3: An Efficient Compressive Sensing Reconstruction Algorithm
