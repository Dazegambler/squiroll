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

#define ALLOCATION_PATCH_TYPE PATCH_SQUIRREL_ALLOCS

static inline constexpr size_t SAVED_FRAMES = 8;
static_assert(std::has_single_bit(SAVED_FRAMES));

void tick_allocs();
size_t fastcall rollback_allocs(size_t frames);
void reset_rollback_buffers();

void* cdecl my_malloc(size_t size);
void* cdecl my_calloc(size_t num, size_t size);
void cdecl my_free(void* ptr);
void* cdecl my_realloc(void* ptr, size_t new_size);

#endif