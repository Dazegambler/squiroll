#pragma once
#ifndef UTIL_H
#define UTIL_H

#include <stdlib.h>
#include <stdint.h>

#if defined(_MSC_VER) && !defined(MSVC_COMPAT)
#define MSVC_COMPAT 1
#endif
#if defined(__GNUC__) && !defined(GCC_COMPAT)
#define GCC_COMPAT 1
#endif
#if defined(__clang__) && !defined(CLANG_COMPAT)
#define CLANG_COMPAT 1
#endif

#undef cdecl
#undef stdcall

#if GCC_COMPAT
#define cdecl __attribute__((cdecl))
#define stdcall __attribute__((stdcall))
#elif MSVC_COMPAT || CLANG_COMPAT
#define cdecl __cdecl
#define stdcall __stdcall
#else
#define cdecl
#define stdcall 
#endif

extern const uintptr_t base_address;

inline uintptr_t operator ""_R(unsigned long long int addr) {
    return (uintptr_t)addr + base_address;
}

template<size_t bit_count>
using SBitIntType = std::conditional_t<bit_count <= 8, int8_t,
                                        std::conditional_t<bit_count <= 16,int16_t,
                                        std::conditional_t<bit_count <= 32,int32_t,
                                        std::conditional_t<bit_count <= 64,int64_t,
                                        void>>>>;
template<size_t bit_count>
using UBitIntType = std::conditional_t<bit_count <= 8, int8_t,
                                        std::conditional_t<bit_count <= 16,int16_t,
                                        std::conditional_t<bit_count <= 32,int32_t,
                                        std::conditional_t<bit_count <= 64,int64_t,
                                        void>>>>;
#endif