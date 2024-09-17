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

#define BASE_NOP0
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
#define BASE_NOP11 BASE_NOP5, BASE_NOP6
#define BASE_NOP12 BASE_NOP6, BASE_NOP6
#define BASE_NOP13 BASE_NOP6, BASE_NOP7
#define BASE_NOP14 BASE_NOP7, BASE_NOP7
#define BASE_NOP15 BASE_NOP7, BASE_NOP8
#define BASE_NOP16 BASE_NOP8, BASE_NOP8
#define BASE_NOP17 BASE_NOP8, BASE_NOP9
#define BASE_NOP18 BASE_NOP9, BASE_NOP9
#define BASE_NOP19 BASE_NOP9, BASE_NOP10
#define BASE_NOP20 BASE_NOP10, BASE_NOP10
#define BASE_NOP21 BASE_NOP7, BASE_NOP7, BASE_NOP7
#define BASE_NOP22 BASE_NOP7, BASE_NOP7, BASE_NOP8
#define BASE_NOP23 BASE_NOP7, BASE_NOP8, BASE_NOP8
#define BASE_NOP24 BASE_NOP8, BASE_NOP8, BASE_NOP8
#define BASE_NOP25 BASE_NOP8, BASE_NOP8, BASE_NOP9
#define BASE_NOP26 BASE_NOP8, BASE_NOP9, BASE_NOP9
#define BASE_NOP27 BASE_NOP9, BASE_NOP9, BASE_NOP9
#define BASE_NOP28 BASE_NOP9, BASE_NOP9, BASE_NOP10
#define BASE_NOP29 BASE_NOP9, BASE_NOP10, BASE_NOP10
#define BASE_NOP30 BASE_NOP10, BASE_NOP10, BASE_NOP10
#define BASE_NOP31 BASE_NOP7, BASE_NOP8, BASE_NOP8, BASE_NOP8
#define BASE_NOP32 BASE_NOP8, BASE_NOP8, BASE_NOP8, BASE_NOP8
#define BASE_NOP33 BASE_NOP8, BASE_NOP8, BASE_NOP8, BASE_NOP9
#define BASE_NOP34 BASE_NOP8, BASE_NOP8, BASE_NOP9, BASE_NOP9
#define BASE_NOP35 BASE_NOP8, BASE_NOP9, BASE_NOP9, BASE_NOP9
#define BASE_NOP36 BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9
#define BASE_NOP37 BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP10
#define BASE_NOP38 BASE_NOP9, BASE_NOP9, BASE_NOP10, BASE_NOP10
#define BASE_NOP39 BASE_NOP9, BASE_NOP10, BASE_NOP10, BASE_NOP10
#define BASE_NOP40 BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10
#define BASE_NOP41 BASE_NOP8, BASE_NOP8, BASE_NOP8, BASE_NOP8, BASE_NOP9
#define BASE_NOP42 BASE_NOP8, BASE_NOP8, BASE_NOP8, BASE_NOP9, BASE_NOP9
#define BASE_NOP43 BASE_NOP8, BASE_NOP8, BASE_NOP9, BASE_NOP9, BASE_NOP9
#define BASE_NOP44 BASE_NOP8, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9
#define BASE_NOP45 BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9
#define BASE_NOP46 BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP10
#define BASE_NOP47 BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP10, BASE_NOP10
#define BASE_NOP48 BASE_NOP9, BASE_NOP9, BASE_NOP10, BASE_NOP10, BASE_NOP10
#define BASE_NOP49 BASE_NOP9, BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10
#define BASE_NOP50 BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10
#define BASE_NOP51 BASE_NOP8, BASE_NOP8, BASE_NOP8, BASE_NOP9, BASE_NOP9, BASE_NOP9
#define BASE_NOP52 BASE_NOP8, BASE_NOP8, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9
#define BASE_NOP53 BASE_NOP8, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9
#define BASE_NOP54 BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9
#define BASE_NOP55 BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP10
#define BASE_NOP56 BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP10, BASE_NOP10
#define BASE_NOP57 BASE_NOP9, BASE_NOP9, BASE_NOP9, BASE_NOP10, BASE_NOP10, BASE_NOP10
#define BASE_NOP58 BASE_NOP9, BASE_NOP9, BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10
#define BASE_NOP59 BASE_NOP9, BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10
#define BASE_NOP60 BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10, BASE_NOP10

#define BASE_NOP(val) MACRO_CAT(BASE_NOP,val)

template<size_t length> requires(length <= 60)
static inline constexpr uint8_t NOP_BYTES[0]{};
template<> inline constexpr uint8_t NOP_BYTES<1>[1] = { BASE_NOP(1) };
template<> inline constexpr uint8_t NOP_BYTES<2>[2] = { BASE_NOP(2) };
template<> inline constexpr uint8_t NOP_BYTES<3>[3] = { BASE_NOP(3) };
template<> inline constexpr uint8_t NOP_BYTES<4>[4] = { BASE_NOP(4) };
template<> inline constexpr uint8_t NOP_BYTES<5>[5] = { BASE_NOP(5) };
template<> inline constexpr uint8_t NOP_BYTES<6>[6] = { BASE_NOP(6) };
template<> inline constexpr uint8_t NOP_BYTES<7>[7] = { BASE_NOP(7) };
template<> inline constexpr uint8_t NOP_BYTES<8>[8] = { BASE_NOP(8) };
template<> inline constexpr uint8_t NOP_BYTES<9>[9] = { BASE_NOP(9) };
template<> inline constexpr uint8_t NOP_BYTES<10>[10] = { BASE_NOP(10) };
template<> inline constexpr uint8_t NOP_BYTES<11>[11] = { BASE_NOP(11) };
template<> inline constexpr uint8_t NOP_BYTES<12>[12] = { BASE_NOP(12) };
template<> inline constexpr uint8_t NOP_BYTES<13>[13] = { BASE_NOP(13) };
template<> inline constexpr uint8_t NOP_BYTES<14>[14] = { BASE_NOP(14) };
template<> inline constexpr uint8_t NOP_BYTES<15>[15] = { BASE_NOP(15) };
template<> inline constexpr uint8_t NOP_BYTES<16>[16] = { BASE_NOP(16) };
template<> inline constexpr uint8_t NOP_BYTES<17>[17] = { BASE_NOP(17) };
template<> inline constexpr uint8_t NOP_BYTES<18>[18] = { BASE_NOP(18) };
template<> inline constexpr uint8_t NOP_BYTES<19>[19] = { BASE_NOP(19) };
template<> inline constexpr uint8_t NOP_BYTES<20>[20] = { BASE_NOP(20) };
template<> inline constexpr uint8_t NOP_BYTES<21>[21] = { BASE_NOP(21) };
template<> inline constexpr uint8_t NOP_BYTES<22>[22] = { BASE_NOP(22) };
template<> inline constexpr uint8_t NOP_BYTES<23>[23] = { BASE_NOP(23) };
template<> inline constexpr uint8_t NOP_BYTES<24>[24] = { BASE_NOP(24) };
template<> inline constexpr uint8_t NOP_BYTES<25>[25] = { BASE_NOP(25) };
template<> inline constexpr uint8_t NOP_BYTES<26>[26] = { BASE_NOP(26) };
template<> inline constexpr uint8_t NOP_BYTES<27>[27] = { BASE_NOP(27) };
template<> inline constexpr uint8_t NOP_BYTES<28>[28] = { BASE_NOP(28) };
template<> inline constexpr uint8_t NOP_BYTES<29>[29] = { BASE_NOP(29) };
template<> inline constexpr uint8_t NOP_BYTES<30>[30] = { BASE_NOP(30) };
template<> inline constexpr uint8_t NOP_BYTES<31>[31] = { BASE_NOP(31) };
template<> inline constexpr uint8_t NOP_BYTES<32>[32] = { BASE_NOP(32) };
template<> inline constexpr uint8_t NOP_BYTES<33>[33] = { BASE_NOP(33) };
template<> inline constexpr uint8_t NOP_BYTES<34>[34] = { BASE_NOP(34) };
template<> inline constexpr uint8_t NOP_BYTES<35>[35] = { BASE_NOP(35) };
template<> inline constexpr uint8_t NOP_BYTES<36>[36] = { BASE_NOP(36) };
template<> inline constexpr uint8_t NOP_BYTES<37>[37] = { BASE_NOP(37) };
template<> inline constexpr uint8_t NOP_BYTES<38>[38] = { BASE_NOP(38) };
template<> inline constexpr uint8_t NOP_BYTES<39>[39] = { BASE_NOP(39) };
template<> inline constexpr uint8_t NOP_BYTES<40>[40] = { BASE_NOP(40) };
template<> inline constexpr uint8_t NOP_BYTES<41>[41] = { BASE_NOP(41) };
template<> inline constexpr uint8_t NOP_BYTES<42>[42] = { BASE_NOP(42) };
template<> inline constexpr uint8_t NOP_BYTES<43>[43] = { BASE_NOP(43) };
template<> inline constexpr uint8_t NOP_BYTES<44>[44] = { BASE_NOP(44) };
template<> inline constexpr uint8_t NOP_BYTES<45>[45] = { BASE_NOP(45) };
template<> inline constexpr uint8_t NOP_BYTES<46>[46] = { BASE_NOP(46) };
template<> inline constexpr uint8_t NOP_BYTES<47>[47] = { BASE_NOP(47) };
template<> inline constexpr uint8_t NOP_BYTES<48>[48] = { BASE_NOP(48) };
template<> inline constexpr uint8_t NOP_BYTES<49>[49] = { BASE_NOP(49) };
template<> inline constexpr uint8_t NOP_BYTES<50>[50] = { BASE_NOP(50) };
template<> inline constexpr uint8_t NOP_BYTES<51>[51] = { BASE_NOP(51) };
template<> inline constexpr uint8_t NOP_BYTES<52>[52] = { BASE_NOP(52) };
template<> inline constexpr uint8_t NOP_BYTES<53>[53] = { BASE_NOP(53) };
template<> inline constexpr uint8_t NOP_BYTES<54>[54] = { BASE_NOP(54) };
template<> inline constexpr uint8_t NOP_BYTES<55>[55] = { BASE_NOP(55) };
template<> inline constexpr uint8_t NOP_BYTES<56>[56] = { BASE_NOP(56) };
template<> inline constexpr uint8_t NOP_BYTES<57>[57] = { BASE_NOP(57) };
template<> inline constexpr uint8_t NOP_BYTES<58>[58] = { BASE_NOP(58) };
template<> inline constexpr uint8_t NOP_BYTES<59>[59] = { BASE_NOP(59) };
template<> inline constexpr uint8_t NOP_BYTES<60>[60] = { BASE_NOP(60) };

static inline constexpr uint8_t INFINITE_LOOP_BYTES[] = { 0xEB, 0xFE };
static inline constexpr uint8_t INT3_BYTES[] = { 0xCC };

#endif