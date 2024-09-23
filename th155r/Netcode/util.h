#pragma once

#ifndef UTIL_H
#define UTIL_H 1

#include <stdlib.h>
#include <stdint.h>
#include <type_traits>
#include <limits.h>
#include <limits>
#include <atomic>

#include <winsock2.h>
#include <windows.h>

#define _MACRO_CAT(arg1, arg2) arg1 ## arg2
#define MACRO_CAT(arg1, arg2) _MACRO_CAT(arg1, arg2)
#define _MACRO_STR(arg) #arg
#define MACRO_STR(arg) _MACRO_STR(arg)
#define MACRO_EVAL(...) __VA_ARGS__

#define MACRO_FIRST(arg1, ...) arg1

#if defined(_MSC_VER) && !defined(MSVC_COMPAT)
#define MSVC_COMPAT 1
#endif
#if defined(__GNUC__) && !defined(GCC_COMPAT)
#define GCC_COMPAT 1
#endif
#if defined(__clang__) && !defined(CLANG_COMPAT)
#define CLANG_COMPAT 1
#endif
#if defined(__MINGW32__) || defined(__MINGW64__)
#define MINGW_COMPAT 1
#endif

#if GCC_COMPAT || CLANG_COMPAT
#define USE_MSVC_ASM 0
#elif MSVC_COMPAT
#define USE_MSVC_ASM 1
#endif

#define MACRO_VOID(...)

#if __INTELLISENSE__
#define requires(...) MACRO_EVAL(MACRO_VOID(__VA_ARGS__))
#else

#endif

#ifdef cdecl
#undef cdecl
#endif
#ifdef stdcall
#undef stdcall
#endif
#ifdef fastcall
#undef fastcall
#endif
#ifdef thiscall
#undef thiscall
#endif
#ifdef vectorcall
#undef vectorcall
#endif

#ifndef __has_builtin
#define __has_builtin(name) 0
#endif

#if GCC_COMPAT || CLANG_COMPAT
#define cdecl __attribute__((cdecl))
#define stdcall __attribute__((stdcall))
#define fastcall __attribute__((fastcall))
#define thiscall __attribute__((thiscall))
#elif MSVC_COMPAT
#define cdecl __cdecl
#define stdcall __stdcall
#define fastcall __fastcall
#define thiscall __thiscall
#else
#define cdecl
#define stdcall 
#define fastcall
#define thiscall
#endif

#if CLANG_COMPAT
#define vectorcall __attribute__((vectorcall))
#elif MSVC_COMPAT
#define vectorcall __vectorcall
#elif GCC_COMPAT
#define vectorcall __attribute__((sseregparm))
#else
#define vectorcall
#endif

#if GCC_COMPAT || CLANG_COMPAT
#define thisfastcall thiscall
#define thisfastcall_edx(...)
#define lambda_cc(...) __VA_ARGS__
#else
#define thisfastcall fastcall
#define thisfastcall_edx(...) __VA_ARGS__
#define lambda_cc(...)
#endif

#ifdef forceinline
#undef forceinline
#endif

#ifdef neverinline
#undef neverinline
#endif

#ifdef naked
#undef naked
#endif

#if MSVC_COMPAT || CLANG_COMPAT
#define forceinline __forceinline
#define neverinline __declspec(noinline)
#define naked __declspec(naked)
#else
#define forceinline __attribute__((always_inline)) inline
#define neverinline __attribute__((noinline))
#define naked __attribute__((naked))
#endif

#ifdef EVAL_NOOP
#undef EVAL_NOOP
#endif

#if MSVC_COMPAT
#define EVAL_NOOP(...) __noop(__VA_ARGS__)
#else
#define EVAL_NOOP(...) (0)
#endif

#ifdef dll_export
#undef dll_export
#endif

#define dll_export __declspec(dllexport)

#if GCC_COMPAT || CLANG_COMPAT
#define expect(...) __builtin_expect(__VA_ARGS__)
#else
#define expect(...) MACRO_FIRST(__VA_ARGS__)
#endif

#ifdef unreachable
#undef unreachable
#endif

#if GCC_COMPAT || CLANG_COMPAT
#define unreachable __builtin_unreachable()
#elif MSVC_COMPAT
#define unreachable __assume(0)
#else
#define unreachable do; while(0)
#endif

/*
#if GCC_COMPAT || CLANG_COMPAT
#define stack_return_offset ((uintptr_t*)__builtin_return_address(0))
#elif MSVC_COMPAT
#include <intrin.h>
#define stack_return_offset ((uintptr_t*)_AddressOfReturnAddress())
#else
#error "Unknown stack offset format"
#endif
*/

#if !__has_builtin(__builtin_add_overflow)
#define __builtin_add_overflow __builtin_add_overflow_impl
template<typename T>
static inline bool __builtin_add_overflow(T a, T b, T * res) {
    if constexpr (std::is_signed_v<T>) {
        using U = std::make_unsigned_t<T>;
        U result = (U)a + (U)b;
        *res = (T)result;
        if (a > 0) {
            return b <= std::numeric_limits<T>::max() - a;
        } else {
            return b >= std::numeric_limits<T>::min() - a;
        }
    } else {
        return (*res = a + b) >= a;
    }
}
#endif

#if !__has_builtin(__builtin_sub_overflow)
#define __builtin_sub_overflow __builtin_sub_overflow_impl
template<typename T>
static inline bool __builtin_sub_overflow(T a, T b, T * res) {
    if constexpr (std::is_signed_v<T>) {
        using U = std::make_unsigned_t<T>;
        U result = (U)a - (U)b;
        *res = (T)result;
        if (a > 0) {
            return b >= std::numeric_limits<T>::max() - a;
        } else {
            return b <= std::numeric_limits<T>::min() - a;
        }
    } else {
        return (*res = a - b) <= a;
    }
}
#endif

#define countof(array_type) \
(sizeof(array_type) / sizeof(array_type[0]))

#define bitsof(type) (sizeof(type) * CHAR_BIT)


template<typename T>
static inline T saturate_add(T lhs, T rhs) {
    if constexpr (std::is_signed_v<T>) {
        using U = std::make_unsigned_t<T>;
        T ret;
        if (!__builtin_add_overflow(lhs, rhs, &ret)) {
            return ret;
        }
        return ((U)rhs >> (bitsof(T) - 1)) + (U)std::numeric_limits<T>::max();
    } else {
        T ret = lhs + rhs;
        return ret >= lhs ? ret : std::numeric_limits<T>::max();
    }
}

template<typename T>
static inline T saturate_sub(T lhs, T rhs) {
    if constexpr (std::is_signed_v<T>) {
        using U = std::make_unsigned_t<T>;
        T ret;
        if (!__builtin_sub_overflow(lhs, rhs, &ret)) {
            return ret;
        }
        return (U)std::numeric_limits<T>::min() - ((U)rhs >> (bitsof(T) - 1));
    } else {
        T ret = lhs - rhs;
        return ret <= lhs ? ret : std::numeric_limits<T>::min();
    }
}


extern const uintptr_t base_address;

forceinline uintptr_t operator ""_R(unsigned long long int addr) {
    return (uintptr_t)addr + base_address;
}

template <size_t bit_count>
using SBitIntType = std::conditional_t<bit_count <= 8, int8_t,
					std::conditional_t<bit_count <= 16, int16_t,
					std::conditional_t<bit_count <= 32, int32_t,
					std::conditional_t<bit_count <= 64, int64_t,
					void>>>>;
template <size_t bit_count>
using UBitIntType = std::conditional_t<bit_count <= 8, uint8_t,
					std::conditional_t<bit_count <= 16, uint16_t,
					std::conditional_t<bit_count <= 32, uint32_t,
					std::conditional_t<bit_count <= 64, uint64_t,
					void>>>>;
                    
template <typename R, typename B, typename O> requires(!std::is_same_v<R, B>)
static forceinline R* based_pointer(B* base, O offset) {
    return (R*)((uintptr_t)base + (uintptr_t)offset);
}

template <typename P, typename O>
static forceinline P* based_pointer(P* base, O offset) {
    return (P*)((uintptr_t)base + (uintptr_t)offset);
}

template <typename R, typename B, typename O> requires(!std::is_pointer_v<B>)
static forceinline R* based_pointer(B base, O offset) {
    return (R*)((uintptr_t)base + (uintptr_t)offset);
}

template <typename B, typename O> requires(!std::is_pointer_v<B>)
static forceinline B based_pointer(B base, O offset) {
    return (B)((uintptr_t)base + (uintptr_t)offset);
}

static inline unsigned int get_random(unsigned int max_value) {
    return (unsigned int)rand() % max_value;
}

static inline bool random_percentage(unsigned int chance) {
    return get_random(100) < chance;
}

static inline bool IsKeyPressed(int key) {
    return GetKeyState(key) < 0;
}

static inline bool ScrollLockOn() {
    return GetKeyState(VK_SCROLL) & 1;
}

static inline void SetScrollLockState(bool state) {
    if (ScrollLockOn() != state) {
        keybd_event(VK_SCROLL, 0x45, KEYEVENTF_EXTENDEDKEY, 0);
        keybd_event(VK_SCROLL, 0x45, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);
    }
}

static inline void WaitForScrollLock(size_t delay = 1000) {
    while (!ScrollLockOn()) {
        Sleep(delay);
    }
}

// This is intentionally not marked static
inline bool HasScrollLockChanged() {
    static bool prev_scroll_state = false;

    if (ScrollLockOn() != prev_scroll_state) {
        prev_scroll_state ^= true;
        return true;
    }
    return false;
}

static inline bool file_exists(const char* path) {
    DWORD attr = GetFileAttributesA(path);
    return attr != INVALID_FILE_ATTRIBUTES && !(attr & FILE_ATTRIBUTE_DIRECTORY);
}

#if !USE_MSVC_ASM
#define infinite_loop() __asm__(".byte 0xEB, 0xFE")
#define halt_and_catch_fire() __asm__("int3")
#else
#define infinite_loop() __asm { __asm _emit 0xEB __asm _emit 0xFE }
#define halt_and_catch_fire() __asm { __asm INT3 }
#endif

struct msvc_string {
    union {
        char short_buffer[16];
        char* long_buffer;
    };
    size_t current_length;
    size_t buffer_length;

    inline char* thiscall data() {
        return this->buffer_length < 16 ? this->short_buffer : this->long_buffer;
    }

    inline size_t thiscall length() const {
        return this->current_length;
    }
};

template <typename T>
static inline constexpr size_t INTEGER_BUFFER_SIZE = std::numeric_limits<T>::digits10 + 2 + std::is_signed_v<T>;

// IDK what the exact right value would be here to cover all
// text based float formats, so just add 24 for some padding.
template <typename T>
static inline constexpr size_t FLOAT_BUFFER_SIZE = std::numeric_limits<T>::max_digits10 + 3 + 24;

struct SpinLock {
    std::atomic<bool> flag;

    inline constexpr SpinLock() : flag(false) {}
    SpinLock(const SpinLock&) = delete;
    SpinLock& operator=(const SpinLock&) = delete;

    inline void lock() {
        while (this->flag.exchange(true, std::memory_order_acquire));
        std::atomic_thread_fence(std::memory_order_acquire);
    }
    inline bool try_lock() {
        bool ret = this->flag.exchange(true, std::memory_order_acquire);
        std::atomic_thread_fence(std::memory_order_acquire);
        return ret ^ true;
    }
    inline void unlock() {
        std::atomic_thread_fence(std::memory_order_release);
        this->flag.store(false, std::memory_order_release);
    }
};

#endif