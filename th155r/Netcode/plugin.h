#pragma once

#ifndef SHARED_HEADER_H
#define SHARED_HEADER_H 1

#include <stdlib.h>
#include <stdint.h>
#include <windows.h>
#include "util.h"

struct ChangeData
{
    const void* apply;
    const size_t length;

    constexpr ChangeData() : data(nullptr), length(0) {}

    template <size_t N>
    constexpr ChangeData(const uint8_t (&data)[N]) : data(data), length(N) {}

    constexpr operator bool() const
    {
        return this->data != NULL;
    }
};
#endif