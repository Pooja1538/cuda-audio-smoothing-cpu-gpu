#output, input in waveform

import numpy as np
import matplotlib.pyplot as plt

def read_raw_wav(filename):
    with open(filename, "rb") as f:
        f.read(44)  # skip header
        data = np.frombuffer(f.read(), dtype=np.int16)
    return data

# Read files
input_audio = read_raw_wav("input.wav")
cpu_audio = read_raw_wav("output_cpu.wav")
gpu_audio = read_raw_wav("output_gpu.wav")

# Take smaller chunk for clear graph
N = 1000
input_audio = input_audio[:N]
cpu_audio = cpu_audio[:N]
gpu_audio = gpu_audio[:N]

# Plot
plt.figure(figsize=(12,5))

plt.plot(input_audio, label="Original", alpha=0.7)
plt.plot(cpu_audio, label="CPU Smoothed", alpha=0.7)
plt.plot(gpu_audio, label="GPU Smoothed", alpha=0.7)

plt.title("Audio Waveform Comparison")
plt.xlabel("Sample Index")
plt.ylabel("Amplitude")
plt.legend()
plt.grid()

plt.show()
