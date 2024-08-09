#pragma once

#ifndef PatchUtils_H
#define PatchUtils_H 1

#include <stdlib.h>
#include <stdint.h>

void mem_write(void* address, const void* data, size_t size);

//void hotpatch_call(void* target, void* replacement);
void hotpatch_jump(void* target, void* replacement);
void hotpatch_ret(void* target, uint16_t pop_bytes);
void hotpatch_rel32(void* target, void* replacement);
void hotpatch_import(void* addr, void* replacement);

#endif