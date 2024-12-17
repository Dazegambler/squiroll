#pragma once

#ifndef COMMON_H
#define COMMON_H 1

#define _MACRO_STR(arg) #arg
#define MACRO_STR(arg) _MACRO_STR(arg)
#define MACRO_EVAL(...) __VA_ARGS__
#define MACRO_VOID(...)
#if __INTELLISENSE__
#define requires(...) MACRO_EVAL(MACRO_VOID(__VA_ARGS__))
#endif

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <limits.h>

#include <type_traits>

#if __INTELLISENSE__ && !_HAS_CXX20
#define TEMP_DEF_CXX20 1
#undef _HAS_CXX20
#define _HAS_CXX20 1
#endif
#include <bit>
#if __INTELLISENSE__ && TEMP_DEF_CXX20
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#if _WIN32
#include <synchapi.h>
#if INCLUDE_KEYBOARD_FUNCTIONS
#include <conio.h>
#endif
#else
#include <time.h>
#endif

#ifndef expect
#define expect __builtin_expect
#endif

#ifndef __has_builtin
#define __has_builtin(name) 0
#endif

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

static inline void wait_milliseconds(size_t count) {
#if _WIN32
	return Sleep(count);
#else
	timespec sleep_time;
	sleep_time.tv_sec = count / 1000;
	sleep_time.tv_nsec = count % 1000 * 1000000;
	timespec sleep_rem;
	while (nanosleep(&sleep_time, &sleep_rem) != 0) {
		sleep_time = sleep_rem;
	}
#endif
}

[[noreturn]] static void error_exit(const char* message) {
	fputs(message, stderr);
	exit(EXIT_FAILURE);
}

[[noreturn]] static void error_exitf(const char* format, ...) {
	va_list va;
	va_start(va, format);
	vfprintf(stderr, format, va);
	va_end(va);
	exit(EXIT_FAILURE);
}

#if INCLUDE_KEYBOARD_FUNCTIONS
static inline char wait_for_keyboard() {
	while (!_kbhit());
	return _getch();
}

static inline char wait_for_keyboard(size_t delay) {
	while (!_kbhit()) wait_milliseconds(delay);
	return _getch();
}
#endif

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

template <typename T>
static inline bool strbuf_to_uint16(const T* str, uint16_t& out) {
	using U = std::make_unsigned_t<T>;
	
	const U* str_read = (const U*)str;
	switch (uint32_t ret = *str_read++) {
		case (U)'0': case (U)'1': case (U)'2': case (U)'3': case (U)'4':
		case (U)'5': case (U)'6': case (U)'7': case (U)'8': case (U)'9':
			ret -= (U)'0';
			for (;;) {
				switch (U c = *str_read++) {
					default:
						out = ret;
						return true;
					case (U)'0': case (U)'1': case (U)'2': case (U)'3': case (U)'4':
					case (U)'5': case (U)'6': case (U)'7': case (U)'8': case (U)'9':
						ret = ret * 10 + (c - (U)'0');
						if (ret <= UINT16_MAX) {
							continue;
						}
				}
		default:
				return false;
			}
	}
}

template<size_t N>
static inline size_t getsn(char(&str)[N]) {
	fgets(str, N, stdin);
	size_t length = strcspn(str, "\r\n");
	str[length] = '\0';
	return length;
}

template<size_t N>
static inline size_t getsn_newline(char(&str)[N]) {
	fgets(str, N, stdin);
	size_t length = strcspn(str, "\r\0");
	str[length] = '\n';
	return length;
}

constexpr size_t seconds_as_ms(size_t seconds) {
	return seconds * 1000;
}

constexpr size_t seconds_as_ms(double seconds) {
	return (size_t)(seconds * 1000.0);
}

constexpr size_t operator ""_secms(unsigned long long seconds) {
	return seconds_as_ms((size_t)seconds);
}

constexpr size_t operator ""_secms(long double seconds) {
	return seconds_as_ms((double)seconds);
}

#endif