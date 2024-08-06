#pragma once
#ifndef ALLOCMAN_H
#define ALLOCMAN_H

#include <stdint.h>
#include <stdlib.h>
#include <bit>

#include "util.h"

// struct AllocNode {
//     AllocNode* next;
//     AllocNode* prev;

//     void prepend(AllocNode* new_node);
//     void append(AllocNode* new_node);
//     void unlink();
// };

// enum AllocTickResult {
//     SaveData,
//     FreeData
// };

// struct AllocData {
//     AllocNode node;
//     size_t size;
//     int8_t timer;
//     alignas(8) unsigned char data[];

//     void init(size_t size);
//     void reinit(size_t size);
//     void start_free(int8_t time);
//     AllocTickResult tick();
//     void rollback(size_t frames);
// };

// struct Alloc {
//     AllocData* ptr;
//     size_t size;
//     unsigned char data[];
// };

static inline constexpr size_t SAVED_FRAMES = 8;
static_assert(std::has_single_bit(SAVED_FRAMES));
//static constexpr size_t FRAME_WRAP_MASK = SAVED_FRAMES - 1;

// struct AllocManager {
//     AllocNode dummy_node;
//     size_t saved_data_index;
//     uint8_t* saved_data[SAVED_FRAMES];
//     size_t buffer_sizes[SAVED_FRAMES];

//     constexpr AllocManager();
//     size_t increment_index();
//     size_t rollback_index(size_t frames);
//     void append(AllocData* data);

//     template <typename L>
//     void for_each_alloc(const L& lambda);

//     template <typename L>
//     void for_each_saved_alloc(size_t index, const L& lambda);

//     void tick();
//     void rollback(size_t frames);
// };

void tick_allocs();
size_t rollback_allocs(size_t frames);
void reset_rollback_buffers();
void* cdecl my_malloc(size_t size);
void cdecl my_free(void* ptr);
void* cdecl my_realloc(void* ptr, size_t new_size);

#endif