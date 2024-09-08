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

#endif