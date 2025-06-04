#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <squirrel.h>

#include "rollback.h"
#include "TF4.h"

diffMan* rollback_Manager;

void Reset(HSQUIRRELVM v,ManbowActor2DGroup* group) {
    if(rollback_Manager)delete rollback_Manager;
    rollback_Manager = new diffMan(v, group);
}

void Tick() {
    if(!rollback_Manager)return;
    rollback_Manager->Tick();
}

void Undo(size_t frames) {
    if(!rollback_Manager)return;
    rollback_Manager->Undo(frames);
}

void Clear() {
    if(rollback_Manager)delete rollback_Manager;
}