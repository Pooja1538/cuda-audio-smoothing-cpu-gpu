#cpu gpu together


%%writefile audio_gpu.cu
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define HEADER_SIZE 44

// ================= GPU KERNEL =================
__global__ void smooth(short *input, short *output, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;

    if (i > 0 && i < n - 1) {
        float temp = input[i];

        for (int j = 0; j < 90; j++) {
            temp = (input[i-1] + temp + input[i+1]) / 3.0f;
        }

        output[i] = (short)temp;
    }
}

// ================= MAIN =================
int main() {

    FILE *fin = fopen("input.wav", "rb");
    FILE *fout_cpu = fopen("output_cpu.wav", "wb");
    FILE *fout_gpu = fopen("output_gpu.wav", "wb");

    if (!fin || !fout_cpu || !fout_gpu) {
        printf("File error\n");
        return 1;
    }

    // Copy header
    char header[HEADER_SIZE];
    fread(header, sizeof(char), HEADER_SIZE, fin);
    fwrite(header, sizeof(char), HEADER_SIZE, fout_cpu);
    fwrite(header, sizeof(char), HEADER_SIZE, fout_gpu);

    // File size
    fseek(fin, 0, SEEK_END);
    int file_size = ftell(fin);
    int data_size = file_size - HEADER_SIZE;
    int num_samples = data_size / sizeof(short);

    rewind(fin);
    fseek(fin, HEADER_SIZE, SEEK_SET);

    // Allocate memory
    short *input = (short*)malloc(num_samples * sizeof(short));
    short *cpu_out = (short*)malloc(num_samples * sizeof(short));
    short *gpu_out = (short*)malloc(num_samples * sizeof(short));

    fread(input, sizeof(short), num_samples, fin);

    // ================= CPU =================
    clock_t cpu_start = clock();

    for (int i = 1; i < num_samples - 1; i++) {
        float temp = input[i];

        for (int j = 0; j < 50; j++) {
            temp = (input[i-1] + temp + input[i+1]) / 3.0f;
        }

        cpu_out[i] = (short)temp;
    }

    clock_t cpu_end = clock();
    double cpu_time = (double)(cpu_end - cpu_start) / CLOCKS_PER_SEC;

    fwrite(cpu_out, sizeof(short), num_samples, fout_cpu);

    // ================= GPU =================
    short *d_input, *d_output;
    cudaMalloc(&d_input, num_samples * sizeof(short));
    cudaMalloc(&d_output, num_samples * sizeof(short));

    int blockSize = 256;
    int gridSize = (num_samples + blockSize - 1) / blockSize;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // 🔥 FULL GPU TIMING (copy + compute + copy)
    cudaEventRecord(start);

    cudaMemcpy(d_input, input, num_samples * sizeof(short), cudaMemcpyHostToDevice);

    smooth<<<gridSize, blockSize>>>(d_input, d_output, num_samples);
    cudaDeviceSynchronize();

    cudaMemcpy(gpu_out, d_output, num_samples * sizeof(short), cudaMemcpyDeviceToHost);

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float gpu_ms;
    cudaEventElapsedTime(&gpu_ms, start, stop);

    float gpu_sec = gpu_ms / 1000.0f;

    fwrite(gpu_out, sizeof(short), num_samples, fout_gpu);

    // ================= RESULTS =================
    float speedup = cpu_time / gpu_sec;

    printf("\n===== PERFORMANCE RESULTS =====\n");
    printf("CPU Time  : %.6f sec\n", cpu_time);
    printf("GPU Time  : %.3f ms (%.6f sec)\n", gpu_ms, gpu_sec);
    printf("Speedup   : %.2fx\n", speedup);

    // Cleanup
    cudaFree(d_input);
    cudaFree(d_output);
    free(input);
    free(cpu_out);
    free(gpu_out);

    fclose(fin);
    fclose(fout_cpu);
    fclose(fout_gpu);

    return 0;
}
