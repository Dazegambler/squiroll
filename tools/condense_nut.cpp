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

// Workaround for a parsing bug of some sort...?
#define REMOVE_SEMICOLONS 1

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
#if REMOVE_SEMICOLONS
    bool pre_semicolon = false;
#endif
    uint8_t comment_type = 0; // 1 = single, 2 = multi

    std::string_view prev_token = ""sv;

    char c = '\0';
    char prev_c = '\0';

    char* current;

    auto start_token = [&]() {
        if (!is_token) {
            is_token = true;
            token_start = current;
        }
    };

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
        else if (comment_type) {
            switch (c) {
                case '\n':
                    if (comment_type == 1) {
                        comment_type = 0;
                        c = ' ';
                        goto handle_newline;
                    }
                    c = prev_c;
                    continue;
                case '/':
                    if (comment_type == 2) {
                        if (prev_c == '*') {
                            comment_type = 0;
                            c = ' ';
                            goto handle_whitespace;
                        }
                    }
                    c = prev_c;
                    continue;
                default:
                    c = prev_c;
                    continue;
            }
        }
        else if (!is_string) {
            switch (c) {
                case '\r':
                    end_token();
                    c = prev_c;
                    continue;
                case '\n': handle_newline:
#if REMOVE_SEMICOLONS
                    if (pre_semicolon) {
                        pre_semicolon = false;
                        *out_buf_write++ = '\n';
                    }
                    if (prev_c == '}') {
                        end_token();
                        //continue;
                        break;
                    }
#endif
                    goto handle_whitespace;
                case ';':
#if REMOVE_SEMICOLONS
                    pre_semicolon = true;
                    continue;
#else
                    goto handle_whitespace;
#endif
                case '\t':
                    c = ' ';
                    [[fallthrough]];
                case ' ':
                    
                    switch (current[1]) {
                        case '(': case '[': case '{':
                            can_fold = true;
                            end_token();
                            continue;
                    }
                    
                    if (
                        current[1] == 'i' && current[2] == 'n' &&
                        (
                            (current[3] == ' ' || current[3] == '\t' || current[3] == ':') ||
                            (
                                current[3] == 's' && current[4] == 't' && current[5] == 'a' && current[6] == 'n' && current[7] == 'c' &&
                                current[8] == 'e' && current[9] == 'o' && current[10] == 'f' && (current[11] == ' ' || current[11] == '\t' || current[11] == ':')
                            )
                        )
                    ) {
                        end_token();
                        break;
                    }
                    [[fallthrough]];
                case '\0': handle_whitespace: {
                    end_token();
#if !REMOVE_SEMICOLONS
                    if (c != ';') {
#endif
                        bool prev_is_function = prev_token == "function"sv;
                        bool prev_is_return = false;
                        bool prev_is_else = false;
                        bool next_can_colon = false;
                        if (
                            prev_is_function || prev_token == "local"sv || prev_token == "case"sv || 
                            (prev_is_return = prev_token == "return"sv) || prev_token == "class"sv || prev_token == "delete"sv ||
                            (next_can_colon = (prev_token == "in"sv || prev_token == "instanceof"sv)) ||
                            (prev_is_else = prev_token == "else"sv)
                        ) {
                            if (!can_fold) {
                                can_fold = true;
                                if (prev_is_else) {
                                    c = ' ';
                                    if (
                                        !(
                                            current[1] == 'i' && current[2] == 'f' && 
                                            (current[3] == ' ' || current[3] == '\t' || current[3] == '(' || current[3] == '\r' || current[3] == '\n')
                                        )
                                    ) {
                                        continue;
                                    }
                                }
                                /*
                                else if (prev_is_function) {
                                    //c = ' ';
                                    if (
                                        (current[1] == ' ' || current[1] == '\t') && current[2] == '('
                                    ) {
                                        continue;
                                    }
                                }
                                */
                                //else if (prev_is_return) {

                                //}
                                break;
                            }
                        }
                        continue;
#if !REMOVE_SEMICOLONS
                    }
                    can_fold = true;
                    break;
#endif
                }
                case '/':
                    end_token();
                    pre_comment = true;
                    [[fallthrough]];
                case '*':
                    if (prev_c == '/') {
                        pre_comment = false;
                        comment_type = 1 + (c == '*');
                        continue;
                    }
                    if (pre_comment) {
                        continue;
                    }
                    break;
                case ':':
                    if (!pre_namespace) {
                        pre_namespace = true;
                        end_token();
                        start_token();
                        continue;
                    }
                    if (prev_token == ":"sv) {
                        pre_namespace = false;
                        *out_buf_write++ = ':';
                        *out_buf_write++ = ' ';
                    }
                    break;
                case '(': case ')': case '{': case '}': case '[': case ']':
                    end_token();
                    break;
                default: default_char:
                    can_fold = false;
                    start_token();
                    break;
            }
        }
    print_char:
        if (comment_type == 0) {
            if (pre_comment) {
                pre_comment = false;
                *out_buf_write++ = '/';
            }
            if (pre_namespace) {
                pre_namespace = false;
                *out_buf_write++ = ':';
            }
#if REMOVE_SEMICOLONS
            if (pre_semicolon) {
                pre_semicolon = false;
                *out_buf_write++ = ';';
            }
#endif
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
