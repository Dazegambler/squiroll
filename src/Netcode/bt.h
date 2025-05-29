#pragma once
#ifndef BT_H
#define BT_H

#include "util.h"

// Bullet's Vector3 actually has 4 elements because of SIMD
struct alignas(16) btVector3 {
    //float v[4];
    vec<float, 4, true> v;
};

static_assert(sizeof(btVector3) == 0x10);

struct btMatrix3x3 {
    btVector3 m[3];
};

static_assert(sizeof(btMatrix3x3) == 0x30);

struct btTransform {
    btMatrix3x3 basis;
    btVector3 origin;
};

static_assert(sizeof(btTransform) == 0x40);

struct btCollisionShape {
    // TODO: Make vtable explicit instead of trusting compiler with function order
    virtual void unk0();
    virtual void getAabb(btTransform* t, btVector3* aabbMin, btVector3* aabbMax);

    // void* vtbl // 0x0
    uint32_t shape; // 0x4
    // 0x8, unknown total size
};

struct btBroadphaseProxy {
    void* m_clientObject;
    uint16_t m_collisionFilterGroup;
    uint16_t m_collisionFilterMask;
};

struct btGhostObject {
    char __unk0[0x10]; // 0x0
    btTransform m_worldTransform; // 0x10
    char __unk50[0xC8 - 0x50]; // 0x50
    btBroadphaseProxy* m_broadphaseProxy; // 0xC8
    btCollisionShape* m_collisionShape; // 0xCC
    char __unkD0[8]; // 0xD0
    uint32_t m_collisionFlags; // 0xD8
    char __unkDC[0x280 - 0xDC]; // 0xDC
    // 0x280
};

static_assert(sizeof(btGhostObject) == 0x280);

template<typename T>
struct btAlignedObjectArray {
    size_t m_size; // 0x0
    size_t m_capacity; // 0x4
    T* m_data; // 0x8
    bool m_ownsMemory; // 0xC
    // 0x10
};

static_assert(sizeof(btAlignedObjectArray<void>) == 0x10);

struct btCollisionWorld {
    void* vtbl; // 0x0
    char __unk4[4]; // 0x4
    btAlignedObjectArray<btGhostObject*> m_collisionObjects; // 0x8
    char __unk18[0x150 - 0x18]; // 0x18 
};

static_assert(sizeof(btCollisionWorld) == 0x150);


#endif