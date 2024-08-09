
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <stdio.h>
#include <windows.h>
#include "log.h"

typedef void cdecl vprintf_t(const char* format, va_list va);
typedef void cdecl vfprintf_t(FILE* stream, const char* format, va_list va);

static void cdecl printf_dummy(const char* format, ...) {
}
static void cdecl fprintf_dummy(FILE* stream, const char* format, va_list va) {
}

void cdecl printf_lookup(const char* format, ...) {
    printf_t* printf_func = (printf_t*)printf_dummy;
    if (HMODULE msvcrt = GetModuleHandleA("msvcrt.dll")) {
        if (printf_t* log_func = (printf_t*)GetProcAddress(msvcrt, "printf")) {
            printf_func = log_func;
        }
        if (vprintf_t* vprintf_func = (vprintf_t*)GetProcAddress(msvcrt, "vprintf")) {
            va_list va;
            va_start(va, format);
            vprintf_func(format, va);
            va_end(va);
        }
    }
    log_printf = printf_func;
}

void cdecl fprintf_lookup(FILE* stream, const char* format, ...) {
    fprintf_t* fprintf_func = (fprintf_t*)fprintf_dummy;
    if (HMODULE msvcrt = GetModuleHandleA("msvcrt.dll")) {
        if (fprintf_t* log_func = (fprintf_t*)GetProcAddress(msvcrt, "fprintf")) {
            fprintf_func = log_func;
        }
        if (vfprintf_t* vfprintf_func = (vfprintf_t*)GetProcAddress(msvcrt, "vfprintf")) {
            va_list va;
            va_start(va, format);
            vfprintf_func(stream, format, va);
            va_end(va);
        }
    }
    log_fprintf = fprintf_func;
}

printf_t* log_printf = (printf_t*)&printf_lookup;
fprintf_t* log_fprintf = (fprintf_t*)&fprintf_lookup;
