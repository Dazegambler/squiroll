#pragma once
#include <squirrel.h>
#ifndef ROLLBACK_H
#define ROLLBACK_H

#include <functional>
#include <vector>

#include "TF4.h"
#include "kite_api.h"

struct data_diff {
    data_diff* next;
    std::function<void()> apply;
    data_diff(std::function<void()> diff){
        this->apply = diff;
    }
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
        this->Clear();
    }

    inline void Apply() {
        if(!this->change)return;
        while(this->change->next){
            this->change->apply();
            this->change = change->next;
        }
    }

    inline void AddChange(std::function<void()> diff) {
        if(!this->change) {
            this->change = new data_diff(diff);
        }else {
            this->change->next = new data_diff(diff);
        }
    }

    private:

    inline void Clear() {
        while (this->change->next){
            data_diff* temp = this->change;
            this->change = this->change->next;
            delete temp;
        }   
    }
};

struct diffMan {
    frame_diff* current;
    ManbowActor2DGroup* group;

    diffMan(ManbowActor2DGroup* _group) {
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
                this->Store(actor);
            } while (--group_size);
        }
        return true;
    }

    bool Undo(size_t frames) {
        if(!this->current)return false;
        while(--frames)this->current = this->current->prev;
        this->current->Apply();
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

    bool Store(ManbowActor2D* actor) {
        return true;
    }
};

#endif