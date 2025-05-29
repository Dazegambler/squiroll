#pragma once
#ifndef SQRAT_H
#define SQRAT_H

struct SqratObject {
    char dont_care0[0x14]; // 0x0
    // 0x14
};

static_assert(sizeof(SqratObject) == 0x14);

struct SqratFunction {
    char dont_care0[0x14]; // 0x0
    // 0x14
};

static_assert(sizeof(SqratFunction) == 0x14);
#endif