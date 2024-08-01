#include "AllocMan.h"

// AllocNode member functions
void AllocNode::prepend(AllocNode* new_node) {
    new_node->next = this;
    this->prev = new_node;
}

void AllocNode::append(AllocNode* new_node) {
    this->next->prepend(new_node);
    new_node->prepend(this);
}

void AllocNode::unlink() {
    AllocNode* next_node = this->next;
    AllocNode* prev_node = this->prev;
    next_node->prev = prev_node;
    prev_node->next = next_node;
}

void AllocNode::relink() {
    this->next->prev = this;
    this->prev->next = this;
}

// AllocData member functions
void AllocData::init(size_t size) {
    this->size = size;
    this->timer = -1;
}

void AllocData::reinit(size_t size) {
    this->size = size;
    this->node.relink();
}

void AllocData::start_free(int8_t time) {
    this->timer = time;
}

AllocTickResult AllocData::tick() {
    if (!(this->timer < 0) && --this->timer != 0) {
        this->node.unlink();
        return FreeData;
    }
    return SaveData;
}

void AllocData::rollback(size_t frames) {
    if (!(this->timer < 0)) {
        this->timer += frames;
    }
}

constexpr AllocManager::AllocManager() : saved_data_index(0), saved_data{}, buffer_sizes{} {
    this->dummy_node.next = &this->dummy_node;
    this->dummy_node.prev = &this->dummy_node;
}

size_t AllocManager::increment_index() {
    size_t next_index = this->saved_data_index + 1 & FRAME_WRAP_MASK;
    return this->saved_data_index = next_index;
}

size_t AllocManager::rollback_index(size_t frames) {
    size_t next_index = this->saved_data_index - frames & FRAME_WRAP_MASK;
    return this->saved_data_index = next_index;
}

void AllocManager::append(AllocData *data) {
    this->dummy_node.prev->append(&data->node);
}

template <typename L>
void AllocManager::for_each_alloc(const L& lambda) {
    AllocNode* node = this->dummy_node.next;
    for (AllocNode* next_node; node != &this->dummy_node; node = next_node) {
        next_node = node->next;
        lambda((AllocData*)node);
    }
}

template <typename L>
void AllocManager::for_each_saved_alloc(size_t index, const L& lambda) {
    uint8_t* buffer = this->saved_data[index];
    uint8_t* buffer_end = buffer + this->buffer_sizes[index];
    while (buffer < buffer_end) {
        Alloc* saved_data = (Alloc*)buffer;
        buffer += sizeof(Alloc) + saved_data->size;
        lambda(saved_data);
    }
}

void AllocManager::tick() {
    size_t total_size = 0;
    for_each_alloc([&](AllocData* alloc) {
        switch (alloc->tick()) {
            case SaveData:
                total_size += sizeof(AllocData) + alloc->size;
                break;
            case FreeData:
                free(alloc);
                break;
        }
    });
    size_t current_index = this->increment_index();
    uint8_t*& current_buffer = this->saved_data[current_index];
    if (total_size > this->buffer_sizes[current_index]) {
        this->buffer_sizes[current_index] = total_size;
        current_buffer = (uint8_t*)realloc(current_buffer, total_size);
    }
    uint8_t* buffer_write = current_buffer;
    for_each_alloc([&](AllocData* alloc) {
        Alloc* saved_data = (Alloc*)buffer_write;
        buffer_write += sizeof(Alloc) + alloc->size;
        saved_data->ptr = alloc;
        saved_data->size = alloc->size;
        memcpy(saved_data->data, alloc->data, alloc->size);
    });
}

void AllocManager::rollback(size_t frames) {
    size_t index = this->rollback_index(frames);
    for_each_saved_alloc(index, [](Alloc* saved_data) {
        memcpy(saved_data->ptr->data, saved_data->data, saved_data->size);
    });
}

static AllocManager alloc_man;

void tick_allocs() {
    alloc_man.tick();
}

void rollback_allocs(size_t frames) {
    alloc_man.rollback(frames);
}

AllocData* get_alloc_data(void* ptr) {
    return (AllocData*)((uintptr_t)ptr - offsetof(AllocData, data));
}

void* cdecl my_malloc(size_t size) {
    AllocData* real_alloc = (AllocData*)malloc(sizeof(AllocData) + size);
    real_alloc->init(size);
    alloc_man.append(real_alloc);
    return &real_alloc->data;
}

void cdecl my_free(void* ptr) {
    if (ptr) {
        AllocData* real_alloc = get_alloc_data(ptr);
        real_alloc->start_free(SAVED_FRAMES);
    }
}

void* cdecl my_realloc(void* ptr, size_t new_size) {
    if (ptr) {
        AllocData* real_alloc = get_alloc_data(ptr);
        if (new_size) {
            AllocData* new_alloc = (AllocData*)realloc(real_alloc, new_size + sizeof(AllocData));
            if (new_alloc) {
                new_alloc->reinit(new_size);
            }
        } else {
            real_alloc->start_free(SAVED_FRAMES);
        }
        return NULL;
    }
    return my_malloc(new_size);
}

void* cdecl my_realloc_sq(void* ptr, size_t old_size, size_t new_size) {
    return my_realloc(ptr, new_size);
}