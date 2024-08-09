#include <stdint.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <algorithm>
#include <bit>
#include "AllocMan.h"
#include "log.h"

#define SHRINK_ROLLBACK_BUFFERS 0

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

struct SavedAlloc;

struct AllocData {
    AllocNode node;
    size_t size;
    rollback_timer_t free_timer;
    union {
        uint8_t flags;
        struct {
            bool rollback_tag : 1;
            bool has_record : 1;
        };
    };
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
        this->has_record = false;
    }
    
    void reinit(size_t size) {
        this->size = size;
    }
    
    void cleanup() {
        this->node.unlink();
    }
    
    void start_free(rollback_timer_t time) {
        this->free_timer = time;
    }
    
    AllocTickResult tick() {
        this->has_record = true;
        if (
            this->free_timer == 0 ||
            --this->free_timer != 0
        ) {
            return SaveData;
        }
        return FreeData;
    }
    
    inline void rollback(size_t frames, SavedAlloc* saved_alloc);
};

struct SavedAlloc {
    AllocData* ptr;
    size_t size;
    alignas(4) unsigned char data[];
    
    static inline size_t buffer_size(AllocData* alloc) {
        return sizeof(SavedAlloc) + alloc->size;
    }
    
    size_t total_size() const {
        return sizeof(SavedAlloc) + this->size;
    }
    
    void record(AllocData* alloc) {
        this->ptr = alloc;
        size_t size = this->size = alloc->size;
        memcpy(this->data, alloc->data, size);
    }
};

inline void AllocData::rollback(size_t frames, SavedAlloc* saved_alloc) {
    if (
        this->free_timer != 0 &&
        (this->free_timer += frames) > SAVED_FRAMES
    ) {
        this->free_timer = 0;
    }
    this->rollback_tag = true;
    memcpy(this->data, saved_alloc->data, saved_alloc->size);
}

struct AllocManager {
    static inline constexpr size_t FRAME_WRAP_MASK = SAVED_FRAMES - 1;
    
    AllocNode dummy_node;
    size_t saved_data_index;
    size_t available_frames;
    uint8_t* saved_data[SAVED_FRAMES];
    size_t filled_sizes[SAVED_FRAMES];
    size_t buffer_sizes[SAVED_FRAMES];

    constexpr AllocManager()
        : saved_data_index(0), available_frames(0), saved_data{}, filled_sizes{}, buffer_sizes{}
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
    
    void print_buffer_sizes() const {
        size_t total_filled = 0;
        size_t total_buffer = 0;
        for (size_t i = 0; i < SAVED_FRAMES; ++i) {
            size_t filled = this->filled_sizes[i];
            total_filled += filled;
            size_t buffer = this->buffer_sizes[i];
            total_buffer += buffer;
            log_printf(
                "%2zu: %zu/%zu (%.3f)\n"
                , i, filled, buffer, (double)filled / (double)buffer
            );
        }
        log_printf(
            "Total (%zu): %zu/%zu (%.3f)\n"
            , SAVED_FRAMES, total_filled, total_buffer, (double)total_filled / (double)total_buffer
        );
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
            buffer += saved_data->total_size();
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
                    alloc->cleanup();
                    free(alloc);
                    break;
            }
        });
        size_t current_index = this->increment_index();
        this->filled_sizes[current_index] = total_size;
        uint8_t* current_buffer = this->saved_data[current_index];
#if !SHRINK_ROLLBACK_BUFFERS
        if (total_size > this->buffer_sizes[current_index])
#endif
        {
            this->buffer_sizes[current_index] = total_size;
            this->saved_data[current_index] = current_buffer = (uint8_t*)realloc(current_buffer, total_size);
        }
        uint8_t* buffer_write = current_buffer;
        this->for_each_alloc([&](AllocData* alloc) {
            SavedAlloc* saved_data = (SavedAlloc*)buffer_write;
            buffer_write += SavedAlloc::buffer_size(alloc);
            saved_data->record(alloc);
        });
    }
    
    size_t rollback(size_t frames) {
        frames = std::min(frames, this->available_frames);
        if (frames) {
            size_t index = this->rollback_index(frames);
            this->for_each_saved_alloc(index, [=](SavedAlloc* saved_data) {
                AllocData* alloc = saved_data->ptr;
                alloc->rollback(frames, saved_data);
            });
            // Any allocations without a rollback tag set
            // must have allocated after this rollback frame,
            // so free those to prevent memory leaks.
            this->for_each_alloc([](AllocData* alloc) {
                if (alloc->rollback_tag) {
                    alloc->rollback_tag = false;
                } else {
                    alloc->cleanup();
                    free(alloc);
                }
            });
        }
        return frames;
    }
};

static AllocManager alloc_man;

void free_alloc(AllocData* alloc) {
    if (alloc->has_record) {
        alloc->start_free(SAVED_FRAMES);
    } else {
        alloc->cleanup();
        free(alloc);
    }
}

// External definitions

void tick_allocs() {
    alloc_man.tick();
}

size_t fastcall rollback_allocs(size_t frames) {
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

void* cdecl my_calloc(size_t num, size_t size) {
    size_t total_size = num * size;
    void* ret = my_malloc(total_size);
    return memset(ret, 0, total_size);
}

void cdecl my_free(void* ptr) {
    if (ptr) {
        AllocData* real_alloc = AllocData::get_from_ptr(ptr);
        free_alloc(real_alloc);
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
                    free_alloc(real_alloc);
                }
            }
            return ptr;
        }
        free_alloc(real_alloc);
        return NULL;
    }
    return my_malloc(new_size);
}