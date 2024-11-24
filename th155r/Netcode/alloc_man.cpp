#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <stdint.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <algorithm>
#include <bit>
#include <unordered_set>
//#include <unordered_map>
#include <mutex>

#include "alloc_man.h"
#include "log.h"
#include "util.h"

#if ALLOCATION_PATCH_TYPE != PATCH_NO_ALLOCS

#define SHRINK_ROLLBACK_BUFFERS 0

// Internal definitions

static inline constexpr size_t MAX_ROLLBACK_TIMER = SAVED_FRAMES * 2;

static inline constexpr size_t ROLLBACK_TIMER_RECORD_THRESHOLD = SAVED_FRAMES;

using rollback_timer_t = UBitIntType<std::bit_width(MAX_ROLLBACK_TIMER)>;

// size: 0x8
struct AllocNode {
    AllocNode* next; // 0x0
    AllocNode* prev; // 0x4
    // 0x8

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
    PreserveData,
    FreeData
};

struct SavedAlloc;

// size: 0x10+
struct AllocData {
    AllocNode node; // 0x0
    size_t size; // 0x8
    rollback_timer_t free_timer; // 0xC
    union {
        uint8_t flags; // 0xD
        struct {
            bool rollback_tag : 1;
            bool has_record : 1;
        };
    };
    // two bytes of padding
    alignas(__STDCPP_DEFAULT_NEW_ALIGNMENT__) unsigned char data[]; // 0x10
    
    static forceinline AllocData* get_from_ptr(void* ptr) {
        return (AllocData*)((uintptr_t)ptr - offsetof(AllocData, data));
    }
    
    static forceinline size_t buffer_size(size_t size) {
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
#if MEMORY_DEBUG_LEVEL >= MEMORY_DEBUG_LIGHT
        // Write dummy values in to make it obvious
        // if a node is getting freed twice
        this->node.next = (AllocNode*)0x00000318;
        this->node.prev = (AllocNode*)0x00000318;
#endif
    }
    
    void free() {
        this->cleanup();
        ::free(this);
    }
    
    void start_free() {
        this->free_timer = (rollback_timer_t)MAX_ROLLBACK_TIMER;
    }
    
    AllocTickResult tick() {
        this->has_record = true;
        if (this->free_timer == 0) {
            return SaveData;
        }
        if (--this->free_timer != 0) {
            return PreserveData;
        }
        return FreeData;
    }
    
    inline bool rollback(size_t frames, SavedAlloc* saved_alloc);
};

// size: 0x8+
struct SavedAlloc {
    AllocData* ptr; // 0x0
    size_t size; // 0x4
    alignas(4) unsigned char data[]; // 0x8
    
    static forceinline size_t save_buffer_size(AllocData* alloc) {
        return sizeof(SavedAlloc) + alloc->size;
    }
    static forceinline size_t preserve_buffer_size(AllocData* alloc) {
        return sizeof(SavedAlloc);
    }
    
    size_t total_size() const {
        return sizeof(SavedAlloc) + this->size;
    }
    
    size_t record(AllocData* alloc) {
        this->ptr = alloc;
        size_t size = 0;
        if (alloc->free_timer == 0) {
            size = alloc->size;
            memcpy(this->data, alloc->data, size);
        }
        this->size = size;
        return sizeof(SavedAlloc) + size;
    }
};

inline bool AllocData::rollback(size_t frames, SavedAlloc* saved_alloc) {
    this->rollback_tag = true;
    size_t current_free_timer = this->free_timer;
    if (current_free_timer != 0) {
        if (current_free_timer <= ROLLBACK_TIMER_RECORD_THRESHOLD) {
            // This node can't possibly re-stabilize, so do nothing
            return false;
        }
        if ((current_free_timer += frames) > MAX_ROLLBACK_TIMER) {
            // This node has re-stabilized, so copy the data back
            this->free_timer = 0;
        } else {
            // This node could re-stabilize, but the data
            // doesn't need to be copied back yet
            this->free_timer = (rollback_timer_t)current_free_timer;
            return false;
        }
    }
    memcpy(this->data, saved_alloc->data, saved_alloc->size);
    return true;
}

// size: 0x10 + 0xC * SAVED_FRAMES
struct AllocManager {
    static inline constexpr size_t FRAME_WRAP_MASK = SAVED_FRAMES - 1;
    
    AllocNode dummy_node; // 0x0
    size_t saved_data_index; // 0x8
    size_t available_frames; // 0xC
    uint8_t* saved_data[SAVED_FRAMES]; // 0x10
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
    forceinline void for_each_alloc(const L& lambda) {
        AllocNode* node = this->dummy_node.next;
        for (AllocNode* next_node; node != &this->dummy_node; node = next_node) {
            next_node = node->next;
            lambda((AllocData*)node);
        }
    }

    template <typename L>
    forceinline void for_each_saved_alloc(size_t index, const L& lambda) {
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
                default:
                    unreachable;
                case SaveData:
                    total_size += SavedAlloc::save_buffer_size(alloc);
                    break;
                case PreserveData:
                    total_size += SavedAlloc::preserve_buffer_size(alloc);
                    break;
                case FreeData:
                    alloc->free();
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
            buffer_write += saved_data->record(alloc);
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
                    alloc->free();
                }
            });
        }
        return frames;
    }
};

static AllocManager alloc_man;

static SpinLock alloc_lock;

static void free_alloc(AllocData* alloc) {
    if (alloc->has_record) {
        alloc->start_free();
    } else {
        alloc->free();
    }
}

// External definitions

void tick_allocs() {
    std::lock_guard<SpinLock> lock(alloc_lock);
    alloc_man.tick();
}

size_t fastcall rollback_allocs(size_t frames) {
    std::lock_guard<SpinLock> lock(alloc_lock);
    return alloc_man.rollback(frames);
}

void update_allocs() {
    std::lock_guard<SpinLock> lock(alloc_lock);
    if (HasScrollLockChanged()) {
        alloc_man.rollback(SAVED_FRAMES);
    }
    else {
        alloc_man.tick();
    }
}

void reset_rollback_buffers() {
    alloc_man.available_frames = 0;
}

void* cdecl my_malloc(size_t size) {
    AllocData* real_alloc = (AllocData*)malloc(AllocData::buffer_size(size));
    if (expect(real_alloc != NULL, true)) {
        std::lock_guard<SpinLock> lock(alloc_lock);
        real_alloc->init(size);
        alloc_man.append(real_alloc);
        return &real_alloc->data;
    }
    // Out of memory
    return NULL;
}

void* cdecl my_calloc(size_t num, size_t size) {
    size_t total_size = num * size;
    void* ret = my_malloc(total_size);
    if (expect(ret != NULL, true)) {
        return memset(ret, 0, total_size);
    }
    // Out of memory
    return NULL;
}

void cdecl my_free(void* ptr) {
    if (ptr) {
        AllocData* real_alloc = AllocData::get_from_ptr(ptr);
        free_alloc(real_alloc);
    }
}

size_t cdecl my_msize(void* ptr) {
    AllocData* real_alloc = AllocData::get_from_ptr(ptr);
    return real_alloc->size;
}

void* cdecl my_expand(void* ptr, size_t new_size) {
    AllocData* real_alloc = AllocData::get_from_ptr(ptr);
    if (
        new_size <= real_alloc->size ||
        _expand(real_alloc, AllocData::buffer_size(new_size))
    ) {
        return ptr;
    }
    return NULL;
}

void* cdecl my_realloc(void* ptr, size_t new_size) {
    if (ptr) {
        AllocData* real_alloc = AllocData::get_from_ptr(ptr);
        if (new_size) {
            size_t current_size = real_alloc->size;
            if (new_size > current_size) {
                if (_expand(real_alloc, AllocData::buffer_size(new_size))) {
                    // Block expanded in place
                    real_alloc->reinit(new_size);
                } else {
                    // Block could not expand in place, allocate a new block
                    ptr = my_malloc(new_size);
                    if (expect(ptr != NULL, true)) {
                        memcpy(ptr, real_alloc->data, current_size);
                        free_alloc(real_alloc);
                    } else {
                        // Out of memory
                        // ptr is NULL anyway, so don't do anything
                    }
                }
            }
            return ptr;
        }
        free_alloc(real_alloc);
        return NULL;
    }
    return my_malloc(new_size);
}

void* cdecl my_recalloc(void* ptr, size_t num, size_t size) {
    if (ptr) {
        size_t new_size = num * size;
        AllocData* real_alloc = AllocData::get_from_ptr(ptr);
        if (new_size) {
            size_t current_size = real_alloc->size;
            if (new_size > current_size) {
                if (_expand(real_alloc, AllocData::buffer_size(new_size))) {
                    // Block expanded in place
                    real_alloc->reinit(new_size);
                } else {
                    // Block could not expand in place, allocate a new block
                    ptr = my_malloc(new_size);
                    if (expect(ptr != NULL, true)) {
                        memcpy(ptr, real_alloc->data, current_size);
                        free_alloc(real_alloc);
                    } else {
                        // Out of memory
                        return NULL;
                    }
                }
                memset(based_pointer(ptr, current_size), 0, new_size - current_size);
            }
            return ptr;
        }
        free_alloc(real_alloc);
        return NULL;
    }
    return my_calloc(num, size);
}

#endif