#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <utility>
#include <string>
#include <string_view>
#include <vector>
#include <unordered_set>
#include <unordered_map>
#include <array>

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

#define DEBUG_PRINTING 0

// Workaround for a parsing bug of some sort...?
#define REMOVE_SEMICOLONS 1

#define RENAME_LOCALS 1

#define BLOCK_COMPRESSION 1

/*
struct ScopeTracker {
    size_t current_scope;
    std::vector<size_t> scope_start_indices;

    inline void start_scope(size_t index) {
        this->current_scope = index;
        this->scope_start_indices.push_back(index);
    }

    inline void end_scope() {
        this->current_scope = this->scope_start_indices.cend()[-1];
        this->scope_start_indices.pop_back();
    }
};
*/

#if RENAME_LOCALS
struct LocalTokens {

    static inline constexpr auto replacement_cycle = []() constexpr {
        std::array<char, 256> cycle = {};
        for (size_t i = 0; i < 9; ++i) {
            cycle['0' + i] = '0' + i + 1;
        }
        cycle['9'] = '_';
        cycle['_'] = 'a';
        for (size_t i = 0; i < 26; ++i) {
            cycle['a' + i] = 'a' + i + 1;
        }
        cycle['z'] = 'A';
        for (size_t i = 0; i < 26; ++i) {
            cycle['A' + i] = 'A' + i + 1;
        }
        cycle['Z'] = '0';
        return cycle;
    }();

    char* replacement_buffer = NULL;
    size_t replacement_length = 0;

    std::unordered_map<std::string_view, std::string_view> tokens;
    std::unordered_set<std::string_view> non_swap_tokens;

    std::string_view generate_replacement() {
        char* buffer = this->replacement_buffer;
        size_t length = this->replacement_length;

        do {
            if (length) {
                for (size_t i = length - 1; i; --i) {
                    char replacement = replacement_cycle[buffer[i]];
                    buffer[i] = replacement;
                    if (replacement != 'a') {
                        continue;
                    }
                }
                char replacement = replacement_cycle[buffer[0]];
                if (replacement != '0') {
                    buffer[0] = replacement;
                    continue;
                }
                buffer[0] = 'a';
            }
            buffer = (char*)realloc(buffer, ++length);
            buffer[length - 1] = 'a';
        } while (
            this->non_swap_tokens.find(std::string_view(buffer, length)) != this->non_swap_tokens.end()
        );
        this->replacement_length = length;
        this->replacement_buffer = buffer;
        char* persist = (char*)malloc(length + 1);
        persist[length] = '\0';
        memcpy(persist, buffer, length);
        return std::string_view(persist, length);
    }

    std::string_view map_token(std::string_view token) {
        auto token_data = this->tokens.find(token);
        if (token_data != this->tokens.end()) {
            return token_data->second;
        }
        else {
            this->non_swap_tokens.insert(token);
            return {};
        }
    }

    std::string_view add_token(std::string_view token) {
        auto token_data = this->tokens.find(token);
        if (token_data != this->tokens.end()) {
            return token_data->second;
        }
        else {
            std::string_view replacement = this->generate_replacement();
            this->tokens.insert_or_assign(token, replacement);
            return replacement;
        }
    }
};

#define RENAME_LOCALS_VAL(...) __VA_ARGS__
#else
#define RENAME_LOCALS_VAL(...)
#endif

int main(int argc, char* argv[]) {
    if (argc <= 1) {
        error_exit(
            "Usage:\n"
            "condense_nut input_path [output_filename]"
#if RENAME_LOCALS
            " [mapping_output]"
#endif
            "\n"
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
#if RENAME_LOCALS
    bool token_is_local = false;
    bool token_is_foreach = false;
#endif
    uint8_t comment_type = 0; // 1 = single, 2 = multi
    uint8_t string_type = 0; // 1 = double quote, 2 = verbatim, 3 = single quote
#if RENAME_LOCALS
    LocalTokens local_map;
#endif
#if DEBUG_PRINTING
    size_t line_number = 1;
#endif

    std::string_view prev_token = ""sv;
#if BLOCK_COMPRESSION
    // Should this have been an array? Probably
    std::string_view prev_prev_token = ""sv;
    bool is_lambda = false;
#endif

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

    auto end_token = [&](
#if RENAME_LOCALS
        bool preserve_local_state = false
#endif
        ) {
        if (is_token) {
            is_token = false;
            std::string_view new_token = std::string_view(token_start, current - token_start);
#if RENAME_LOCALS
            std::string_view replacement;
            if (token_is_local) {
                if (new_token != "function"sv) {
                    token_is_local = preserve_local_state;
                    if (!new_token.empty()) {
                        replacement = local_map.add_token(new_token);
#if DEBUG_PRINTING
                        printf(
                            "Add  \"%.*s\"<-\"%.*s\" on line %zu\n"
                            , (int)new_token.length(), new_token.data(), (int)replacement.length(), replacement.data(), line_number
                        );
#endif
                        goto rewrite_chars;
                    }
                }
            }
            else if (prev_token != "."sv) {
                if (!new_token.empty()) {
                    replacement = local_map.map_token(new_token);
                    if (!replacement.empty()) {
                    rewrite_chars:
                        out_buf_write -= new_token.length();
#if DEBUG_PRINTING
                        printf(
                            "Swap \"%.*s\"<-\"%.*s\" on line %zu\n"
                            , (int)new_token.length(), new_token.data(), (int)replacement.length(), replacement.data(), line_number
                        );
#endif
                        memcpy(out_buf_write, replacement.data(), replacement.length());
                        out_buf_write += replacement.length();
                        new_token = replacement;
                    }
                }
            }
#endif
#if BLOCK_COMPRESSION
            prev_prev_token = prev_token;
#endif
            prev_token = new_token;
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
#if BLOCK_COMPRESSION
                            prev_prev_token = prev_token;
#endif
                            prev_token = "\""sv;
                            string_type = 1 + (prev_c == '@');
                            break;
                        case '\'':
                            can_fold = false;
                            is_token = false;
#if BLOCK_COMPRESSION
                            prev_prev_token = prev_token;
#endif
                            prev_token = "'"sv;
                            string_type = 3;
                            break;
                        case '\r':
                            end_token();
                            c = prev_c;
                            continue;
                        case '\n': handle_newline:
#if DEBUG_PRINTING
                            ++line_number;
#endif
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
#if RENAME_LOCALS
                            // I have no idea why this can't just be end_token()
                            if (is_token) {
                                end_token();
                                start_token();
                            }
#endif
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
#if RENAME_LOCALS
                                token_is_foreach = false;
#endif
                                end_token();
                                if (
                                    prev_token.ends_with(')') ||
                                    prev_token.ends_with('"') ||
                                    prev_token.ends_with('\'')
                                ) {
                                    continue;
                                }
                                //end_token();
                                break;
                            }
                            [[fallthrough]];
                        case '\0': handle_whitespace: {
                            end_token(RENAME_LOCALS_VAL(token_is_foreach));
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
                                    !can_fold
                                ) {
                                    if (prev_token == "else"sv) {
                                        can_fold = true;
                                        for (size_t j = i; j < size; ++j) {
                                            switch (char c2 = buffer[j]) {
                                                case '\n':
#if DEBUG_PRINTING
                                                    ++line_number;
#endif
                                                case ' ': case '\t': case '\r':
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
                                        break;
                                    }
#if RENAME_LOCALS
                                    if (prev_token == "local"sv || prev_token == "const"sv) {
                                        can_fold = true;
                                        token_is_local = true;
                                        break;
                                    }
                                    if (prev_token == "foreach"sv) {
                                        token_is_foreach = true;
#if DEBUG_PRINTING
                                        printf("foreach on line %zu\n", line_number);
#endif
                                        goto skip_whitespace;
                                    }
#endif
#if BLOCK_COMPRESSION
                                    bool is_return;
#endif
                                    if (
                                        (
#if BLOCK_COMPRESSION
                                            is_return =
#endif
                                            (prev_token == "return"sv || prev_token == "yield"sv)
                                        ) ||
                                        prev_token == "throw"sv || prev_token == "delete"sv ||
                                        prev_token == "resume"sv || prev_token == "extends"sv ||
                                        prev_token == "in"sv || prev_token == "instanceof"sv ||
                                        prev_token == "typeof"sv || prev_token == "case"sv ||
                                        prev_token == "clone"sv
                                    ) {
                                        can_fold = true;
#if BLOCK_COMPRESSION
                                        if (is_return) {
                                            if (prev_prev_token == "function"sv) {
                                                out_buf_write -= 17;
                                                *out_buf_write++ = '@';
                                                *out_buf_write++ = '(';
                                                *out_buf_write++ = ')';
                                                is_lambda = true;
                                                goto skip_whitespace;
                                            }
                                        }
                                        prev_prev_token = prev_token;
#endif
                                        prev_token = ""sv;
                                        for (size_t j = i; j < size; ++j) {
                                            switch (char c2 = buffer[j]) {
                                                case '\n':
#if DEBUG_PRINTING
                                                    ++line_number;
#endif
                                                case ' ': case '\t': case '\r':
                                                    continue;
                                                case '\'': case '"': case ':': case '{': case '[': case '(':
                                                    i = j;
                                                    c = c2;
                                                    goto skip_whitespace;
                                                default:
                                                    goto print_char;
                                            }
                                        }
                                        break;
                                    }
                                    if (
#if !RENAME_LOCALS
                                        prev_token == "local"sv || prev_token == "const"sv ||
#endif
                                        prev_token == "function"sv || prev_token == "class"sv ||
                                        prev_token == "static"sv || prev_token == "enum"sv

                                    ) {
                                        can_fold = true;
                                        break;
                                    }
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
#if !RENAME_LOCALS
                            end_token();
#endif
                            pre_comment = true;
                            [[fallthrough]];
                        case '*':
#if RENAME_LOCALS
                            end_token();
#endif
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
                        case '}':
#if BLOCK_COMPRESSION
                            if (is_lambda) {
                                is_lambda = false;
                                continue;
                            }
#endif
                        case ')': case ']':
                            end_token();
                            if (prev_printed_c == '\n') {
                                --out_buf_write;
                            }
#if BLOCK_COMPRESSION
                            if (c == '}') {
                                // Eliminate empty else blocks
                                if (prev_token == "else"sv) {
                                    prev_prev_token = prev_token;
                                    prev_token = ""sv;
                                    out_buf_write -= 6;
                                    continue;
                                }
                                else if (
                                    // Eliminate empty braces from function/catch blocks
                                    prev_printed_c == '{' &&
                                    (
                                        prev_token == "function"sv || prev_prev_token == "function"sv ||
                                        prev_prev_token == "catch"sv
                                    )
                                ) {
                                    prev_prev_token = prev_token;
                                    prev_token = ""sv;
                                    --out_buf_write;
                                    c = ';';
                                }
                            }
#endif
                            break;
                        case '(':
#if RENAME_LOCALS
                            //if (prev_token == "function"sv) {
                                //token_is_local = false;
                            //}
#endif
                        case '{': case '[':
                            end_token();
                            break;
#if RENAME_LOCALS
                        case ',':
                            if (token_is_local || token_is_foreach) {
                                end_token(true);
                                break;
                            }
                            [[fallthrough]];
                        case '=': case '+': case '-':
                        case '&': case '|': case '^': case '%':
                        case '<': case '>': case '!': case '~':
                            end_token();
                            can_fold = false;
                            break;
                        case '.':
                            end_token();
                            can_fold = false;
#if BLOCK_COMPRESSION
                            prev_prev_token = prev_token;
#endif
                            prev_token = "."sv; // Bit of a hack, but it kinda works?
                            break;
#endif
                        default: default_char:
                            can_fold = false;
                            start_token();
#if RENAME_LOCALS
                            token_is_local |= token_is_foreach;
#endif
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
    free(out_buf);

    if (argc > 2) {
        fclose(output);
    }

#if RENAME_LOCALS
    if (argc > 3) {
        if (FILE* mapping_out = fopen(argv[3], "wb")) {
            for (auto [token, replacement] : local_map.tokens) {
                fwrite(replacement.data(), replacement.length(), 1, mapping_out);
                fwrite("<-", 2, 1, mapping_out);
                fwrite(token.data(), token.length(), 1, mapping_out);
                fputc('\n', mapping_out);
            }
            fclose(mapping_out);
        }
    }
#endif

    free(buffer);

    return EXIT_SUCCESS;
}
