#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <utility>
#include <string_view>

using namespace std::literals::string_view_literals;

[[noreturn]] static void error_exit(const char* message) {
    fputs(message, stderr);
    exit(EXIT_FAILURE);
}

[[nodiscard]] inline auto read_file_to_string(const char* path) {
    long file_size = 0;
    char* buffer = NULL;
    if (FILE* file = fopen(path, "rb")) {
        fseek(file, 0, SEEK_END);
        file_size = ftell(file);
        if ((buffer = (char*)malloc(file_size + 1))) {
            rewind(file);
            fread(buffer, file_size, 1, file);
            buffer[file_size++] = '\0';
        }
        fclose(file);
    }
    return std::make_pair(buffer, file_size);
}

int main(int argc, char* argv[]) {
    if (argc <= 1) {
        error_exit(
            "Usage:\n"
            "condense_nut input_path [output_filename]\n"
        );
    }

    auto [buffer, size] = read_file_to_string(argv[1]);
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

    char* buffer_read = buffer;

    char* out_buf = (char*)malloc(size);
    char* out_buf_write = out_buf;


    char* token_start = buffer;
    bool is_token = false;
    bool is_string = false;
    bool can_fold = false;
    bool pre_comment = false;
    bool pre_namespace = false;
    uint8_t comment_type = 0; // 1 = single, 2 = multi

    std::string_view prev_token = ""sv;

    char c = '\0';
    char prev_c = '\0';

    char* current;

    auto end_token = [&]() {
        if (is_token) {
            is_token = false;
            prev_token = std::string_view(token_start, current - token_start);
        }
    };

    for (
        size_t i = 0;
        i < size;
        prev_c = c
    ) {
        current = buffer + i++;
        c = *current;
        if (c == '"') {
            can_fold = false;
            if (is_string) {
                is_string = prev_c == '\\';
            } else {
                is_string = true;
            }
        }
        else if (!is_string) {
            switch (c) {
                    if (0) {
                case '\n':
                        if (comment_type == 1) {
                            comment_type = 0;
                        }
                    } else {
                case '\t':
                        c = ' ';
                case ' ': 
                        if (
                            current[1] == 'i' && current[2] == 'n' &&
                            (current[3] == ' ' || current[3] == '\t')
                        ) {
                            end_token();
                            break;
                        }
                    }
                case ';': case '\0':
                    end_token();
                    if (c != ';') {
                        if (
                            prev_token == "function"sv || prev_token == "else"sv || prev_token == "local"sv ||
                            prev_token == "in"sv || prev_token == "case"sv || prev_token == "return"sv || prev_token == "class"sv
                        ) {
                            if (!can_fold) {
                                can_fold = true;
                                if (prev_token == "else"sv) {
                                    c = ' ';
                                }
                                break;
                            }
                        }
                case '\r':
                        continue;
                    } else {
                        can_fold = true;
                    }
                    break;
                case '/':
                    pre_comment = true;
                    if (comment_type == 2) {
                        if (prev_c == '*') {
                            comment_type = 0;
                        }
                        continue;
                    }
                    [[fallthrough]];
                case '*':
                    if (prev_c == '/') {
                        pre_comment = false;
                        comment_type = 1 + (c == '*');
                        end_token();
                        continue;
                    }
                    if (pre_comment) {
                        continue;
                    }
                    break;
                    /*
                case ':':
                    if (prev_token == "}"sv) {
                        pre_namespace = true;
                        continue;
                    }
                    if (pre_namespace) {
                        *out_buf_write++ = ' ';
                    }
                    break;
                case 'i':
                    if (current[1] == 'f' && prev_token == "}"sv) {
                        *out_buf_write++ = ' ';
                    }
                    break;
                    */
                default:
                    can_fold = false;
                    if (!is_token) {
                        is_token = true;
                        token_start = current;
                    }
                    break;
            }
        }
        if (comment_type == 0) {
            if (pre_comment) {
                pre_comment = false;
                *out_buf_write++ = '/';
            }
            if (pre_namespace) {
                pre_namespace = false;
                *out_buf_write++ = ':';
            }
            *out_buf_write++ = c;
        }
    }

    fwrite(out_buf, out_buf_write - out_buf, 1, output);

    free(buffer);
    free(out_buf);

    if (argc > 2) {
        fclose(output);
    }

    return EXIT_SUCCESS;
}
