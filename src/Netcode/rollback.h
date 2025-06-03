#pragma once
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

static const char* SQPaths[] = {
    "team.op_stop",
    "team.op_stop_max",
    "team.combo_count",
    "team.combo_damage",
    "team.damage_scale",
    "team.combo_stun",
    "team.life",
    "team.damage_life",
    "x",
    "y",
    "z",
    "vx",
    "vy",
    "direction"
};

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

struct SQDiff {
    SQObject root;
    SQObject new_val;

    SQDiff(SQObject _root, SQObject _new_val) : root(_root),new_val(_new_val){}
};

struct data_diff {
    std::unordered_map<std::string_view,SQDiff*> SQChanges;
};

struct frame_diff {
    frame_diff* next;
    frame_diff* prev;
    data_diff* change;

    frame_diff() {
        *this->prev = *this;
    }

    frame_diff(frame_diff* previous) {
        this->prev = previous;
    }

    ~frame_diff() {
        delete this->change;
    }

    inline void Apply(HSQUIRRELVM v) {
        if(!this->change)return;
        for (auto path : SQPaths){
            SQDiff *diff = this->change->SQChanges.at(path);
            this->sq_setval(v,diff->root,path,diff->new_val);
        }
    }

    inline void AddSQChange(std::string_view path, SQObject root, SQObject val) {
        if(!this->change)this->change = new data_diff();
        this->change->SQChanges[path] = new SQDiff(root,val);
    }

    private:

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
        this->Clear();
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
            this->current->next = new frame_diff(this->current);
            this->current = this->current->next;
            ManbowActor2D** actor_ptr = group->actor_vec.data();
            do {
                ManbowActor2D* actor = *actor_ptr++;
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

    inline void Clear() {
        while (this->current->prev != this->current)this->current = this->current->prev;
        while (this->current->next){
            frame_diff* temp = this->current;
            this->current = this->current->next;
            delete temp;
        }    
    }

    void Store(HSQUIRRELVM v,ManbowActor2D* actor) {
        SQObject sqobj = actor->sq_obj;
        for (auto path : SQPaths){
            SQObject out;
            if(sq_path(v, sqobj,path,out))this->current->AddSQChange(path,sqobj,out);
        }
    }
};

#endif