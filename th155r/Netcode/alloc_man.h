#pragma once

#ifndef ALLOCMAN_H
#define ALLOCMAN_H 1

#include <stdint.h>
#include <stdlib.h>
#include <bit>

#include "util.h"

#define PATCH_NO_ALLOCS 0
#define PATCH_SQUIRREL_ALLOCS 1
#define PATCH_ALL_ALLOCS 2

#define ALLOCATION_PATCH_TYPE PATCH_NO_ALLOCS

#define MEMORY_DEBUG_NONE 0
#define MEMORY_DEBUG_LIGHT 1
#define MEMORY_DEBUG_HEAVY 2

#define MEMORY_DEBUG_LEVEL MEMORY_DEBUG_LIGHT

static inline constexpr size_t SAVED_FRAMES = 8;
static_assert(std::has_single_bit(SAVED_FRAMES));

void tick_allocs();
size_t fastcall rollback_allocs(size_t frames);
void reset_rollback_buffers();

void update_allocs();

void* cdecl my_malloc(size_t size);
void* cdecl my_calloc(size_t num, size_t size);
void cdecl my_free(void* ptr);
size_t cdecl my_msize(void* ptr);
void* cdecl my_expand(void* ptr, size_t new_size);
void* cdecl my_realloc(void* ptr, size_t new_size);
void* cdecl my_recalloc(void* ptr, size_t num, size_t size);

#endif