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

template <uint8_t ... bytes>
static inline constexpr uint8_t PATCH_BYTES[] = { bytes... };

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

#define NOP_BYTES(val) PATCH_BYTES<BASE_NOP(val)>

#define INFINITE_LOOP_BYTES PATCH_BYTES<0xEB, 0xFE>
#define INT3_BYTES PATCH_BYTES<0xCC>

#endif