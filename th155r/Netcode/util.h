#pragma once

#ifndef UTIL_H
#define UTIL_H 1

#define SYNC_USE_MILLISECONDS 0
#define SYNC_USE_MICROSECONDS 1

#define SYNC_TYPE SYNC_USE_MICROSECONDS

#include <stdlib.h>
#include <stdint.h>
#include <type_traits>
#include <limits.h>
#include <limits>
#include <atomic>
#include <bit>

#include <immintrin.h>

#include <winsock2.h>
#include <windows.h>

#define _MACRO_CAT(arg1, arg2) arg1 ## arg2
#define MACRO_CAT(arg1, arg2) _MACRO_CAT(arg1, arg2)
#define _MACRO_CATW(arg1, arg2, arg3) arg1 ## arg2 ## arg3
#define MACRO_CATW(arg1, arg2, arg3) _MACRO_CATW(arg1, arg2, arg3)
#define _MACRO_CAT4(arg1, arg2, arg3, arg4) arg1 ## arg2 ## arg3 ## arg4
#define MACRO_CAT4(arg1, arg2, arg3, arg4) _MACRO_CAT4(arg1, arg2, arg3, arg4)
#define _MACRO_CAT5(arg1, arg2, arg3, arg4, arg5) arg1 ## arg2 ## arg3 ## arg4 ## arg5
#define MACRO_CAT5(arg1, arg2, arg3, arg4, arg5) _MACRO_CAT5(arg1, arg2, arg3, arg4, arg5)
#define _MACRO_STR(arg) #arg
#define MACRO_STR(arg) _MACRO_STR(arg)
#define MACRO_EVAL(...) __VA_ARGS__
#define MACRO_VOID(...)

#define MACRO_FIRST(arg1, ...) arg1
#define MACRO_VOID2(...) MACRO_FIRST(,__VA_ARGS__)

#define require_semicolon() do; while(0)

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
#define VLA_SUPPORT 1
#elif MSVC_COMPAT
#define USE_MSVC_ASM 1
#define VLA_SUPPORT 0
#else
#define USE_MSVC_ASM 0
#define VLA_SUPPORT 0
#endif

#if MSVC_COMPAT
#include <malloc.h>
#endif

template<class L, int = (L{}(), 0) >
static inline constexpr bool is_constexpr(L) { return true; }
static inline constexpr bool is_constexpr(...) { return false; }
#define IS_CONSTEXPR(...) is_constexpr([]{ __VA_ARGS__; })

#if __INTELLISENSE__
#define requires(...) MACRO_EVAL(MACRO_VOID(__VA_ARGS__))
#else

#endif

#ifndef __has_builtin
#define __has_builtin(name) 0
#endif

#ifndef __has_attribute
#define __has_attribute(name) 0
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

#if GCC_COMPAT || CLANG_COMPAT
#define lambda_forceinline __attribute__((always_inline))
#else
#define lambda_forceinline
#endif

#if CLANG_COMPAT
#define clang_noinline [[clang::noinline]]
#else
#define clang_noinline
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

#ifdef gnu_used
#undef gnu_used
#endif

#ifdef gnu_alias
#undef gnu_alias
#endif

#if GCC_COMPAT || CLANG_COMPAT
#define gnu_used __attribute__((used))
#define gnu_alias(...) __attribute__((alias(__VA_ARGS__)))
#else
#define gnu_used
#define gnu_alias(...)
#endif

#if !__has_builtin(__builtin_expect_with_probability)
#define __builtin_expect_with_probability(cond, ...) (cond)
#endif
#define expect_chance __builtin_expect_with_probability

#if GCC_COMPAT || CLANG_COMPAT
#define expect(...) __builtin_expect(__VA_ARGS__)
#else
#define expect(...) MACRO_FIRST(__VA_ARGS__)
#endif

#if CLANG_COMPAT
#define assume(...) __builtin_assume(__VA_ARGS__)
#elif GCC_COMPAT
#define assume(...) __attibute__((assume(__VA_ARGS__)))
#elif MSVC_COMPAT
#define assume(...) __assume(__VA_ARGS__)
#else
#define assume(...)
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

#if __has_attribute(address_space)
#define read_fs_dword(offset) (*(uint32_t __attribute__((address_space(257)))*)((uintptr_t)(offset)))
#elif defined(__SEG_FS)
#if CLANG_COMPAT || !defined(__cplusplus)
#define read_fs_dword(offset) (*(__seg_fs uint32_t*)((uintptr_t)(offset)))
#else
uint32_t fastcall read_fs_dword(size_t offset) {
    uint32_t ret;
    __asm__(
        "movl %%fs:%[offset], %[ret]"
        : [ret] "=r"(ret)
        : [offset] "ri"(offset)
    );
    return ret;
}
#endif
#elif MSVC_COMPAT
#define read_fs_dword(offset) __readfsdword(offset)
#else
#define read_fs_dword(offset) (*(uint32_t*)((uintptr_t)(offset)))
#endif

#if GCC_COMPAT || CLANG_COMPAT
//#define stack_return_offset ((uintptr_t*)__builtin_return_address(0))
#define return_address ((uintptr_t)__builtin_return_address(0))
#elif MSVC_COMPAT
#include <intrin.h>
#define stack_return_offset ((uintptr_t*)_AddressOfReturnAddress())
#define return_address (*stack_return_offset)
#else
static inline const uintptr_t dummy_ip = 0;
#define stack_return_offset (&dummy_ip)
#define return_address (*stack_return_offset)
#endif

#if CLANG_COMPAT
#define nounroll _Pragma("clang loop unroll(disable)")
#elif GCC_COMPAT
#define nounroll _Pragma("GCC unroll 0")
#else
#define nounroll
#endif

#if CLANG_COMPAT
#define PUSH_WARNINGS() _Pragma("clang diagnostic push")
#define POP_WARNINGS() _Pragma("clang diagnostic pop")
#define IGNORE_DESIGNATED_INITIALIZER_WARNING() _Pragma("clang diagnostic ignored \"-Wc99-designator\"")
#elif GCC_COMPAT
#define PUSH_WARNINGS() _Pragma("GCC diagnostic push")
#define POP_WARNINGS() _Pragma("GCC diagnostic pop")
#define IGNORE_DESIGNATED_INITIALIZER_WARNING()
#elif MSVC_COMPAT
#define PUSH_WARNINGS() _Pragma("warning(push)")
#define POP_WARNINGS() _Pragma("warning(pop)")
#define IGNORE_DESIGNATED_INITIALIZER_WARNING()
#else
#define PUSH_WARNINGS()
#define POP_WARNINGS()
#define IGNORE_DESIGNATED_INITIALIZER_WARNING()
#endif


#define countof(array_type) \
(sizeof(array_type) / sizeof(array_type[0]))

#define bitsof(type) (sizeof(type) * CHAR_BIT)

#define bool_str(...) ((bool)(__VA_ARGS__) ? "true" : "false")

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

#if !__has_builtin(__builtin_bswap16)
static inline uint16_t __builtin_bswap16(uint16_t value) {
    return value >> 8 | value << 8;
}
#endif

#if !__has_builtin(__builtin_bswap32)
static inline uint32_t __builtin_bswap32(uint32_t value) {
    return value << 24 | value >> 24 | (value & 0x0000FF00u) << 8 | (value & 0x00FF0000u) >> 8;
}
#endif

#if !__has_builtin(__builtin_bswap64)
static inline uint64_t __builtin_bswap64(uint64_t value) {
    value = (value & 0x00000000FFFFFFFFull) << 32 | (value & 0xFFFFFFFF00000000ull) >> 32;
    value = (value & 0x0000FFFF0000FFFFull) << 16 | (value & 0xFFFF0000FFFF0000ull) >> 16;
    return  (value & 0x00FF00FF00FF00FFull) << 8  | (value & 0xFF00FF00FF00FF00ull) >> 8;
}
#endif

template<typename T>
static inline T bswap(const T& value) {
    if constexpr (sizeof(T) == sizeof(uint8_t)) {
        return value;
    }
    else if constexpr (sizeof(T) == sizeof(uint16_t)) {
        uint16_t temp = __builtin_bswap16(*(uint16_t*)&value);
        return *(T*)&temp;
    }
    else if constexpr (sizeof(T) == sizeof(uint32_t)) {
        uint32_t temp = __builtin_bswap32(*(uint32_t*)&value);
        return *(T*)&temp;
    }
    else if constexpr (sizeof(T) == sizeof(uint64_t)) {
        uint64_t temp = __builtin_bswap64(*(uint64_t*)&value);
        return *(T*)&temp;
    }
    else {
        static_assert(false, "Invalid argument type for bswap");
    }
}

template<typename T>
static inline constexpr T hton(T value) {
    if constexpr (std::endian::native == std::endian::little) {
        return bswap(value);
    } else if constexpr (std::endian::native == std::endian::big) {
        return value;
    } else {
        static_assert(false);
    }
}

template<typename T>
static inline constexpr T ntoh(T value) {
    if constexpr (std::endian::native == std::endian::little) {
        return bswap(value);
    } else if constexpr (std::endian::native == std::endian::big) {
        return value;
    } else {
        static_assert(false);
    }
}

#if !__has_builtin(__builtin_add_overflow)
#define __builtin_add_overflow __builtin_add_overflow_impl
template<typename T>
static inline bool __builtin_add_overflow_impl(T a, T b, T* res) {
    if constexpr (std::is_signed_v<T>) {
        using U = std::make_unsigned_t<T>;
        U result = (U)a + (U)b;
        *res = (T)result;
        if (a > 0) {
            return b <= (std::numeric_limits<T>::max)() - a;
        } else {
            return b >= (std::numeric_limits<T>::min)() - a;
        }
    } else {
        return (*res = a + b) >= a;
    }
}
#endif

#if !__has_builtin(__builtin_sub_overflow)
#define __builtin_sub_overflow __builtin_sub_overflow_impl
template<typename T>
static inline bool __builtin_sub_overflow_impl(T a, T b, T* res) {
    if constexpr (std::is_signed_v<T>) {
        using U = std::make_unsigned_t<T>;
        U result = (U)a - (U)b;
        *res = (T)result;
        if (a > 0) {
            return b >= (std::numeric_limits<T>::max)() - a;
        } else {
            return b <= (std::numeric_limits<T>::min)() - a;
        }
    } else {
        return (*res = a - b) <= a;
    }
}
#endif

template<typename T>
static inline T saturate_add(T lhs, T rhs) {
    if constexpr (std::is_signed_v<T>) {
        using U = std::make_unsigned_t<T>;
        T ret;
        if (!__builtin_add_overflow(lhs, rhs, &ret)) {
            return ret;
        }
        return ((U)rhs >> (bitsof(T) - 1)) + (U)(std::numeric_limits<T>::max)();
    } else {
        T ret = lhs + rhs;
        return ret >= lhs ? ret : (std::numeric_limits<T>::max)();
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
        return (U)(std::numeric_limits<T>::min)() - ((U)rhs >> (bitsof(T) - 1));
    } else {
        T ret = lhs - rhs;
        return ret <= lhs ? ret : (std::numeric_limits<T>::min)();
    }
}

extern const uintptr_t base_address;

forceinline uintptr_t operator ""_R(unsigned long long int addr) {
    return (uintptr_t)addr + base_address;
}
                    
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

template <typename T>
static inline size_t uint8_to_strbuf(uint8_t value, T* text_buffer) {
    size_t digit_offset;
    switch (value) {
        case 0 ... 9:
            digit_offset = 0;
            break;
        case 10 ... 99:
            digit_offset = 1;
            break;
        default:
            digit_offset = 2;
            break;
    }
    size_t ret = digit_offset + 1;
    do {
        uint8_t digit = value % 10;
        value /= 10;
        text_buffer[digit_offset] = ((T)'0') + digit;
    } while (digit_offset--);
    return ret;
}

template <typename T>
static inline size_t uint16_to_strbuf(uint16_t value, T* text_buffer) {
    size_t digit_offset;
    switch (value) {
        case 0 ... 9:
            digit_offset = 0;
            break;
        case 10 ... 99:
            digit_offset = 1;
            break;
        case 100 ... 999:
            digit_offset = 2;
            break;
        case 1000 ... 9999:
            digit_offset = 3;
            break;
        default:
            digit_offset = 4;
            break;
    }
    size_t ret = digit_offset + 1;
    do {
        uint16_t digit = value % 10;
        value /= 10;
        text_buffer[digit_offset] = ((T)'0') + digit;
    } while (digit_offset--);
    return ret;
}

template <typename T>
static inline size_t uint16_to_hex_strbuf(uint16_t value, T* text_buffer) {
    uint32_t temp = value;
    size_t digit_offset = temp ? (15 - std::countl_zero(value)) >> 2 : 0;
    size_t ret = digit_offset + 1;
    do {
        uint16_t digit = temp & 0xF;
        temp >>= 2;
        text_buffer[digit_offset] = (digit < 10 ? (T)'0' : (T)('A' - 10)) + digit;
    } while (digit_offset--);
    return ret;
}

struct LARGE_INTEGERX {
    LARGE_INTEGER value;

    inline LARGE_INTEGERX& operator=(const int64_t& value) {
        this->value.QuadPart = value;
        return *this;
    }

    inline LARGE_INTEGER* operator&() {
        return &this->value;
    }

    inline operator int64_t() const {
        return this->value.QuadPart;
    }

    inline explicit operator uint64_t() const {
        return this->value.QuadPart;
    }
};

struct WaitableEvent {
    HANDLE os_handle = INVALID_HANDLE_VALUE;

    inline void initialize() {
        this->os_handle = CreateEventExW(NULL, NULL, CREATE_EVENT_MANUAL_RESET, EVENT_ALL_ACCESS);
    }

    inline void set() const {
        (void)SetEvent(this->os_handle);
    }

    inline void reset() const {
        (void)ResetEvent(this->os_handle);
    }

    inline bool wait(uint32_t timeout = INFINITE) const {
        return WaitForSingleObjectEx(this->os_handle, timeout, FALSE) == WAIT_OBJECT_0;
    }

    inline bool wait_milliseconds(uint64_t timeout) const {
        return this->wait(timeout);
    }

    inline bool wait_microseconds(uint64_t timeout) const {
        return this->wait(timeout / 1000);
    }

    inline bool wait_sync(uint64_t timeout) const {
#if SYNC_TYPE == SYNC_USE_MILLISECONDS
        return this->wait_milliseconds(timeout);
#elif SYNC_TYPE == SYNC_USE_MICROSECONDS
        return this->wait_microseconds(timeout);
#endif
    }
};

struct WaitableTimer {
    HANDLE os_handle = INVALID_HANDLE_VALUE;

    inline void initialize() {
        using func_t = decltype(CreateWaitableTimerExW);
        if (func_t* create_func = (func_t*)GetProcAddress(GetModuleHandleW(L"kernel32.dll"), "CreateWaitableTimerExW")) {
            HANDLE timer = create_func(NULL, NULL, CREATE_WAITABLE_TIMER_MANUAL_RESET | CREATE_WAITABLE_TIMER_HIGH_RESOLUTION, EVENT_ALL_ACCESS);
            if (!timer) {
                timer = create_func(NULL, NULL, CREATE_WAITABLE_TIMER_MANUAL_RESET, EVENT_ALL_ACCESS);
            }
            this->os_handle = timer;
        }
        else {
            this->os_handle = CreateWaitableTimerW(NULL, TRUE, NULL);
        }
    }

    inline void set(int64_t duration) const {
        LARGE_INTEGER delay;
        delay.QuadPart = -duration;

        // MS documentation sucks for high resolution timers.
        // All arguments except the first two must be 0.
        // https://stackoverflow.com/questions/73647588/createwaitabletimerex-and-setwaitabletimerex-with-high-resolution-flag-name-and#comment130054268_73647588
        SetWaitableTimer(this->os_handle, &delay, 0, NULL, NULL, FALSE);
    }

    inline void set_milliseconds(int64_t duration) const {
        return this->set(duration * 10000);
    }

    inline void set_microseconds(int64_t duration) const {
        return this->set(duration * 10);
    }

    inline void set_sync(int64_t duration) const {
#if SYNC_TYPE == SYNC_USE_MILLISECONDS
        return this->set_milliseconds(duration);
#elif SYNC_TYPE == SYNC_USE_MICROSECONDS
        return this->set_microseconds(duration);
#endif
    }

    inline void wait() const {
        WaitForSingleObject(this->os_handle, INFINITE);
    }

    inline void wait(int64_t duration) const {
        this->set(duration);
        this->wait();
    }

    inline void wait_milliseconds(int64_t duration) const {
        return this->wait(duration * 10000);
    }

    inline void wait_microseconds(int64_t duration) const {
        return this->wait(duration * 10);
    }

    inline void wait_sync(int64_t duration) const {
#if SYNC_TYPE == SYNC_USE_MILLISECONDS
        return this->wait_milliseconds(duration);
#elif SYNC_TYPE == SYNC_USE_MICROSECONDS
        return this->wait_microseconds(duration);
#endif
    }
};

#define CurrentProcessPseudoHandle() ((HANDLE)-1)
#define CurrentThreadPseudoHandle() ((HANDLE)-2)

static inline constexpr double FRAC_SECONDS_PER_FRAME = 1.0 / 60.0;

extern uint64_t qpc_second_frequency;
extern uint64_t qpc_frame_frequency;
extern uint64_t qpc_milli_frequency;
extern uint64_t qpc_micro_frequency;

#if SYNC_TYPE == SYNC_USE_MILLISECONDS
#define SYNC_WORD_STR "milliseconds"
#define SYNC_UNIT_STR "ms"
#elif SYNC_TYPE == SYNC_USE_MICROSECONDS
#define SYNC_WORD_STR "microseconds"
#define SYNC_UNIT_STR "us"
#endif

static inline uint64_t current_qpc() {
    LARGE_INTEGERX now;
    QueryPerformanceCounter(&now);
    return (uint64_t)now;
}

static inline uint64_t qpc_to_seconds(uint64_t value) {
    return value / qpc_second_frequency;
}

static inline uint64_t qpc_to_frames(uint64_t value) {
    return value / qpc_frame_frequency;
}

static inline uint64_t qpc_to_milliseconds(uint64_t value) {
    return value / qpc_milli_frequency;
}

static inline uint64_t qpc_to_microseconds(uint64_t value) {
    return value / qpc_micro_frequency;
}

static inline uint64_t qpc_to_sync_time(uint64_t value) {
#if SYNC_TYPE == SYNC_USE_MILLISECONDS
    return qpc_to_milliseconds(value);
#elif SYNC_TYPE == SYNC_USE_MICROSECONDS
    return qpc_to_microseconds(value);
#endif
}

static inline int64_t current_sync_time() {
    return qpc_to_sync_time(current_qpc());
}

template <bool use_pause = false>
static inline void spin_until_qpc(uint64_t stop) {
    while (current_qpc() < stop) {
        if constexpr (use_pause) {
            _mm_pause();
        }
    }
}

template <bool use_pause = false>
static inline void spin_for_sync_time(uint64_t duration) {
    uint64_t initial_time = current_sync_time();
    while (current_sync_time() - initial_time < duration) {
        if constexpr (use_pause) {
            _mm_pause();
        }
    }
}

static inline void sync_to_microseconds(int64_t minimum_time, int64_t multiple) {
    int64_t initial_time = current_sync_time();
    int64_t current_time;
    do current_time = current_sync_time();
    while (current_time - initial_time < minimum_time || current_time % multiple);
}

template <typename T>
static inline bool wait_until_true(T& value) {
    while (!value);
    return true;
}

template <typename T>
static inline bool wait_until_true(T& value, int64_t timeout_ms) {
    int64_t initial_time = current_sync_time();
    bool was_true;
    while (!(was_true = value) && current_sync_time() - initial_time < timeout_ms);
    return was_true;
}

#endif