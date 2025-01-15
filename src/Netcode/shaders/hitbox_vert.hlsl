// fxc /T vs_5_0 /O3 /E main src/Netcode/shaders/hitbox_vert.hlsl /Fo src/Netcode/shaders/hitbox_vert.cso && tools/make_embed_windows src/Netcode/shaders/hitbox_vert.cso src/Netcode/shaders/hitbox_vert.cso.h

#include "hitbox_common.hlsli"

struct VSInput {
    // Already in clip space!
    float2 pos : POSITION0;
};

struct Hitbox {
    uint col;
    uint flags; // Only specifies circle/rect for now
    float2 thresholds;
};

StructuredBuffer<Hitbox> hitboxes;

float4 decode_color(uint col) {
    return float4(float((col >> 16) & 0xFF) / 255.0, float((col >> 8) & 0xFF) / 255.0, float(col & 0xFF) / 255.0, float((col >> 24) & 0xFF) / 255.0);
}

float2 snap_to_pixel(float2 pos) {
    const float2 half_res = float2(1280.0f / 2.0f, 720.0f / 2.0f);
    return round(pos * half_res) / half_res;
}

PSInput main(VSInput input, uint vertex_raw : SV_VertexID) {
    uint idx = vertex_raw >> 2;
    uint vtx = vertex_raw & 3;

    PSInput output;
    output.pos = float4(snap_to_pixel(input.pos), 0.5f, 1.0f);
    output.uv = float2(vtx == 1 || vtx == 2, vtx < 2) * 2.0f - 1.0f;
    output.col = decode_color(hitboxes[idx].col);
    output.flags = hitboxes[idx].flags;
    output.thresholds = hitboxes[idx].thresholds;
    return output;
}
