
#include <windows.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include "log.h"

typedef void vprintf_t(const char* format, va_list va);

static void printf_dummy(const char* format, ...) {
}

void printf_lookup(const char* format, ...) {
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

printf_t* log_printf = (printf_t*)&printf_lookup;

