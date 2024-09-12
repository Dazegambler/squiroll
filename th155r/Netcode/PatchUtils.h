#pragma once

#ifndef PatchUtils_H
#define PatchUtils_H 1

#include <stdlib.h>
#include <stdint.h>
#include <windows.h>

#include "util.h"

void mem_write(void* address, const void* data, size_t size);

template <typename T>
static forceinline void mem_write(T address, const void* data, size_t size) {
    return mem_write((void*)address, data, size);
}

template <typename T, typename D>
static forceinline void mem_write(T address, const D& data) {
    return mem_write((void*)address, (const void*)&data, sizeof(D));
}

int mem_prot_overwrite(void* address, size_t size, DWORD prot);


void hotpatch_call(void* target, void* replacement);
void hotpatch_icall(void* target, void* replacement);
void hotpatch_jump(void* target, void* replacement);
void hotpatch_ret(void* target, uint16_t pop_bytes);
void hotpatch_rel32(void* target, void* replacement);
void hotpatch_import(void* addr, void* replacement);

template <typename T, typename R>
static forceinline void hotpatch_call(T target, R replacement) {
    return hotpatch_call((void*)target, (void*)replacement);
}

template <typename T, typename R>
static forceinline void hotpatch_icall(T target, R replacement) {
    return hotpatch_icall((void*)target, (void*)replacement);
}

template <typename T, typename R>
static forceinline void hotpatch_jump(T target, R replacement) {
    return hotpatch_jump((void*)target, (void*)replacement);
}

template <typename T>
static forceinline void hotpatch_ret(T target, uint16_t pop_bytes) {
    return hotpatch_ret((void*)target, pop_bytes);
}

template <typename T, typename R>
static forceinline void hotpatch_rel32(T target, R replacement) {
    return hotpatch_rel32((void*)target, (void*)replacement);
}

template <typename T, typename R>
static forceinline void hotpatch_import(T target, R replacement) {
    return hotpatch_import((void*)target, (void*)replacement);
}

#define BASE_NOP1 0x90
#define BASE_NOP2 0x66, 0x90
#define BASE_NOP3 0x0F, 0x1F, 0x00
#define BASE_NOP4 0x0F, 0x1F, 0x40, 0x00
#define BASE_NOP5 0x0F, 0x1F, 0x44, 0x00, 0x00
#define BASE_NOP6 0x66, 0x0F, 0x1F, 0x44, 0x00, 0x00
#define BASE_NOP7 0x0F, 0x1F, 0x80, 0x00, 0x00, 0x00, 0x00
#define BASE_NOP8 0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00
#define BASE_NOP9 0x66, 0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00
#define BASE_NOP10 0x66, 0x2E, 0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00
template<size_t length> requires(length <= 60)
static inline constexpr uint8_t NOP_BYTES[0]{};
template<> inline constexpr uint8_t NOP_BYTES<1>[1] = { BASE_NOP1 };
template<> inline constexpr uint8_t NOP_BYTES<2>[2] = { BASE_NOP2 };
template<> inline constexpr uint8_t NOP_BYTES<3>[3] = { BASE_NOP3 };
template<> inline constexpr uint8_t NOP_BYTES<4>[4] = { BASE_NOP4 };
template<> inline constexpr uint8_t NOP_BYTES<5>[5] = { BASE_NOP5 };
template<> inline constexpr uint8_t NOP_BYTES<6>[6] = { BASE_NOP6 };
template<> inline constexpr uint8_t NOP_BYTES<7>[7] = { BASE_NOP7 };
template<> inline constexpr uint8_t NOP_BYTES<8>[8] = { BASE_NOP8 };
template<> inline constexpr uint8_t NOP_BYTES<9>[9] = { BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<10>[10] = { BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<11>[11] = { BASE_NOP5, BASE_NOP6 };
template<> inline constexpr uint8_t NOP_BYTES<12>[12] = { BASE_NOP6, BASE_NOP6 };
template<> inline constexpr uint8_t NOP_BYTES<13>[13] = { BASE_NOP6, BASE_NOP7 };
template<> inline constexpr uint8_t NOP_BYTES<14>[14] = { BASE_NOP7, BASE_NOP7 };
template<> inline constexpr uint8_t NOP_BYTES<15>[15] = { BASE_NOP7, BASE_NOP8 };
template<> inline constexpr uint8_t NOP_BYTES<16>[16] = { BASE_NOP8, BASE_NOP8 };
template<> inline constexpr uint8_t NOP_BYTES<17>[17] = { BASE_NOP8, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<18>[18] = { BASE_NOP9, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<19>[19] = { BASE_NOP9, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<20>[20] = { BASE_NOP10, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<21>[21] = { BASE_NOP7, BASE_NOP7, BASE_NOP7 };
template<> inline constexpr uint8_t NOP_BYTES<22>[22] = { BASE_NOP7, BASE_NOP7, BASE_NOP8 };
template<> inline constexpr uint8_t NOP_BYTES<23>[23] = { BASE_NOP7, BASE_NOP8, BASE_NOP8 };
template<> inline constexpr uint8_t NOP_BYTES<24>[24] = { BASE_NOP8, BASE_NOP8, BASE_NOP8 };
template<> inline constexpr uint8_t NOP_BYTES<25>[25] = { BASE_NOP8, BASE_NOP8, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<26>[26] = { BASE_NOP8, BASE_NOP9, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<27>[27] = { BASE_NOP9, BASE_NOP9, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<28>[28] = { BASE_NOP9, BASE_NOP9, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<29>[29] = { BASE_NOP9, BASE_NOP10, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<30>[30] = { BASE_NOP10, BASE_NOP10, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<31>[31] = { BASE_NOP7, BASE_NOP8, BASE_NOP8, BASE_NOP8 };
template<> inline constexpr uint8_t NOP_BYTES<32>[32] = { BASE_NOP8, BASE_NOP8, BASE_NOP8, BASE_NOP8 };
template<> inline constexpr uint8_t NOP_BYTES<33>[33] = { BASE_NOP8, BASE_NOP8, BASE_NOP8, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<34>[34] = { BASE_NOP8, BASE_NOP8, BASE_NOP9, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<35>[35] = { BASE_NOP8, BASE_NOP9, BASE_NOP9, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<36>[36] = { BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<37>[37] = { BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<38>[38] = { BASE_NOP9, BASE_NOP9, BASE_NOP10, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<39>[39] = { BASE_NOP9, BASE_NOP10, BASE_NOP10, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<40>[40] = { BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<41>[41] = { BASE_NOP8, BASE_NOP8, BASE_NOP8, BASE_NOP8, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<42>[42] = { BASE_NOP8, BASE_NOP8, BASE_NOP8, BASE_NOP9, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<43>[43] = { BASE_NOP8, BASE_NOP8, BASE_NOP9, BASE_NOP9, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<44>[44] = { BASE_NOP8, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<45>[45] = { BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<46>[46] = { BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<47>[47] = { BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP10, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<48>[48] = { BASE_NOP9, BASE_NOP9, BASE_NOP10, BASE_NOP10, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<49>[49] = { BASE_NOP9, BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<50>[50] = { BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<51>[51] = { BASE_NOP8, BASE_NOP8, BASE_NOP8, BASE_NOP9, BASE_NOP9, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<52>[52] = { BASE_NOP8, BASE_NOP8, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<53>[53] = { BASE_NOP8, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<54>[54] = { BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9 };
template<> inline constexpr uint8_t NOP_BYTES<55>[55] = { BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<56>[56] = { BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP10, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<57>[57] = { BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP10, BASE_NOP10, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<58>[58] = { BASE_NOP9, BASE_NOP9, BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<59>[59] = { BASE_NOP9, BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10 };
template<> inline constexpr uint8_t NOP_BYTES<60>[60] = { BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10 };

static inline constexpr uint8_t INFINITE_LOOP_BYTES[] = { 0xEB, 0xFE };

#endif