#pragma once
#include <cstddef>
#include <memory>
#ifndef ROLLBACK_H
#define ROLLBACK_H

#include <functional>
#include <squirrel.h>
#include <string_view>
#include <unordered_map>
#include <vector>
#include <string.h>

#include "TF4.h"
#include "kite_api.h"
#include "log.h"

static const char* SQPaths[] = {
    "team.op_stop",
    "team.op_stop_max",
    "team.combo_count",
    "team.combo_damage",
    "team.damage_scale",
    "team.combo_stun",
    "team.life",
    "team.damage_life",
    // "x",
    // "y",
    // "vx",
    // "vy",
    // "direction"
};

struct SQDiff {
    const char* path;
    SQObject new_val;

    SQDiff(const char* path, SQObject new_val) : path(path),new_val(new_val){}
};

struct data_diff {
    ManbowActor2D* actor;
    std::vector<SQDiff> SQChanges;
    float pos[3];
    float vx;
    float vy;
    float direction;
    TakeData take;
    int32_t motion;
    int32_t key_take;

    data_diff(ManbowActor2D* actor){
        this->actor = actor;
        this->pos[0] = actor->pos[0];
        this->pos[1] = actor->pos[1];
        this->pos[2] = actor->pos[2];

        // this->vx = actor->vx;
        // this->vy = actor->vy;

        // ManbowActor2D _actor = *actor;
        // ManbowAnimationController2D &cont = *_actor.anim_controller;
        // TakeData &data = *cont.take;
        TakeData data = *actor->anim_controller->take;
        this->take = data; // crash here
        this->key_take = actor->anim_controller->key_take;
        this->motion = actor->anim_controller->motion;
    }
};

struct frame_diff {
    frame_diff* next;
    frame_diff* prev;
    std::vector<data_diff> changes;

    frame_diff(frame_diff* previous) {
        this->prev = previous;
    }

    ~frame_diff() {
        delete this->next;
    }

    void Apply(HSQUIRRELVM v) {
        if(!this->changes.size())return;
        for (auto change : this->changes){
            if (!change.actor){
                continue;
            }
            for (auto diff : change.SQChanges){
                this->sq_setval(v, change.actor->sq_obj, diff.path, diff.new_val);
            }
            auto actor2d = change.actor;

            // log_printf("set:[%f,%f,%f]\n", change.pos[0], change.pos[1],change.pos[2]);
            // actor2d->pos[0] = change.pos[0];
            // actor2d->pos[1] = change.pos[1];
            // actor2d->pos[2] = change.pos[2];

            // actor2d->vx = change.vx;
            // actor2d->vy = change.vy;
            actor2d->direction = change.direction;

            actor2d->anim_controller->SetMotion(change.motion,change.key_take);
            // log_printf("%d\n",change.take->frame_total);
            // actor2d->anim_controller->take = &change.take;
            // actor2d->anim_controller->SetTake(change.key_take);
        }
    }

    private:

    bool sq_path(HSQUIRRELVM v, const SQObject &root, const char* path, SQObject &out) {
        sq_pushobject(v, root);
    
        const char* p = path;
        const char* dot;
    
        while ((dot = strchr(p, '.')) != NULL) {
            sq_pushstring(v, p, (SQInteger)(dot - p));
            if (SQ_FAILED(sq_get(v, -2))) {
                sq_pop(v, 2);
                return false;
            }
    
            sq_remove(v, -2);
    
            p = dot + 1;
        }
    
        sq_pushstring(v, p, -1);
        if (SQ_FAILED(sq_get(v, -2))) {
            sq_pop(v, 2);
            return false;
        }
    
        sq_getstackobj(v, -1, &out);
    
        sq_pop(v, 1);
        return true;
    }

    void sq_setval(HSQUIRRELVM v,SQObject root, const char* path,SQObject &val) {
        SQObject obj;
        if (sq_path(v, root, path, obj)) {
            if (obj._type >= OT_STRING && obj._type <= OT_GENERATOR)sq_release(v, &obj);
            sq_pushobject(v, val);
            sq_getstackobj(v, -1, &obj);
            sq_pop(v, 1);    
        }
    }
};

struct diffMan {
    frame_diff* current;
    ManbowActor2DGroup* group;
    HSQUIRRELVM v;

    // diffMan(HSQUIRRELVM _v, ManbowActor2DGroup* _group) {
    //     v = _v;
    //     group = _group;
    // }

    ~diffMan(){
        delete current;
    }

    public:

    //this is for a more static single manager only approach
    //i'm still not sure whether to take that or not
    bool Init(HSQUIRRELVM v, ManbowActor2DGroup* _group) {
        if (current)delete this->current;
        this->v = v;
        this->group = _group;
        return true;
    }

    bool Tick() {
        if(!this->group)return false;
        if (size_t group_size = group->size) {
            if(this->current){
                this->current->next = new frame_diff(this->current);
                this->current = this->current->next;
            }else {
                this->current = new frame_diff(nullptr);
            }
            ManbowActor2D **actor_ptr = group->actor_vec.data();
            do {
              ManbowActor2D *actor = *actor_ptr++;
              this->Store(this->v, actor);
            } while (--group_size);
        }
        return true;
    }

    bool TickA(std::vector<ManbowActor2D*> actors) {
        if(this->current){
            this->current->next = new frame_diff(this->current);
            this->current = this->current->next;
        }else {
            this->current = new frame_diff(nullptr);
        }
        for(auto actor : actors){
            this->Store(v, actor);
        }
        return true;
    }

    bool Undo(size_t frames) {
        if(!this->current)return false;
        while(frames-- && this->current->prev)this->current = this->current->prev;
        this->current->Apply(v);
        return true;
    }

    private:

    bool sq_path(HSQUIRRELVM v, const SQObject &root, const char* path, SQObject &out) {
        sq_pushobject(v, root);
    
        const char* p = path;
        const char* dot;
    
        while ((dot = strchr(p, '.')) != NULL) {
            sq_pushstring(v, p, (SQInteger)(dot - p));
            if (SQ_FAILED(sq_get(v, -2))) {
                sq_pop(v, 2);
                return false;
            }
    
            sq_remove(v, -2);
    
            p = dot + 1;
        }
    
        sq_pushstring(v, p, -1);
        if (SQ_FAILED(sq_get(v, -2))) {
            sq_pop(v, 2);
            return false;
        }
    
        sq_getstackobj(v, -1, &out);
    
        sq_pop(v, 1);
        return true;
    }

    void Store(HSQUIRRELVM v,ManbowActor2D* actor) {
        if(!actor)return;
        this->current->changes.emplace_back(data_diff(actor));//crash here
        auto current = this->current->changes.back();
        SQObject sqobj = actor->sq_obj;
        for (auto path : SQPaths) {
          SQObject out;
          if (sq_path(v, sqobj, path, out))current.SQChanges.emplace_back(SQDiff(path, out));
        }
    }
};

void Reset(HSQUIRRELVM v,ManbowActor2DGroup* group);
void Tick();
void TickA(std::vector<ManbowActor2D*> actors);
void Undo(size_t frames);
void Clear();

#endif