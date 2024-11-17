#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <stdio.h>
#include <windows.h>
#include "log.h"
#include "util.h"
#include "patch_utils.h"

typedef void cdecl vprintf_t(const char* format, va_list va);
typedef void cdecl vfprintf_t(FILE* stream, const char* format, va_list va);

#if !MINGW_COMPAT

printf_t* log_printf = (printf_t*)&printf;
fprintf_t* log_fprintf = (fprintf_t*)&fprintf;

#else

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
#endif

#include <exception>

static constexpr uintptr_t cxx_string_exception_throws[] = {
    0xB910, 0xB977, 0x52993, 0x52A04, 0x83280, 0x832F3, 0x9CD3A, 0x9CEFA, 0x9D0A6,
    0x9D141, 0xC194A, 0xC1B67, 0xE40B0, 0xE4124, 0xE4200, 0xE427E, 0x1233D6, 0x123495
};

typedef void stdcall cxx_throw_exception_string_hook_t(
    msvc_string* str,
    void* throw_info
);

void stdcall cxx_throw_exception_string_hook(
    msvc_string* str,
    void* throw_info
) {
    log_printf(
        "Squirrel C++ exception: \"%s\"\n"
        "Turn on ScrollLock to continue...\n"
        , str->data()
    );
    bool prev_scroll_state = ScrollLockOn();
    SetScrollLockState(false);
    WaitForScrollLock();
    SetScrollLockState(prev_scroll_state);
    return ((cxx_throw_exception_string_hook_t*)(0x2FB5DD_R))(str, throw_info);
}

void patch_throw_logs() {
    uintptr_t base = base_address;
    for (size_t i = 0; i < countof(cxx_string_exception_throws); ++i) {
        hotpatch_rel32(based_pointer(base, cxx_string_exception_throws[i]), cxx_throw_exception_string_hook);
    }
}