#include <stdint.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <algorithm>
#include <bit>
#include "AllocMan.h"

// Internal definitions

using rollback_timer_t = UBitIntType<std::bit_width(SAVED_FRAMES)>;

struct AllocNode {
    AllocNode* next;
    AllocNode* prev;

    void prepend(AllocNode* new_node) {
        new_node->next = this;
        this->prev = new_node;
    }
    
    void append(AllocNode* new_node) {
        this->next->prepend(new_node);
        new_node->prepend(this);
    }
    
    void unlink() const {
        AllocNode* next_node = this->next;
        AllocNode* prev_node = this->prev;
        next_node->prev = prev_node;
        prev_node->next = next_node;
    }
};

enum AllocTickResult {
    SaveData,
    FreeData
};

struct AllocData {
    AllocNode node;
    size_t size;
    rollback_timer_t free_timer;
    bool rollback_tag;
    alignas(__STDCPP_DEFAULT_NEW_ALIGNMENT__) unsigned char data[];
    
    static inline AllocData* get_from_ptr(void* ptr) {
        return (AllocData*)((uintptr_t)ptr - offsetof(AllocData, data));
    }
    
    static inline size_t buffer_size(size_t size) {
        return sizeof(AllocData) + size;
    }
    
   void init(size_t size) {
        this->size = size;
        this->free_timer = 0;
        this->rollback_tag = false;
    }
    
    void reinit(size_t size) {
        this->size = size;
    }
    
    void start_free(rollback_timer_t time) {
        this->free_timer = time;
    }
    
    AllocTickResult tick() {
        if (
            this->free_timer == 0 ||
            --this->free_timer != 0
        ) {
            return SaveData;
        }
        this->node.unlink();
        return FreeData;
    }
    
    void rollback_metadata(size_t frames) {
        if (
            this->free_timer != 0 &&
            (this->free_timer += frames) >= SAVED_FRAMES
        ) {
            this->free_timer = 0;
        }
        this->rollback_tag = true;
    }
};

struct SavedAlloc {
    AllocData* ptr;
    size_t size;
    alignas(4) unsigned char data[];
    
    static inline size_t buffer_size(AllocData* alloc) {
        return sizeof(SavedAlloc) + alloc->size;
    }
};

struct AllocManager {
    static inline constexpr size_t FRAME_WRAP_MASK = SAVED_FRAMES - 1;
    
    AllocNode dummy_node;
    size_t saved_data_index;
    size_t available_frames;
    uint8_t* saved_data[SAVED_FRAMES];
    size_t filled_sizes[SAVED_FRAMES];
    size_t buffer_sizes[SAVED_FRAMES];

    constexpr AllocManager()
        : saved_data_index(0), available_frames(0), saved_data{}, buffer_sizes{}, filled_sizes{} 
    {
        this->dummy_node.next = &this->dummy_node;
        this->dummy_node.prev = &this->dummy_node;
    }
    
    size_t increment_index() {
        this->available_frames = std::min(SAVED_FRAMES, this->available_frames + 1);
        size_t next_index = this->saved_data_index + 1 & FRAME_WRAP_MASK;
        return this->saved_data_index = next_index;
    }
    
    size_t rollback_index(size_t frames) {
        this->available_frames -= frames;
        size_t next_index = this->saved_data_index - frames & FRAME_WRAP_MASK;
        return this->saved_data_index = next_index;
    }
    
    void append(AllocData* data) {
        this->dummy_node.prev->append(&data->node);
    }

    template <typename L>
    inline void for_each_alloc(const L& lambda) {
        AllocNode* node = this->dummy_node.next;
        for (AllocNode* next_node; node != &this->dummy_node; node = next_node) {
            next_node = node->next;
            lambda((AllocData*)node);
        }
    }

    template <typename L>
    inline void for_each_saved_alloc(size_t index, const L& lambda) {
        uint8_t* buffer = this->saved_data[index];
        uint8_t* buffer_end = buffer + this->filled_sizes[index];
        while (buffer < buffer_end) {
            SavedAlloc* saved_data = (SavedAlloc*)buffer;
            buffer += sizeof(SavedAlloc) + saved_data->size;
            lambda(saved_data);
        }
    }

    void tick() {
        size_t total_size = 0;
        this->for_each_alloc([&](AllocData* alloc) {
            switch (alloc->tick()) {
                case SaveData:
                    total_size += SavedAlloc::buffer_size(alloc);
                    break;
                case FreeData:
                    free(alloc);
                    break;
            }
        });
        size_t current_index = this->increment_index();
        this->filled_sizes[current_index] = total_size;
        uint8_t* current_buffer = this->saved_data[current_index];
        if (total_size > this->buffer_sizes[current_index]) {
            this->buffer_sizes[current_index] = total_size;
            this->saved_data[current_index] = current_buffer = (uint8_t*)realloc(current_buffer, total_size);
        }
        uint8_t* buffer_write = current_buffer;
        this->for_each_alloc([&](AllocData* alloc) {
            SavedAlloc* saved_data = (SavedAlloc*)buffer_write;
            buffer_write += SavedAlloc::buffer_size(alloc);
            saved_data->ptr = alloc;
            saved_data->size = alloc->size;
            memcpy(saved_data->data, alloc->data, alloc->size);
        });
    }
    
    size_t rollback(size_t frames) {
        frames = std::min(frames, this->available_frames);
        if (frames) {
            size_t index = this->rollback_index(frames);
            this->for_each_saved_alloc(index, [=](SavedAlloc* saved_data) {
                AllocData* alloc = saved_data->ptr;
                alloc->rollback_metadata(frames);
                memcpy(alloc->data, saved_data->data, saved_data->size);
            });
            // Any allocations without a rollback tag set
            // must have allocated after this rollback frame,
            // so free those to prevent memory leaks.
            this->for_each_alloc([](AllocData* alloc) {
                if (alloc->rollback_tag) {
                    alloc->rollback_tag = false;
                } else {
                    alloc->node.unlink();
                    free(alloc);
                }
            });
        }
        return frames;
    }
};

static AllocManager alloc_man;

// External definitions

void tick_allocs() {
    alloc_man.tick();
}

size_t rollback_allocs(size_t frames) {
    return alloc_man.rollback(frames);
}

void reset_rollback_buffers() {
    alloc_man.available_frames = 0;
}

void* cdecl my_malloc(size_t size) {
    AllocData* real_alloc = (AllocData*)malloc(AllocData::buffer_size(size));
    real_alloc->init(size);
    alloc_man.append(real_alloc);
    return &real_alloc->data;
}

void cdecl my_free(void* ptr) {
    if (ptr) {
        AllocData* real_alloc = AllocData::get_from_ptr(ptr);
        real_alloc->start_free(SAVED_FRAMES);
    }
}

void* cdecl my_realloc(void* ptr, size_t new_size) {
    if (ptr) {
        AllocData* real_alloc = AllocData::get_from_ptr(ptr);
        if (new_size) {
            if (new_size > real_alloc->size) {
                AllocData* new_alloc = (AllocData*)_expand(real_alloc, AllocData::buffer_size(new_size));
                if (new_alloc) {
                    new_alloc->reinit(new_size);
                } else {
                    ptr = my_malloc(new_size);
                    memcpy(ptr, real_alloc->data, real_alloc->size);
                    real_alloc->start_free(SAVED_FRAMES);
                }
            }
            return ptr;
        }
        real_alloc->start_free(SAVED_FRAMES);
        return NULL;
    }
    return my_malloc(new_size);
}