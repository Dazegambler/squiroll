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
    "team.damage_life"
};

struct SQDiff {
    const char* path;
    SQObject new_val;

    SQDiff(const char* path, SQObject new_val) : path(path),new_val(new_val){}
};

struct data_diff {
    data_diff* next;
    ManbowActor2D* actor;
    std::vector<SQDiff*> SQChanges;
    float pos[3];
    float vx;
    float vy;
    float direction;
    TakeData* take;
    int32_t key_take;

    data_diff(ManbowActor2D* actor) : actor(actor){}
    ~data_diff(){
        while (this->next){
            auto temp = this;
            *this = *this->next;
            delete temp;
        }
    }
};

struct frame_diff {
    frame_diff* next;
    frame_diff* prev;
    data_diff* change;

    frame_diff() {
        this->prev = this;
    }

    frame_diff(frame_diff* previous) {
        this->prev = previous;
    }

    ~frame_diff() {
        delete this->change;
        while (this->prev != this)*this = this->prev;
        while (this->next){
            auto temp = this;
            *this = this->next;
            delete temp;
        }
    }

    void Apply(HSQUIRRELVM v) {
        if(!this->change)return;
        while(this->change->next){
            auto change = this->change;
            if (!change->actor){
                delete change;
                continue;
            }
            for (auto diff : change->SQChanges){
                this->sq_setval(v, change->actor->sq_obj, diff->path, diff->new_val);
            }
            auto actor2d = change->actor;

            actor2d->pos[0] = change->pos[0];
            actor2d->pos[1] = change->pos[1];
            actor2d->pos[2] = change->pos[2];

            actor2d->vx = change->vx;
            actor2d->vy = change->vy;
            actor2d->direction = change->direction;

            std::shared_ptr<ManbowAnimationController2D> cont = actor2d->anim_controller;
            cont->take = change->take;
            cont->vftable->SetTake(cont.get(),change->key_take);

            delete change;
            this->change = this->change->next;
        }
    }

    inline void AddSQChange(ManbowActor2D* actor) {
        if(!this->change){
            log_printf("4.1\n");
            this->change = new data_diff(actor);
        }else {
            log_printf("4.2\n");
            this->change->next = new data_diff(actor); // here
            log_printf("4.3\n");
            this->change = this->change->next;
            log_printf("4.4\n");
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

    diffMan(HSQUIRRELVM _v, ManbowActor2DGroup* _group) {
        v = _v;
        group = _group;
    }

    ~diffMan(){
        delete current;
    }

    public:

    //this is for a more static single manager only approach
    //i'm still not sure whether to take that or not
    // bool Init(ManbowActor2DGroup* _group) {
    //     if(this->current) {
    //         if(this->current->prev != this->current)this->Clear();
    //         else {
    //             delete this->current;
    //         }   
    //     }    
    //     this->group = _group;
    //     return true;
    // }

    bool Tick() {
        if(!this->group)return false;
        if (size_t group_size = group->size) {
            log_printf("1\n");
            if(this->current){
                this->current->next = new frame_diff(this->current);
                this->current = this->current->next;
            }else {
                this->current = new frame_diff();
            }
            log_printf("2\n");
            ManbowActor2D **actor_ptr = group->actor_vec.data();
            log_printf("3\n");
            do {
              ManbowActor2D *actor = *actor_ptr++;
              this->Store(this->v, actor);
            } while (--group_size);
        }
        return true;
    }

    bool Undo(size_t frames) {
        if(!this->current)return false;
        while(--frames)this->current = this->current->prev;
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
        log_printf("4\n");
        this->current->AddSQChange(actor);
        log_printf("5\n");
        SQObject sqobj = actor->sq_obj;
        log_printf("6\n");
        for (auto path : SQPaths) {
          SQObject out;
          if (sq_path(v, sqobj, path, out))
            this->current->change->SQChanges.push_back(new SQDiff(path, out));
        }
    }
};

void Reset(HSQUIRRELVM v,ManbowActor2DGroup* group);
void Tick();
void Undo(size_t frames);
void Clear();

#endif