#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <vector>
#include <squirrel.h>

#include "rollback.h"
#include "TF4.h"
#include "log.h"

static diffMan* rollback_Manager = new diffMan();

void Reset(HSQUIRRELVM v,ManbowActor2DGroup* group) {
    rollback_Manager->Init(v,group);
}

void Tick() {
    if(!rollback_Manager)return;
    rollback_Manager->Tick();
}

void TickA(std::vector<ManbowActor2D*> actors) {
    rollback_Manager->TickA(actors);
}

void Undo(size_t frames) {
    if(!rollback_Manager)return;
    rollback_Manager->Undo(frames);
}

void Clear() {
    delete rollback_Manager->current;
}