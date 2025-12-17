#pragma once

#ifndef FILE_REPLACEMENT_H
#define FILE_REPLACEMENT_H 1

#include <stdlib.h>
#include <stdint.h>
#include <windows.h>
#include "util.h"

struct EmbedData {
    const uint8_t *const data;
    const size_t length;

    constexpr EmbedData() : data(nullptr), length(0) {}

    template<size_t N>
    constexpr EmbedData(const uint8_t(&data)[N]) : data(data), length(N) {}

    constexpr operator bool() const {
        return this->data != NULL;
    }
};

EmbedData get_embed_data(const char *name);

#endif