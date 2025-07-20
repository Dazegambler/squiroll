#include <cstdint>
#if __INTELLISENSE__
#undef __HAS_CXX20
#define _HAS_CXX20 0
#endif

#include "TF4.h"
#include "log.h"

TakeData* data;

bool NewTake(ManbowActor2D* player) {
    TakeData* _data = player->anim_controller->take;
    while(_data->previous)_data = _data->previous;
    if (!data || data != _data){
        data = _data;
        return true;
    }
    return false;
}

int16_t* GetMetadata(ManbowActor2D* player) {
    int16_t* metadata = &player->anim_controller->animation_data->data[0];
    return metadata;
}

bool hasData(ManbowActor2D* actor) {
    AnimationData* anim_data = actor->anim_controller->animation_data;
    return anim_data->hit_count != anim_data->col_count;
}

bool IsFrameActive(ManbowActor2D* actor) {
    AnimationData* anim_data = actor->anim_controller->animation_data;
    return anim_data->hit_count != anim_data->hurt_count;
}
