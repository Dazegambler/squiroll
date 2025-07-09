#include <cstdint>
#if __INTELLISENSE__
#undef __HAS_CXX20
#define _HAS_CXX20 0
#endif

#include "TF4.h"

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
