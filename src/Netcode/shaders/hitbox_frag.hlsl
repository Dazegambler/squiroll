// fxc /T ps_5_0 /O3 /E main src/Netcode/shaders/hitbox_frag.hlsl /Fo src/Netcode/shaders/hitbox_frag.cso && tools/make_embed_windows src/Netcode/shaders/hitbox_frag.cso src/Netcode/shaders/hitbox_frag.cso.h

#include "hitbox_common.hlsli"

cbuffer fragment {
    float2 alphas;
};

float4 main(PSInput input) : SV_TARGET {
    // Yes, branching in a shader
    if (input.flags & 1) {
        float sq_dist = input.uv.x * input.uv.x + input.uv.y * input.uv.y;
        if (sq_dist > 1.0f)
            discard;

        bool is_border = sq_dist >= input.thresholds[0];
        return float4(input.col, alphas[is_border]);
    } else {
        bool is_border = abs(input.uv.x) >= input.thresholds[0] || abs(input.uv.y) >= input.thresholds[1];
        return float4(input.col, alphas[is_border]);
    }
}
