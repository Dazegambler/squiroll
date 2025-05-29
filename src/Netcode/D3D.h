#pragma once
#ifndef D3D_H
#define D3D_H

#include <d3d11.h>
#include "util.h"

typedef struct _D3DMATRIX {
    /*
    union {
        struct {
            float _11, _12, _13, _14;
            float _21, _22, _23, _24;
            float _31, _32, _33, _34;
            float _41, _42, _43, _44;
        };
        float m[4][4];
    };
    */
    vec<float, 4> m[4];
}D3DMATRIX;

#endif