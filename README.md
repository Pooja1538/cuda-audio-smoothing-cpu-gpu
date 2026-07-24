# cuda-audio-smoothing-cpu-gpu
CPU vs GPU (CUDA) audio smoothing filter on WAV files — benchmarks execution time and speedup, with waveform visualization.

# CPU vs GPU Audio Smoothing (CUDA)

Applies a simple moving-average smoothing filter to raw PCM audio (WAV) samples,
implemented both on CPU (sequential C) and GPU (CUDA), and compares performance.

## Overview
Each audio sample is iteratively smoothed using its neighboring samples:
temp = (input[i-1] + temp + input[i+1]) / 3.0
repeated over multiple passes. The GPU version parallelizes this across threads
(one thread per sample) using a CUDA kernel, while the CPU version processes
samples sequentially.

## Files
- `cpu_audio.c` — CPU-only implementation, measures execution time with `clock()`
- `audio_gpu.cu` — Combined CPU + GPU (CUDA) implementation; runs both and reports
  CPU time, GPU time (including host-to-device/device-to-host transfer), and speedup
- `waveform_plot.py` — Reads the original and both processed WAV files and plots
  their waveforms for visual comparison

## How it works
input.wav → skip 44-byte WAV header → read PCM samples (int16)
→ smoothing filter (CPU sequential / GPU parallel kernel)
→ output_cpu.wav / output_gpu.wav
## Requirements
- CPU version: any C compiler (`gcc cpu_audio.c -o cpu_audio`)
- GPU version: NVIDIA GPU + CUDA toolkit (`nvcc audio_gpu.cu -o audio_gpu`)
- Plotting: `pip install numpy matplotlib`

## Usage
```bash
# Compile
gcc cpu_audio.c -o cpu_audio
nvcc audio_gpu.cu -o audio_gpu

# Run (expects input.wav in the same directory)
./cpu_audio
./audio_gpu

# Visualize
python waveform_plot.py
```

## Output
Prints CPU time, GPU time (ms and sec), and speedup factor (CPU time / GPU time).
Produces `output_cpu.wav` and `output_gpu.wav`, plus a waveform comparison plot.

## Notes
- Input WAV is assumed to be a standard 44-byte header, 16-bit PCM format.
- Smoothing pass counts differ slightly between CPU (`100`), GPU-in-combined-file (`50`),
  and the standalone GPU kernel (`90`) — align these if you want a strictly fair CPU-vs-GPU
  time comparison.
