#cpu only


%%writefile cpu_audio.c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define HEADER_SIZE 44

int main() {
    FILE *fin = fopen("input.wav", "rb");
    FILE *fout = fopen("output_cpu.wav", "wb");

    if (!fin || !fout) {
        printf("Error opening file!\n");
        return 1;
    }

    char header[HEADER_SIZE];
    fread(header, sizeof(char), HEADER_SIZE, fin);
    fwrite(header, sizeof(char), HEADER_SIZE, fout);

    fseek(fin, 0, SEEK_END);
    int file_size = ftell(fin);
    int data_size = file_size - HEADER_SIZE;
    int num_samples = data_size / sizeof(short);

    rewind(fin);
    fseek(fin, HEADER_SIZE, SEEK_SET);

    short *input = (short*)malloc(num_samples * sizeof(short));
    short *output = (short*)malloc(num_samples * sizeof(short));

    fread(input, sizeof(short), num_samples, fin);

    clock_t start = clock();

    for (int i = 1; i < num_samples - 1; i++) {
        float temp = input[i];

        for (int j = 0; j < 100; j++) {
            temp = (input[i-1] + temp + input[i+1]) / 3.0f;
        }

        output[i] = (short)temp;
    }

    clock_t end = clock();

    double cpu_time = (double)(end - start) / CLOCKS_PER_SEC;
    printf("CPU Time: %.6f sec\n", cpu_time);

    fwrite(output, sizeof(short), num_samples, fout);

    fclose(fin);
    fclose(fout);
    free(input);
    free(output);

    return 0;
}

