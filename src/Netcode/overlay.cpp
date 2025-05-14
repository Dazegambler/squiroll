#include <cstdint>
#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <d3d11.h>
#include <vector>
#include <memory>
#include <list>

#include "config.h"
#include "log.h"
#include "squirrel.h"
#include "util.h"
#include "overlay.h"

static constexpr uint8_t hitbox_vert_cso[] = {
#include "shaders/hitbox_vert.cso.h"
};
static constexpr uint8_t hitbox_frag_cso[] = {
#include "shaders/hitbox_frag.cso.h"
};

#define MAX_HITBOXES 1024

struct btVector3;

#define d3d11_dev ((ID3D11Device**)0x4DAE9C_R)
#define d3d11_imm ((ID3D11DeviceContext**)0x4DAE98_R)
#define btBox2dShape_getHalfExtentsWithMargin ((btVector3* (*thiscall)(btCollisionShape*, btVector3*))0x1C0EB0_R)
//#define draw_rect ((void (vectorcall*)(const float*, float, float, float, float))0x39600_R)

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
} D3DMATRIX;

// TODO: Move this stuff to its own header. It might be useful for rollback too
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

struct ManbowWorld2D {
    char __unk0[0x20]; // 0x0
    btCollisionWorld* bullet_world; // 0x20
    char __unk24[8]; // 0x24
    // 0x2C
};

static_assert(sizeof(ManbowWorld2D) == 0x2C);

struct ManbowActorCollisionData {
    char __unk0[0xC]; // 0x0
    btGhostObject* obj_ptr; // 0xC
    btGhostObject obj; // 0x10
};

struct Unk130 {
    char            __unk0[0xC]; // 0x0
    uint32_t        __unkc; // 0xc
};

struct TakeData {
    char            __unk0[0xc]; // 0x0
    TakeData*       previous; // 0x4
    TakeData*       next; // 0x8
    uint32_t        __unkc; // 0xc
    int32_t        frame_total; // 0x10
};

// struct IAnimationTake;

// struct Actor2DTakeData;

struct AnimationNode {
    void*           __unk0; // 0x0 
    AnimationNode*  next; // 0x4 <
    AnimationNode*  previous; // 0x8
    char            __unkC; // 0xC
    bool            __unkD; // 0xD
    char            __pad[0x2]; // 0xE
    int32_t         __unk10; // 0x10
    TakeData*          __unk14; // 0x14
};

struct AnimationSet2D {
    void*           vtbl; // 0x0
    void*           __unk4; // 0x4
    AnimationNode*  head; // 0x8 <
};

// size: 0x120
struct ManbowAnimationControllerBase {
    void* vftable; // 0x0
    char __unk4[0x18]; // 0x4
    uint32_t motion; // 0x1c
    int32_t key_take; // 0x20
    uint32_t keyframe; // 0x24
    float red; // 0x28
    float green; // 0x2C
    float blue; // 0x30
    float alpha; // 0x34
    D3DMATRIX __matrix_38; // 0x38
    std::vector<std::shared_ptr<ManbowActorCollisionData>> collision_boxes; // 0x78
    std::vector<std::shared_ptr<ManbowActorCollisionData>> hit_boxes; // 0x84
    std::vector<std::shared_ptr<ManbowActorCollisionData>> hurt_boxes; // 0x90
    char __unk9C[0x84]; // 0x9C
    // 0x120
};

// size: 0x230
struct ManbowAnimationController2D : ManbowAnimationControllerBase {
    // ManbowAnimationControllerBase base; // 0x0
    void* tf4_imaterial_vftable; // 0x120 (this probably does nothing)
    AnimationSet2D* anim_set;// 0x124
    void* __unk128; // 0x128
    TakeData* take; // 0x12C
    Unk130* __unk130; // 0x130
    int32_t __unk134; // 0x134
    uint32_t current_frame; // 0x138
    char __unk13C[0x224 - 0x13C]; // 0x13C
    std::vector<std::shared_ptr<TakeData>> __unk224; // 0x224
    // 0x230
};

static_assert(sizeof(ManbowAnimationController2D) == 0x230); //something is not alligned by 4 bytes

// size: 0x268
struct ManbowAnimationController3D : ManbowAnimationControllerBase {
    // ManbowAnimationControllerBase base; // 0x0
    char __unk120[0x148]; // 0x120
    // 0x268
};

// size: 0x280
struct ManbowAnimationControllerDynamic : ManbowAnimationController2D {
    // ManbowAnimationController2D base; // 0x0
    char __unk230[0x50]; // 0x230
    // 0x280
};

// size: 0x240
struct ManbowAnimationControllerStencil : ManbowAnimationController2D {
    // ManbowAnimationController2D base; // 0x0
    char __unk230[0x10]; // 0x230
    // 0x240
};

// size: 0x300
struct ManbowAnimationControllerTrail : ManbowAnimationController2D {
    // ManbowAnimationController2D base; // 0x0
    char __unk230[0xD0]; // 0x230
    // 0x300
};

struct ManbowCamera2D {
    char dont_care0[0x1C]; // 0x0
    D3DMATRIX view_proj_matrix; // 0x1C
    D3DMATRIX view_matrix; // 0x5C
    D3DMATRIX proj_matrix; // 0x9C
    char dont_care9C[0x134 - 0xDC]; // 0xDC
    // 0x134
};

static_assert(sizeof(ManbowCamera2D) == 0x134);

struct ManbowActor2DGroup;

struct ManbowActor2D {
    void* vtbl; // 0x0
    char __unk4[8]; // 0x4
    float pos[3]; // 0xC
    int32_t id; // 0x18
    float left; // 0x1C
    float top; // 0x20
    float right; // 0x24
    float bottom; // 0x28
    float vx; // 0x2C
    float vy; // 0x30
    char __unk34[4]; // 0x34
    float direction; // 0x38
    std::shared_ptr<ManbowAnimationController2D> anim_controller; // 0x3C
    char __unk44[4]; // 0x44
    float ox; // 0x48
    float oy; // 0x4C
    float s[3]; // 0x50, skew???
    float r[3]; // 0x5C, rotation???
    void* /* Manbow::Actor2DManager* */ actor2d_mgr; // 0x68
    ManbowActor2DGroup* actor2d_group; // 0x6C
    uint8_t active_flags; // 0x70
    char probably_padding[3]; // 0x71
    SQObject sq_obj; // 0x74
    uint32_t collision_group; // 0x7C
    uint32_t collision_mask; // 0x80
    uint32_t callback_group; // 0x84
    uint32_t callback_mask; // 0x88
    float hitLeft; // 0x8C
    float hitTop; // 0x90
    float hitRight; // 0x94
    float hitBottom; // 0x98
    char __unk9C[0xC]; // 0x9C
    SqratFunction update_func; // 0xA8
    SqratFunction __sqrat_funcBC; // 0xBC
    char __unkD0[8]; // 0xD0
    void* __ptrD8; // 0xD8
    uint32_t group_flags; // 0xDC
    uint32_t list_idx; // 0xE0
    uint32_t __uintE4; // 0xE4
    uint32_t __id2; // 0xE8
    // 0xEC
};

static_assert(sizeof(ManbowActor2D) == 0xEC);

struct ManbowActor2DGroup {
    void* vtbl; // 0x0
    std::shared_ptr<ManbowActor2DGroup> __shared_ptr4; // 0x4
    std::list<std::shared_ptr<ManbowActor2D>> actor_list; // 0xC
    std::vector<ManbowActor2D*> actor_vec; // 0x14
    uint32_t size; // 0x20
    uint32_t update_mask; // 0x24
    bool pending_release; // 0x28
    char probably_padding[3]; // 0x29
    char __unk2C[0xC]; // 0x2C
    std::shared_ptr<ManbowWorld2D> world; // 0x38
    SqratFunction on_hit_collision; // 0x40
    SqratFunction on_hit_actor; // 0x54
    SqratFunction on_move; // 0x68
    char __unk7C[4]; // 0x7C
    SqratObject camera_obj; // 0x80
    ManbowCamera2D* camera; // 0x94
    void (thiscall *update_func)(ManbowActor2DGroup*); // 0x98
    // 0x9C
};

static_assert(sizeof(ManbowActor2DGroup) == 0x9C);

enum DrawType : uint8_t {
    DRAW_RECT,
    DRAW_CIRCLE,
};

struct DrawObj {
    DrawType prim;
    uint16_t group;
    union {
        union {
            float points[2 * 4];
            vec<float, 4> points_vec[2];
        } rect;
        union {
            float aabb[2 * 2];
            vec<float, 4> aabb_vec;
        } circle;
    };

    // This avoids calling memset when resizing vectors
    inline DrawObj() {}
};

struct HitboxVertex {
    float pos[2];
};

// Constant buffer sizes have to be 16-byte aligned
struct alignas(16) HitboxConstantBuffer {
    float alphas[2];
};

struct HitboxGPUData {
    uint32_t col;
    uint32_t flags;
    float thresholds[2];
};

static bool overlay_supported = true;

static ID3D11VertexShader* hitbox_vs = nullptr;
static ID3D11PixelShader* hitbox_ps = nullptr;
static ID3D11InputLayout* hitbox_il = nullptr;
static ID3D11Buffer* hitbox_vb = nullptr;
static ID3D11Buffer* hitbox_ib = nullptr;
static ID3D11Buffer* hitbox_sb = nullptr;
static ID3D11ShaderResourceView* hitbox_sb_srv = nullptr;
static ID3D11Buffer* hitbox_cb = nullptr;

#define CHECK_RES(x) \
    res = x; \
    if (FAILED(res)) { \
        mboxf("D3D11 Exception", MB_OK | MB_ICONERROR, [=](auto add_text) { \
            add_text(#x "\nfailed with result 0x%08X", res); \
        }); \
    }
void overlay_init() {
    HRESULT res;
    ID3D11Device* dev = *d3d11_dev;

    if (dev->GetFeatureLevel() < D3D_FEATURE_LEVEL_11_0) {
        log_printf("D3D11 feature level is too low to support the overlay!\n");
        overlay_supported = false;
        return;
    }

    CHECK_RES(dev->CreateVertexShader(hitbox_vert_cso, sizeof(hitbox_vert_cso), nullptr, &hitbox_vs));
    CHECK_RES(dev->CreatePixelShader(hitbox_frag_cso, sizeof(hitbox_frag_cso), nullptr, &hitbox_ps));

    static constexpr D3D11_INPUT_ELEMENT_DESC input_layout[] = {
        { "POSITION", 0, DXGI_FORMAT_R32G32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0 },
    };
    CHECK_RES(dev->CreateInputLayout(input_layout, countof(input_layout), hitbox_vert_cso, sizeof(hitbox_vert_cso), &hitbox_il));

    static constexpr D3D11_BUFFER_DESC vertex_desc = {
        .ByteWidth = sizeof(HitboxVertex) * MAX_HITBOXES * 4,
        .Usage = D3D11_USAGE_DYNAMIC,
        .BindFlags = D3D11_BIND_VERTEX_BUFFER,
        .CPUAccessFlags = D3D11_CPU_ACCESS_WRITE,
        .MiscFlags = 0,
        .StructureByteStride = 0,
    };
    CHECK_RES(dev->CreateBuffer(&vertex_desc, NULL, &hitbox_vb));

    uint16_t* index_vec = new uint16_t[MAX_HITBOXES * 6];
    for (size_t i = 0; i < MAX_HITBOXES; i++) {
        index_vec[i * 6] = i * 4;
        index_vec[i * 6 + 1] = i * 4 + 1;
        index_vec[i * 6 + 2] = i * 4 + 2;
        index_vec[i * 6 + 3] = i * 4;
        index_vec[i * 6 + 4] = i * 4 + 2;
        index_vec[i * 6 + 5] = i * 4 + 3;
    }
    static constexpr D3D11_BUFFER_DESC index_desc = {
        .ByteWidth = MAX_HITBOXES * 6 * sizeof(*index_vec),
        .Usage = D3D11_USAGE_IMMUTABLE,
        .BindFlags = D3D11_BIND_INDEX_BUFFER,
        .CPUAccessFlags = 0,
        .MiscFlags = 0,
        .StructureByteStride = 0,
    };
    D3D11_SUBRESOURCE_DATA index_init = {
        .pSysMem = index_vec,
    };
    CHECK_RES(dev->CreateBuffer(&index_desc, &index_init, &hitbox_ib));
    delete[] index_vec;

    static constexpr D3D11_BUFFER_DESC struct_desc = {
        .ByteWidth = sizeof(HitboxGPUData) * MAX_HITBOXES,
        .Usage = D3D11_USAGE_DYNAMIC,
        .BindFlags = D3D11_BIND_SHADER_RESOURCE,
        .CPUAccessFlags = D3D11_CPU_ACCESS_WRITE,
        .MiscFlags = D3D11_RESOURCE_MISC_BUFFER_STRUCTURED,
        .StructureByteStride = sizeof(HitboxGPUData),
    };
    CHECK_RES(dev->CreateBuffer(&struct_desc, NULL, &hitbox_sb));

    static constexpr D3D11_SHADER_RESOURCE_VIEW_DESC struct_srv = {
        .Format = DXGI_FORMAT_UNKNOWN,
        .ViewDimension = D3D11_SRV_DIMENSION_BUFFER,
        .Buffer = {
            .FirstElement = 0,
            .NumElements = MAX_HITBOXES,
        }
    };
    CHECK_RES(dev->CreateShaderResourceView(hitbox_sb, &struct_srv, &hitbox_sb_srv));

    static constexpr D3D11_BUFFER_DESC constant_desc = {
        .ByteWidth = sizeof(HitboxConstantBuffer),
        .Usage = D3D11_USAGE_DYNAMIC,
        .BindFlags = D3D11_BIND_CONSTANT_BUFFER,
        .CPUAccessFlags = D3D11_CPU_ACCESS_WRITE,
        .MiscFlags = 0,
        .StructureByteStride = 0,
    };
    CHECK_RES(dev->CreateBuffer(&constant_desc, NULL, &hitbox_cb));
}
#undef CHECK_RES

#define SAFE_RELEASE(x) \
    if (x) { \
        x->Release(); \
        x = nullptr; \
    }
void overlay_destroy() {
    SAFE_RELEASE(hitbox_vs);
    SAFE_RELEASE(hitbox_ps);
    SAFE_RELEASE(hitbox_il);
    SAFE_RELEASE(hitbox_vb);
    SAFE_RELEASE(hitbox_ib);
    SAFE_RELEASE(hitbox_sb);
    SAFE_RELEASE(hitbox_sb_srv);
    SAFE_RELEASE(hitbox_cb);
}
#undef SAFE_RELEASE

static std::vector<DrawObj> overlay_collision;
static std::vector<DrawObj> overlay_hurt;
static std::vector<DrawObj> overlay_hit;

static forceinline void transform_vec2(float* dst, const float* src, const D3DMATRIX* mat) {
    dst[0] = mat->m[0][0] * src[0] + mat->m[1][0] * src[1] + mat->m[3][0];
    dst[1] = mat->m[0][1] * src[0] + mat->m[1][1] * src[1] + mat->m[3][1];
}

/*
static forceinline void transform_vec4(float* dst, const float* src, const D3DMATRIX* mat) {
    dst[0] = mat->m[0][0] * src[0] + mat->m[1][0] * src[1] + mat->m[3][0];
    dst[1] = mat->m[0][1] * src[0] + mat->m[1][1] * src[1] + mat->m[3][1];
    dst[2] = mat->m[0][0] * src[2] + mat->m[1][0] * src[3] + mat->m[3][0];
    dst[3] = mat->m[0][1] * src[2] + mat->m[1][1] * src[3] + mat->m[3][1];
}
*/

static forceinline vec<float, 4> transform_vec4(vec<float, 4> src, vec<float, 4> m0, vec<float, 4> m1, vec<float, 4> m3) {
    vec<float, 4> src_even = shufflevec(src, src, 0, 0, 2, 2);
    vec<float, 4> src_odd = shufflevec(src, src, 1, 1, 3, 3);

    return m0 * src_even + m1 * src_odd + m3;
}

static forceinline void transform_vec2(float* dst, float x, float y, const btTransform* mat) {
    dst[0] = mat->basis.m[0].v[0] * x + mat->basis.m[0].v[1] * y + mat->origin.v[0];
    dst[1] = mat->basis.m[1].v[0] * x + mat->basis.m[1].v[1] * y + mat->origin.v[1];
}

/*
static forceinline void transform_vec4(float* dst, float x, float y, const btTransform* mat) {
    dst[0] = mat->basis.m[0].v[0] * x + mat->basis.m[0].v[1] * y + mat->origin.v[0];
    dst[1] = mat->basis.m[1].v[0] * x + mat->basis.m[1].v[1] * y + mat->origin.v[1];
    dst[2] = mat->basis.m[0].v[0] * -x + mat->basis.m[0].v[1] * y + mat->origin.v[0];
    dst[3] = mat->basis.m[1].v[0] * -x + mat->basis.m[1].v[1] * y + mat->origin.v[1];
}
*/

static forceinline vec<float, 4> transform_vec4(vec<float, 4> basisX, vec<float, 4> basisY, vec<float, 4> origin) {
    return basisX + basisY + origin;
}

static void get_boxes(std::vector<DrawObj>& dst, const std::vector<std::shared_ptr<ManbowActorCollisionData>>& src, const ManbowCamera2D* camera) {
    union {
        btVector3 rect_extents;
        btVector3 aabb[2];
    };

    size_t prev_size = dst.size();
    dst.resize(prev_size + src.size());
    DrawObj* draw_ptr = &dst[prev_size];

    vec<float, 4> view_proj0 = shufflevec(camera->view_proj_matrix.m[0], camera->view_proj_matrix.m[0], 0, 1, 0, 1);
    vec<float, 4> view_proj1 = shufflevec(camera->view_proj_matrix.m[1], camera->view_proj_matrix.m[1], 0, 1, 0, 1);
    vec<float, 4> view_proj3 = shufflevec(camera->view_proj_matrix.m[3], camera->view_proj_matrix.m[3], 0, 1, 0, 1);

    for (const auto& data : src) {
        btGhostObject* obj = data->obj_ptr;

        draw_ptr->group = obj->m_broadphaseProxy ? obj->m_broadphaseProxy->m_collisionFilterGroup : 0;

        switch (obj->m_collisionShape->shape) {
            case 17: {
                btBox2dShape_getHalfExtentsWithMargin(obj->m_collisionShape, &rect_extents);
                draw_ptr->prim = DRAW_RECT;
                //draw.prim = DRAW_RECT;

                // The vertices get transformed on the CPU to calculate the border thresholds later
                // TODO: It might be faster to multiply the two matrices together and use that instead
                
                /*
                float world_points[4];
                transform_vec2(&world_points[0], -rect_extents.v[0], -rect_extents.v[1], &obj->m_worldTransform);
                transform_vec2(&world_points[2], rect_extents.v[0], -rect_extents.v[1], &obj->m_worldTransform);
                transform_vec2(&draw.rect.points[0], &world_points[0], &camera->view_proj_matrix);
                transform_vec2(&draw.rect.points[2], &world_points[2], &camera->view_proj_matrix);
                transform_vec2(&world_points[0], rect_extents.v[0], rect_extents.v[1], &obj->m_worldTransform);
                transform_vec2(&world_points[2], -rect_extents.v[0], rect_extents.v[1], &obj->m_worldTransform);
                transform_vec2(&draw.rect.points[4], &world_points[0], &camera->view_proj_matrix);
                transform_vec2(&draw.rect.points[6], &world_points[2], &camera->view_proj_matrix);
                */

                /*
                float world_points[4];
                transform_vec4(&world_points[0], -rect_extents.v[0], -rect_extents.v[1], &obj->m_worldTransform);
                transform_vec4(&draw.rect.points[0], &world_points[0], &camera->view_proj_matrix);
                transform_vec4(&world_points[0], rect_extents.v[0], rect_extents.v[1], &obj->m_worldTransform);
                transform_vec4(&draw.rect.points[4], &world_points[0], &camera->view_proj_matrix);
                */
                
                vec<float, 4> world_origin = shufflevec(obj->m_worldTransform.origin.v, obj->m_worldTransform.origin.v, 0, 1, 0, 1);
                vec<float, 4> world_basisX = shufflevec(obj->m_worldTransform.basis.m[0].v, obj->m_worldTransform.basis.m[1].v, 0, 4, 0, 4);
                vec<float, 4> world_basisY = shufflevec(obj->m_worldTransform.basis.m[0].v, obj->m_worldTransform.basis.m[1].v, 1, 5, 1, 5);
                vec<float, 4> extentsX = { -rect_extents.v[0], -rect_extents.v[0], rect_extents.v[0], rect_extents.v[0] };
                vec<float, 4> extentsY = { rect_extents.v[1], rect_extents.v[1], rect_extents.v[1], rect_extents.v[1] };

                vec<float, 4> world_points[2];
                world_points[0] = transform_vec4(world_basisX * extentsX, world_basisY * -extentsY, world_origin);
                world_points[1] = transform_vec4(world_basisX * -extentsX, world_basisY * extentsY, world_origin);

                draw_ptr->rect.points_vec[0] = transform_vec4(world_points[0], view_proj0, view_proj1, view_proj3);
                draw_ptr->rect.points_vec[1] = transform_vec4(world_points[1], view_proj0, view_proj1, view_proj3);
                break;
            }
            case 8: {
                obj->m_collisionShape->getAabb(&obj->m_worldTransform, &aabb[0], &aabb[1]);
                draw_ptr->prim = DRAW_CIRCLE;
                //transform_vec2(&draw.circle.aabb[0], (float*)&aabb[0].v, &camera->view_proj_matrix);
                //transform_vec2(&draw.circle.aabb[2], (float*)&aabb[1].v, &camera->view_proj_matrix);
                vec<float, 4> aabb_vec = { aabb[0].v[0], aabb[0].v[1], aabb[1].v[0], aabb[1].v[1] };
                draw_ptr->circle.aabb_vec = transform_vec4(aabb_vec, view_proj0, view_proj1, view_proj3);
                break;
            }
            default:
                log_printf("Unhandled hitbox shape %u\n", obj->m_collisionShape->shape);
                break;
        }
        ++draw_ptr;
    }
}

static size_t hitbox_write_idx = 0;
static HitboxVertex* hitbox_vertices = nullptr;
static HitboxGPUData* hitbox_gpu_data = nullptr;
static int hitbox_player_flags[2] = {};
void overlay_set_hitboxes(ManbowActor2DGroup* group, int p1_flags, int p2_flags) {
    overlay_clear();
    if (!get_hitbox_vis_enabled()) {
        return;
    }

    ManbowCamera2D* camera = group->camera;
    hitbox_player_flags[0] = p1_flags;
    hitbox_player_flags[1] = p2_flags;

    if (uint32_t group_size = group->size) {
        ManbowActor2D** actor_ptr = group->actor_vec.data();
        do {
            ManbowActor2D* actor = *actor_ptr++;
            if (!actor->anim_controller || (actor->active_flags & 1) == 0 || (actor->group_flags & group->update_mask) == 0 || !actor->callback_group)
                continue;

            get_boxes(overlay_collision, actor->anim_controller->collision_boxes, camera);
            get_boxes(overlay_hurt, actor->anim_controller->hurt_boxes, camera);
            get_boxes(overlay_hit, actor->anim_controller->hit_boxes, camera);

        } while (--group_size);

    }
}

int GetFrameCount(ManbowActor2D* player) {
    if (!player || !player->anim_controller->anim_set)
        return 0;
    auto cont = player->anim_controller;
    log_printf(
        "%d\n",
        cont->take->frame_total
    );
    return 0;
}

bool hasData(ManbowActor2DGroup* group) {
    if (uint32_t group_size = group->size) {
        ManbowActor2D** actor_ptr = group->actor_vec.data();
        do {
            ManbowActor2D* actor = *actor_ptr++;
            if (!actor->anim_controller || (actor->active_flags & 1) == 0 || (actor->group_flags & group->update_mask) == 0 || !actor->callback_group)
                continue;

            for (const auto& data : actor->anim_controller->hit_boxes) {
                if (data->obj_ptr->m_collisionShape->shape != 0) {
                    return true;
                }
            }
            for (const auto& data : actor->anim_controller->hurt_boxes) {
                if (data->obj_ptr->m_collisionShape->shape != 0) {
                    return true;
                }
            }
            // for (const auto& data : actor->anim_controller->collision_boxes) {
            //     if (data->obj_ptr->m_collisionShape->shape != 0) {
            //         return true;
            //     }
            // }
        } while (--group_size);
    }
    return false;
}

bool IsFrameActive(ManbowActor2DGroup* group) {
    if (uint32_t group_size = group->size) {
        ManbowActor2D** actor_ptr = group->actor_vec.data();
        do {
            ManbowActor2D* actor = *actor_ptr++;
            if (!actor->anim_controller || (actor->active_flags & 1) == 0 || (actor->group_flags & group->update_mask) == 0 || !actor->callback_group)
                continue;

            for (const auto& data : actor->anim_controller->hit_boxes) {
                if (data->obj_ptr->m_collisionShape->shape != 0) {
                    return true;
                }
            }
        } while (--group_size);
    }
    return false;
}

int IsFrameActive(ManbowActor2DGroup* group,ManbowActor2D* actor1,ManbowActor2D* actor2) {
    int8_t flag = 0;
    if (uint32_t group_size = group->size) {
        ManbowActor2D** actor_ptr = group->actor_vec.data();
        do {
            ManbowActor2D* actor = *actor_ptr++;
            if (!actor->anim_controller || (actor->active_flags & 1) == 0 || (actor->group_flags & group->update_mask) == 0 || !actor->callback_group)
                continue;
            for (const auto& data : actor->anim_controller->hit_boxes) {
                if (data->obj_ptr->m_collisionShape->shape != 0) {

                    if(actor->id == actor1->id || actor->id == actor2->id)flag |= 1;
                    else flag |= 2;
                }
            }
        } while (--group_size);
    }
    return flag;
}

std::vector<SQObject> GetHitboxes(ManbowActor2DGroup* group) {
    std::vector<SQObject> boxes = {};
    if (uint32_t group_size = group->size) {
        ManbowActor2D** actor_ptr = group->actor_vec.data();
        do {
            ManbowActor2D* actor = *actor_ptr++;
            if (!actor->anim_controller || (actor->active_flags & 1) == 0 || (actor->group_flags & group->update_mask) == 0 || !actor->callback_group)
                continue;
            for (const auto &data : actor->anim_controller->hurt_boxes) {
                boxes.push_back(actor->sq_obj);
            }
            for (const auto& data : actor->anim_controller->hit_boxes) {
                boxes.push_back(actor->sq_obj);
            }
        } while (--group_size);
    }
    return boxes;
}

// int FrameDataCheck(ManbowActor2DGroup* group,ManbowActor2D* target,ManbowActor2D* p1,ManbowActor2D* p2) {
//     auto result = 0;
//     if (uint32_t group_size = group->size) {
//         ManbowActor2D** actor_ptr = group->actor_vec.data();
//         do {
//             ManbowActor2D* actor = *actor_ptr++;
//             if (!actor->anim_controller || 
//             (actor->active_flags & 1) == 0 || 
//             (actor->group_flags & group->update_mask) == 0 || 
//             !actor->callback_group ||
//             (actor->id != p1->id && actor->id != p2->id) ||
//             actor->id != target->id)
//                 continue;

//             for (const auto& data : actor->anim_controller->hit_boxes) {
//                 if (data->obj_ptr->m_collisionShape->shape != 0) {
//                     return true;
//                 }
//             }
//         } while (--group_size);
//     }
//     return result;
// }

static forceinline void clip_to_screen(float* dst, const float* src) {
    dst[0] = (1.0f + src[0]) * (1280.0f / 2.0f);
    dst[1] = (1.0f - src[1]) * (720.0f / 2.0f);
}

static forceinline vec<float, 4> clip_to_screen(vec<float, 4> src) {
    vec<float, 4> one = { 1.0f, 1.0f, 1.0f, 1.0f };
    vec<float, 4> src_signed = { src[0], -src[1], src[2], -src[3] };
    vec<float, 4> mult = { 1280.0f / 2.0f, 720.0f / 2.0f, 1280.0f / 2.0f, 720.0f / 2.0f };
    return (one + src_signed) * mult;
}

static forceinline float vec2_distance(const float* p0, const float* p1) {
    float x = p0[0] - p1[0];
    float y = p0[1] - p1[1];
    return sqrtf(x * x + y * y);
}

static forceinline float vec4_distance(vec<float, 4> p) {
    float x = p[0] - p[2];
    float y = p[1] - p[3];
    return sqrtf(x * x + y * y);
}

static float hitbox_border_width = 0.0f;
static void draw_rect(uint32_t col, size_t index, const vec<float, 4>* points) {

    vec<float, 4> points_low = points[0];
    vec<float, 4> points_high = points[1];
    *(vec<float, 4>*)&hitbox_vertices[index * 4] = points_low;
    *(vec<float, 4>*)&hitbox_vertices[index * 4 + 2] = points_high;

    points_low = clip_to_screen(points_low);
    points_high = clip_to_screen(points_high);

    float width = vec4_distance(points_low);
    float height = vec4_distance(shufflevec(points_low, points_high, 0, 1, 6, 7));
    hitbox_gpu_data[index].thresholds[0] = 1.0f - hitbox_border_width / width;
    hitbox_gpu_data[index].thresholds[1] = 1.0f - hitbox_border_width / height;
    hitbox_gpu_data[index].col = col;
    hitbox_gpu_data[index].flags = 0;
}

static void draw_circle(uint32_t col, size_t index, vec<float, 4> aabb) {
    vec<float, 4> low_pos = shufflevec(aabb, aabb, 0, 1, 2, 1);
    *(vec<float, 4>*)&hitbox_vertices[index * 4] = low_pos;
    *(vec<float, 4>*)&hitbox_vertices[index * 4 + 2] = shufflevec(aabb, aabb, 2, 3, 0, 3);

    float threshold = 1.0f - hitbox_border_width / vec4_distance(clip_to_screen(low_pos));
    hitbox_gpu_data[index].thresholds[0] = threshold * threshold;
    hitbox_gpu_data[index].col = col;
    hitbox_gpu_data[index].flags = 1;
}

template <typename F> requires(std::is_invocable_v<F, const DrawObj&>)
static void draw_objs(const std::vector<DrawObj>& vec, F&& col_func) {
    size_t index = hitbox_write_idx;
    if (index != MAX_HITBOXES) {
        for (const auto& obj : vec) {
            uint32_t col = col_func(obj);

            switch (obj.prim) {
                case DRAW_RECT:
                    draw_rect(col, index, obj.rect.points_vec);
                    break;
                case DRAW_CIRCLE:
                    draw_circle(col, index, obj.circle.aabb_vec);
                    break;
            }

            if (++index == MAX_HITBOXES) {
                break;
            }
        }
        hitbox_write_idx = index;
    }
}

static void draw_objs(const std::vector<DrawObj>& vec, uint32_t col) {
    [[clang::always_inline]]
    draw_objs(vec, [=](const DrawObj&) -> uint32_t {
        return col;
    });
}

void overlay_clear() {
    overlay_collision.clear();
    overlay_hurt.clear();
    overlay_hit.clear();
}

static HitboxConstantBuffer hitbox_last_cb = {};
void overlay_draw() {
    if (!overlay_supported)
        return;

    bool has_collision = !overlay_collision.empty();
    bool has_hurt = !overlay_hurt.empty();
    bool has_hit = !overlay_hit.empty();
    if (!has_collision && !has_hurt && !has_hurt)
        return;

    hitbox_border_width = get_hitbox_border_width() * 2.0f;

    // Try not to read config entries if we don't have to
    uint32_t collision_col = has_collision ? get_hitbox_collision_color() : 0;
    uint32_t hit_col = has_hit ? get_hitbox_hit_color() : 0;
    uint32_t player_hurt_col = has_hurt ? get_hitbox_player_hurt_color() : 0;
    uint32_t player_unhit_col = has_hurt ? get_hitbox_player_unhit_color() : 0;
    uint32_t player_ungrab_col = has_hurt ? get_hitbox_player_ungrab_color() : 0;
    uint32_t player_unhit_ungrab_col = has_hurt ? get_hitbox_player_unhit_ungrab_color() : 0;
    uint32_t misc_hurt_col = has_hurt ? get_hitbox_misc_hurt_color() : 0;

    ID3D11DeviceContext* imm = *d3d11_imm;

    D3D11_MAPPED_SUBRESOURCE resource;
    HitboxConstantBuffer new_cb = {
        .alphas = {get_hitbox_inner_alpha(), get_hitbox_border_alpha()}
    };
    if (memcmp(&new_cb, &hitbox_last_cb, sizeof(HitboxConstantBuffer))) {
        hitbox_last_cb = new_cb;

        imm->Map(hitbox_cb, 0, D3D11_MAP_WRITE_DISCARD, 0, &resource);
        memcpy(resource.pData, &new_cb, sizeof(HitboxConstantBuffer));
        imm->Unmap(hitbox_cb, 0);
    }

    imm->Map(hitbox_vb, 0, D3D11_MAP_WRITE_DISCARD, 0, &resource);
    hitbox_vertices = (HitboxVertex*)resource.pData;
    imm->Map(hitbox_sb, 0, D3D11_MAP_WRITE_DISCARD, 0, &resource);
    hitbox_gpu_data = (HitboxGPUData*)resource.pData;
    hitbox_write_idx = 0;

    draw_objs(overlay_collision, collision_col);
    draw_objs(overlay_hurt, [=](const DrawObj& obj) -> uint32_t {
        if (obj.group & 3) {
            int flags = hitbox_player_flags[(obj.group & 2) != 0] & 5;
            switch (flags) {
                case 5:
                    return player_hurt_col;
                case 4:
                    return player_unhit_col;
                case 1:
                    return player_ungrab_col;
                case 0:
                    return player_unhit_ungrab_col;
                default:
                    unreachable;
            }
        } else {
            return misc_hurt_col;
        }
    });
    draw_objs(overlay_hit, hit_col);

    imm->Unmap(hitbox_vb, 0);
    imm->Unmap(hitbox_sb, 0);

    ID3D11InputLayout* orig_il;
    D3D_PRIMITIVE_TOPOLOGY orig_topology;
    ID3D11VertexShader* orig_vs;
    ID3D11PixelShader* orig_ps;
    imm->IAGetInputLayout(&orig_il);
    imm->IAGetPrimitiveTopology(&orig_topology);
    imm->VSGetShader(&orig_vs, nullptr, 0);
    imm->PSGetShader(&orig_ps, nullptr, 0);

    static constexpr UINT stride = sizeof(HitboxVertex);
    static constexpr UINT offset = 0;
    imm->IASetInputLayout(hitbox_il);
    imm->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    imm->IASetVertexBuffers(0, 1, &hitbox_vb, &stride, &offset);
    imm->IASetIndexBuffer(hitbox_ib, DXGI_FORMAT_R16_UINT, 0);
    imm->VSSetShader(hitbox_vs, nullptr, 0);
    imm->VSSetShaderResources(0, 1, &hitbox_sb_srv);
    imm->PSSetShader(hitbox_ps, nullptr, 0);
    imm->PSSetConstantBuffers(0, 1, &hitbox_cb);

    imm->DrawIndexed(hitbox_write_idx * 6, 0, 0);

    static constexpr ID3D11ShaderResourceView* null_srv = nullptr;
    static constexpr ID3D11Buffer* null_buf = nullptr;
    imm->IASetInputLayout(orig_il);
    imm->IASetPrimitiveTopology(orig_topology);
    imm->IASetVertexBuffers(0, 1, &null_buf, &stride, &offset);
    imm->IASetIndexBuffer(null_buf, DXGI_FORMAT_R16_UINT, 0);
    imm->VSSetShader(orig_vs, nullptr, 0);
    imm->VSSetShaderResources(0, 1, &null_srv);
    imm->PSSetShader(orig_ps, nullptr, 0);
    imm->PSSetConstantBuffers(0, 1, &null_buf);
}
