#pragma once
#include "util.h"
#include <cstdint>
#ifndef TF4_H
#define TF4_H

#include <vector>
#include <list>
#include <memory>

#include "squirrel.h"
#include "bt.h"
#include "D3D.h"
#include "sqrat.h"

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

struct Sprite;

typedef void SpriteMethod8(
    const Sprite* self,
    uint32_t keyframe,
    int32_t frame
);

typedef void SpriteMethod10(
    const Sprite* self,
    float color_channel,
    bool some_bool
);

typedef void SpriteMethod14(
    const Sprite* self,
    void* ptr,
    int32_t frame
);

typedef void SpriteMethod18(
    const Sprite* self,
    D3DMATRIX matrix
);

struct SpriteVtable{
    void *const __method0; // 0x0
    void *const __method4; // 0x4
    SpriteMethod8 *const __method8; // 0x8
    void *const __methodC; // 0xC
    SpriteMethod10 *const __method10; // 0x10
    SpriteMethod14 *const __method14; // 0x14
    SpriteMethod18 *const __method18; // 0x18

};

struct Sprite {
    SpriteVtable* vtable; // 0x0
    void* __unk4; // 0x4
    void* __unkA4;
    void* __unkA8;
};

struct Unk18 {
    void* whatever;
};

// size: 0x60
struct BoxData {
    vec<float,4>    matrix[4]; // 0x0
    float           width; // 0x40   
    float           height; // 0x44
    float           length; // 0x48
    float           __float4c; // 0x4c
    int32_t         type; // 0x50
    char            __unk54[0xc]; // 0x54
    // 0x60
};

static_assert(sizeof(BoxData) == 0x60);

struct Point {
    int16_t x;
    int16_t y;
};

struct Unk0 {
    void*  vtable; // 0x0    
};

// size: 0x50
struct AnimationData {
    Unk0*           __arr0; // 0x0 unused?
    BoxData*        box_data; // 0x4
    Point*          points; // 0x8
    int32_t         frame_total; // 0xc
    uint32_t        flags[2]; // 0x10 0 state 1 attack
    /*
    0 : damage
    1 : hitStopE
    2 : hitstopP
    3 : guardStopE
    4 : guardStopP
    5 : firstRate
    6 : comboRate
    7 : AddKnock_Unk
    8 : stun
    9 : bariaBreak_Unk
    10 : guardRealDamage
    11 : slaveBlockOccult
    12 : gauge_onhit
    13 : comboRecoverTime
    14 : minRate_unused
    15 : stopVecX
    16 : stopVecY
    17 : hitSoundEffect
    18 : hitVecX
    19 : hitVecY
    20 : grazeKnock_Unk
    21 : atkType
    22 : atkRank
    23 : hitEffectVFX
    */
    int16_t        data[24]; // 0x18
    int8_t         col_count; // 0x48
    int8_t         hurt_count; // 0x49
    int8_t         hit_count; // 0x4a
    uint8_t         __int4b; // 0x4b unused?
    uint8_t         __int4c; // 0x4c
    uint8_t         __int4d; // 0x4d
    int16_t         __int4e; // 0x4e
    //0x50
};

static_assert(sizeof(AnimationData) == 0x50);

struct Unk140 {
    vec<float,4>    __mat0[4]; // 0x0
    vec<float,4>    __mat40[4]; // 0x40
    vec<float,4>    __mat80[4]; // 0x80
};

struct TakeData {
    void*           __unk0; // 0x0
    TakeData*       next; // 0x4
    TakeData*       previous; // 0x8
    AnimationData*  frame_data; // 0xc
    int32_t         frame_total; // 0x10 divide by 100 for true value
    std::vector<std::shared_ptr<Sprite>> sprites; // 0x14 prob sprites
    /*
    0 : attackLV
    1 : CancelLV
    */
    uint16_t        LVs[2]; // 0x20
    int8_t          __int24; // 0x24
    bool            __bool25; // 0x25
};

// struct IAnimationTake;

// struct Actor2DTakeData;

struct AnimationNode {
    AnimationNode*  __node0; // 0x0 
    AnimationNode*  start; // 0x4 it's as binary tree
    AnimationNode*  __node8; // 0x8
    char            __bytec; // 0xC
    bool            __boold; // 0xD
    char            __pad[0x2]; // 0xE
    int32_t         __int10; // 0x10
    TakeData*       take; // 0x14
};

struct AnimationSet2D {
    void*           vtbl; // 0x0
    void*           __unk4; // 0x4
    AnimationNode*  __unk8; // 0x8 <
    uint32_t        __intc; // 0xC
    void*           __unk10; // 0x10
    uint32_t        __int14; // 0x14
};

// for reference
// bool AnimationController2D::SetMotion(int32_t motion,int32_t take){
//     auto v1 = this->anim_set->__unk8;
//     bool v2 = v1->__unk4->__unkd;
//     auto v3 = v1; //most likely temp storage
//     auto v4 = v1->__unk4;
//     auto v5;
//     while (!v2) {
//         if (v4->__unk10 < motion){
//             v5 = v4->__unk8;
//             v4 = v3;
//         }else{
//             v5 = v4;
//         }
//         v3 = v4;
//         v4 = *v5;
//         v2 = v5->__unkd;
//     }
//     if (v3 == v1 || motion < v3->__unk10) {
//         v3 = v1;
//     } 
//     if (v3 != v1) {
//         this->motion = motion;
//         this->take = v3->__unk14;
//         return this->set_take(take);
//     }
//     return false;
// }

struct ManbowAnimationControllerBase;

typedef bool thiscall SetMotion(
    const ManbowAnimationControllerBase* self, 
    int32_t motion, 
    int32_t take
); 
typedef int thiscall SetTake(
    const ManbowAnimationControllerBase* self, 
    int32_t take
);

typedef bool thiscall PlayTake(
    const ManbowAnimationControllerBase* self, 
    int32_t keyframe
);

struct ManbowAnimationControllerBaseVftable {
    void *const __method0; // 0x0
    void *const __method4; // 0x4
    void *const __method8; // 0x8
    void *const __methodC; // 0xC
    void *const __method10; //0x10
    void *const __method14; // 0x14
    SetMotion *const SetMotion; // 0x18
    SetTake *const SetTake; // 0x1C
    PlayTake *const PlayTake; // 0x20
    void *const __method24; // 0x24
    void *const __method28; // 0x28
    void *const __method2C; // 0x2C
    void *const __method30; // 0x30
    void *const __method34; // 0x34
    void *const __method38; // 0x38
    void *const __method3C; // 0x3C
    void *const __method40; // 0x40
    void *const __method44; // 0x44
    void *const __method48; // 0x48
    void *const __method4C; // 0x4C
    void *const __method50; // 0x50
    void *const __method54; // 0x54
    void *const __method58; // 0x58
    void *const __method5C; // 0x5C
    void *const __method60; // 0x60
    void *const __method64; // 0x64
    void *const __method68; // 0x68
    void *const __method6C; // 0x6C
    void *const __method70; // 0x70
    void *const __method74; // 0x74
    void *const __method78; // 0x78
    void *const __method7C; // 0x7C
    void *const __method80; // 0x80
    void *const __method84; // 0x84
    void *const __method88; // 0x88
    void *const __method8C; // 0x8C
    void *const __method90; // 0x90
    void *const __method94; // 0x94
    void *const __method98; // 0x98
    void *const __method9C; // 0x9C
    void *const __methodA0; // 0xA0
    void *const __methodA4; // 0xA4
    void *const __methodA8; // 0xA8
    void *const __methodAC; // 0xAC
    void *const __methodB0; // 0xB0
    // 0xB0
};

// size: 0x120
struct ManbowAnimationControllerBase {
    ManbowAnimationControllerBaseVftable* vftable; // 0x0
    char __unk4[0x18]; // 0x4
    uint32_t motion; // 0x1c
    int32_t key_take; // 0x20
    uint32_t key_frame; // 0x24
    float red; // 0x28
    float green; // 0x2C
    float blue; // 0x30
    float alpha; // 0x34
    D3DMATRIX __matrix_38; // 0x38
    std::vector<std::shared_ptr<ManbowActorCollisionData>> collision_boxes; // 0x78
    std::vector<std::shared_ptr<ManbowActorCollisionData>> hit_boxes; // 0x84
    std::vector<std::shared_ptr<ManbowActorCollisionData>> hurt_boxes; // 0x90
    char __unk9C[0xC4 - 0x9C]; // 0x9C
    void*  __unkC4; // 0xc4
    char __unkC8[0x11C - 0xC8]; // 0xc8
    bool __bool11C; // 0x11c
    char __pad[3];
    // 0x120

    inline bool SetMotion(int32_t motion, int32_t take){
        return this->vftable->SetMotion(this,motion,take);
    }

    inline int SetTake(int32_t take){
        return this->vftable->SetTake(this,take);
    }
};

// size: 0x230
struct ManbowAnimationController2D : ManbowAnimationControllerBase {
    // ManbowAnimationControllerBase base; // 0x0
    void* tf4_imaterial_vftable; // 0x120 (this probably does nothing)
    AnimationSet2D* anim_set;// 0x124
    void* __unk128; // 0x128
    TakeData* take; // 0x12C
    AnimationData* animation_data; // 0x130
    int32_t frame; // 0x134 divide by 100 to get actual value
    int32_t frame_again; // 0x138
    uint16_t   speed; // 0x13C
    char    __byte13D; // 0x13D
    bool    __bool13E; // 0x13E
    char    __pad13F[2]; // 0x13F
    Unk140*   __unk140; // 0x140
    char    __unk144[0x224 - 0x148]; // 0x144
    std::vector<std::shared_ptr<Sprite>> sprites; // 0x224 most likely a vector of sprites
    // 0x230
};

static_assert(sizeof(ManbowAnimationController2D) == 0x230);

// size: 0x268
struct ManbowAnimationController3D : ManbowAnimationControllerBase {
    // ManbowAnimationControllerBase base; // 0x0
    char __unk120[0x138]; // 0x120
    float       __unk258; // 0x258
    float       __unk25C; // 0x25C
    float       __unk260; // 0x260
    float       __unk264; // 0x264
    // 0x268
};

static_assert(sizeof(ManbowAnimationController3D) == 0x268);

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
    float r[3]; // 0x5C, rotation in radians
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


#endif