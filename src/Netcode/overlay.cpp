
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

#include "D3D.h"
#include "TF4.h"
#include "bt.h"
#include "sqrat.h"

static constexpr uint8_t hitbox_vert_cso[] = {
#include "shaders/hitbox_vert.cso.h"
};
static constexpr uint8_t hitbox_frag_cso[] = {
#include "shaders/hitbox_frag.cso.h"
};

#define MAX_HITBOXES 1024

#define d3d11_dev ((ID3D11Device**)0x4DAE9C_R)
#define d3d11_imm ((ID3D11DeviceContext**)0x4DAE98_R)
#define btBox2dShape_getHalfExtentsWithMargin ((btVector3* (*thiscall)(btCollisionShape*, btVector3*))0x1C0EB0_R)
//#define draw_rect ((void (vectorcall*)(const float*, float, float, float, float))0x39600_R)

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

int debug(ManbowActor2D* player) {
    if (!player || !player->anim_controller->anim_set)return 0;
    auto group = player->actor2d_group;
    log_printf("size:%d\n",group->actor_list.size());
    // std::shared_ptr<ManbowAnimationController2D> cont = player->anim_controller;
    // Unk1* anim_data = cont->animation_data;
    // AnimationSet2D* set =  cont->anim_set;
    // void** data1 = (void**)set;
    // log_printf("\n>>>>>>>>>>>>>>>>data1\n");
    // if (data1){
    //     void** ptr = data1;
    //     log_printf("{\n");
    //     for (size_t i = 0; i < 20; ++i){
    //         void** d = (ptr + i);
    //         log_printf("+0x%x = 0x%p\n",i*4,*d);
    //     }
    //     log_printf("}");
    // }
    // log_printf("data1<<<<<<<<<<<<<<<<<\n");
    return 0;
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
