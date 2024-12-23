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
    bool can_fold = false;
    bool pre_comment = false;
    bool pre_namespace = false;
#if REMOVE_SEMICOLONS
    bool pre_semicolon = false;
#endif
    uint8_t comment_type = 0; // 1 = single, 2 = multi
    uint8_t string_type = 0; // 1 = double quote, 2 = verbatim, 3 = single quote

    std::string_view prev_token = ""sv;

    char c = '\0';
    char prev_c = '\0';
    char prev_printed_c = '\0';

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
        if (comment_type) {
            switch (c) {
                case '\n':
                    if (comment_type == 1) {
                        comment_type = 0;
                        c = ' ';
                        goto handle_newline;
                    }
                    break;
                case '/':
                    if (comment_type == 2) {
                        if (prev_c == '*') {
                            comment_type = 0;
                            c = ' ';
                            goto handle_whitespace;
                        }
                    }
            }
            c = prev_c;
            continue;
        }
        else {
            switch (string_type) {
                // TODO: Calculate which string type be smaller and convert between them
                case 1: // Double quote string
                    if (c == '"' && prev_c != '\\') {
                        string_type = 0;
                    }
                    break;
                case 2: // Verbatim string
                    if (c == '"') {
                        if (prev_c != '"') {
                            string_type = 0;
                        } else {
                            prev_c = 0;
                        }
                    }
                    break;
                case 3: // Single quote string
                    if (c == '\'' && prev_c != '\\') {
                        string_type = 0;
                    }
                    break;
                default:
                    switch (c) {
                        case '"':
                            can_fold = false;
                            is_token = false;
                            prev_token = "\""sv;
                            string_type = 1 + (prev_c == '@');
                            break;
                        case '\'':
                            can_fold = false;
                            is_token = false;
                            prev_token = "'"sv;
                            string_type = 3;
                            break;
                        case '\r':
                            end_token();
                            c = prev_c;
                            continue;
                        case '\n': handle_newline:
#if REMOVE_SEMICOLONS
                            if (pre_semicolon) {
                                pre_semicolon = false;
                                *out_buf_write++ = '\n';
                                prev_printed_c = '\n';
                            }

                            if (prev_c == '}') {
                                end_token();
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
                            
                            // Special handling for keywords that must have
                            // whitespace beforehand in most cases
                            if (
                                // "in" and "instanceof"
                                (
                                    current[1] == 'i' && current[2] == 'n' &&
                                    (
                                        (current[3] == ' ' || current[3] == '\t' || current[3] == ':') ||
                                        (
                                            current[3] == 's' && current[4] == 't' && current[5] == 'a' && current[6] == 'n' && current[7] == 'c' &&
                                            current[8] == 'e' && current[9] == 'o' && current[10] == 'f' && (current[11] == ' ' || current[11] == '\t' || current[11] == ':')
                                        )
                                    )
                                ) ||
                                // "extends"
                                (
                                    current[1] == 'e' && current[2] == 'x' && current[3] == 't' &&
                                    current[4] == 'e' && current[5] == 'n' && current[6] == 'd' &&
                                    current[7] == 's' && (current[8] == ' ' || current[8] == '\t' || current[8] == ':')
                                ) ||
                                // "typeof"
                                (
                                    current[1] == 't' && current[2] == 'y' && current[3] == 'p' &&
                                    current[4] == 'e' && current[5] == 'o' && current[6] == 'f' &&
                                    (current[7] == ' ' || current[7] == '\t' || current[7] == ':')
                                )
                            ) {
                                if (
                                    prev_token.ends_with(')') ||
                                    prev_token.ends_with('"') ||
                                    prev_token.ends_with('\'')
                                ) {
                                    continue;
                                }
                                end_token();
                                break;
                            }
                            [[fallthrough]];
                        case '\0': handle_whitespace: {
                            end_token();
#if !REMOVE_SEMICOLONS
                            if (c != ';') {
#endif
                                bool prev_is_else = false;
                                bool next_ends_token = false;
                                //bool next_can_bracket_or_colon = false;
                                
                                // Valid keyword characters
                                // 
                                // Nothing special:
                                // base, break, catch, continue, default, do, for, foreach,
                                // if, null, switch, this, try, while, true, false, rawcall,
                                // constructor
                                // 
                                // Needs whitespace afterwards:
                                // local, const, class, static
                                // 
                                // Needs valid token end afterwards (whitespace, ", ', :, (, [, {):
                                // return, yield, throw, delete, case, resume, clone
                                //
                                // Needs valid token end before and after:
                                // in, instanceof, typeof, extends
                                //

                                if (
                                    !can_fold &&
                                    (
                                        prev_token == "local"sv || prev_token == "const"sv ||
                                        prev_token == "class"sv || prev_token == "static"sv ||
                                        prev_token == "enum"sv || prev_token == "function"sv ||
                                        (prev_is_else = prev_token == "else"sv) ||
                                        (next_ends_token = (
                                            prev_token == "return"sv || prev_token == "yield"sv ||
                                            prev_token == "throw"sv || prev_token == "delete"sv ||
                                            prev_token == "resume"sv || prev_token == "extends"sv ||
                                            prev_token == "in"sv || prev_token == "instanceof"sv ||
                                            prev_token == "typeof"sv || prev_token == "case"sv ||
                                            prev_token == "clone"sv
                                        ))
                                    )
                                ) {
                                    can_fold = true;
                                    if (prev_is_else) {
                                        for (size_t j = i; j < size; ++j) {
                                            switch (char c2 = buffer[j]) {
                                                case ' ': case '\t': case '\r': case '\n':
                                                    continue;
                                                case 'i':
                                                    if (buffer[j + 1] == 'f') {
                                                        i = j;
                                                        c = ' ';
                                                        goto print_char;
                                                    }
                                                default:
                                                    goto skip_whitespace;
                                            }
                                        }
                                    }
                                    else if (next_ends_token) {
                                        prev_token = ""sv;
                                        for (size_t j = i; j < size; ++j) {
                                            switch (char c2 = buffer[j]) {
                                                case ' ': case '\t': case '\r': case '\n':
                                                    continue;
                                                case '\'': case '"': case ':': case '{': case '[': case '(':
                                                    i = j;
                                                    c = c2;
                                                    goto skip_whitespace;
                                                default:
                                                    goto print_char;
                                            }
                                        }
                                    }
                                    /*
                                    else if (next_can_bracket_or_colon) {
                                        prev_token = ""sv;
                                        for (size_t j = i; j < size; ++j) {
                                            switch (char c2 = buffer[j]) {
                                                case ' ': case '\t': case '\r': case '\n':
                                                    continue;
                                                case ':': case '{': case '[': case '(':
                                                    i = j;
                                                    c = c2;
                                                    goto skip_whitespace;
                                                default:
                                                    goto print_char;
                                            }
                                        }
                                    }
                                    */
                                    break;
                                }
                            skip_whitespace:
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
                        case '#': // Alt single line comment
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
                        case ')': case '}': case ']':
                            end_token();
                            if (prev_printed_c == '\n') {
                                --out_buf_write;
                            }
                            break;
                        case '(':  case '{': case '[':
                            end_token();
                            break;
                        default: default_char:
                            can_fold = false;
                            start_token();
                            break;
                    }
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
            prev_printed_c = c;
        }
    }

    while (out_buf_write[-1] == '\n') {
        --out_buf_write;
    }

    // TODO:
    // Now that everything is condensed, certain
    // code patterns *should* be easier to detect.
    //
    // Single line if statements and loops
    // Empty blocks
    //

    fwrite(out_buf, out_buf_write - out_buf, 1, output);

    free(buffer);
    free(out_buf);

    if (argc > 2) {
        fclose(output);
    }

    return EXIT_SUCCESS;
}
