#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <utility>

[[noreturn]] static void error_exit(const char* message) {
    fputs(message, stderr);
    exit(EXIT_FAILURE);
}

template <typename T = void>
[[nodiscard]] inline auto read_file_to_buffer(const char* path) {
    long file_size = 0;
    T* buffer = NULL;
    if (FILE* file = fopen(path, "rb")) {
        fseek(file, 0, SEEK_END);
        file_size = ftell(file);
        if ((buffer = (T*)malloc(file_size))) {
            rewind(file);
            fread(buffer, file_size, 1, file);
        }
        fclose(file);
    }
    return std::make_pair(buffer, file_size);
}

int main(int argc, char* argv[]) {
    if (argc <= 1) {
        error_exit(
            "Usage:\n"
            "make_embed input_path [output_filename]\n"
        );
    }

    auto [buffer, size] = read_file_to_buffer<uint8_t>(argv[1]);
    if (!buffer) {
        error_exit(
            "Error: Could not open input file\n"
        );
    }
    if (size <= 0) {
        error_exit(
            "Error: Input file has invalid size\n"
        );
    }

    FILE* output = stdout;
    if (argc > 2) {
        output = fopen(argv[2], "wb");
        if (!output) {
            error_exit(
                "Error: Coult not create output file\n"
            );
        }
    }

    uint8_t* buffer_read = buffer;
    
    while (--size) {
        fprintf(output,
            "0x%02X,"
            , *buffer_read++
        );
    }
    fprintf(output,
        "0x%02X"
        , *buffer_read
    );

    free(buffer);

    if (argc > 2) {
        fclose(output);
    }

    return EXIT_SUCCESS;
}
