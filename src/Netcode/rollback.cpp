#include "TF4.h"
#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include "rollback.h"

diffMan* rollback_Manager;

void Reset(ManbowActor2DGroup* group) {
    if(rollback_Manager)delete rollback_Manager;
    rollback_Manager = new diffMan(group);
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
bool get_slot_path(HSQUIRRELVM vm, const SQObject &root, const std::vector<const char*> &path, SQObject &out) {
    SQObject current = root;
    sq_addref(vm, &current);
    SQObject temp;
    for (size_t i = 0; i + 1 < path.size(); ++i) {
        sq_pushobject(vm, current);
        sq_pushstring(vm, path[i], -1);
        if (SQ_FAILED(sq_get(vm, -2))) {
            sq_pop(vm, 2);
            sq_release(vm, &current);
            return false;
        }
        sq_getstackobj(vm, -1, &temp);
        sq_addref(vm, &temp);
        sq_pop(vm, 2);
        sq_release(vm, &current);
        current = temp;
    }
    sq_pushobject(vm, current);
    sq_pushstring(vm, path.back(), -1);
    if (SQ_FAILED(sq_get(vm, -2))) {
        sq_pop(vm, 2);
        sq_release(vm, &current);
        return false;
    }
    sq_getstackobj(vm, -1, &out);
    sq_addref(vm, &out);
    sq_pop(vm, 2);
    sq_release(vm, &current);
    return true;
}

bool set_slot_path(HSQUIRRELVM vm, const SQObject &root, const std::vector<const char*> &path, const SQObject &val) {
    SQObject current = root;
    sq_addref(vm, &current);
    SQObject temp;
    for (size_t i = 0; i + 1 < path.size(); ++i) {
        sq_pushobject(vm, current);
        sq_pushstring(vm, path[i], -1);
        if (SQ_SUCCEEDED(sq_get(vm, -2))) {
            sq_getstackobj(vm, -1, &temp);
            sq_addref(vm, &temp);
            sq_pop(vm, 2);
            sq_release(vm, &current);
            current = temp;
        } else {
            sq_pop(vm, 2);
            sq_release(vm, &current);
            return false;
        }
    }
    bool ok;
    sq_pushobject(vm, current);
    sq_pushstring(vm, path.back(), -1);
    sq_pushobject(vm, val);
    ok = SQ_SUCCEEDED(sq_newslot(vm, -3, SQFalse));
    sq_pop(vm, 1);
    sq_release(vm, &current);
    return ok;
}
bool rollback(){
    return true;
}