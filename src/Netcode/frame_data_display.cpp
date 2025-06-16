#if __INTELLISENSE__
#undef __HAS_CXX20
#define _HAS_CXX20 0
#endif

#include "TF4.h"

int GetFrameCount(ManbowActor2D* player){
    if (!player || !player->anim_controller->anim_set)return 0;
    std::shared_ptr<ManbowAnimationController2D> cont = player->anim_controller;
    TakeData* take = cont->take;
    while(take->previous)take = take->previous;
    int32_t total = take->frame_total;
    while(take->next){
        take = take->next;
        total += take->frame_total;
    }
    return total / 100;
}

bool hasData(ManbowActor2DGroup* group) {
    if (uint32_t group_size = group->size) {
        ManbowActor2D** actor_ptr = group->actor_vec.data();
        do {
            ManbowActor2D* actor = *actor_ptr++;
            if (!actor->anim_controller || (actor->active_flags & 1) == 0 || (actor->group_flags & group->update_mask) == 0 || !actor->callback_group)
                continue;

            for (const auto& data : actor->anim_controller->hit_boxes) {
                if (data->obj_ptr->m_collisionShape->shape != 0) {
                    return true;
                }
            }
            for (const auto& data : actor->anim_controller->hurt_boxes) {
                if (data->obj_ptr->m_collisionShape->shape != 0) {
                    return true;
                }
            }
        } while (--group_size);
    }
    return false;
}

// bool IsFrameActive(ManbowActor2DGroup* group) {
//     if (uint32_t group_size = group->size) {
//         ManbowActor2D** actor_ptr = group->actor_vec.data();
//         do {
//             ManbowActor2D* actor = *actor_ptr++;
//             if (!actor->anim_controller || (actor->active_flags & 1) == 0 || (actor->group_flags & group->update_mask) == 0 || !actor->callback_group)
//                 continue;

//             for (const auto& data : actor->anim_controller->hit_boxes) {
//                 if (data->obj_ptr->m_collisionShape->shape != 0) {
//                     return true;
//                 }
//             }
//         } while (--group_size);
//     }
//     return false;
// }

int IsFrameActive(ManbowActor2DGroup* group,ManbowActor2D* actor1,ManbowActor2D* actor2) {
    int8_t flag = 0;
    if (uint32_t group_size = group->size) {
        ManbowActor2D** actor_ptr = group->actor_vec.data();
        do {
            ManbowActor2D* actor = *actor_ptr++;
            if (!actor->anim_controller || (actor->active_flags & 1) == 0 || (actor->group_flags & group->update_mask) == 0 || !actor->callback_group)
                continue;
            for (const auto& data : actor->anim_controller->hit_boxes) {
                if (data->obj_ptr->m_collisionShape->shape != 0) {

                    if(actor->id == actor1->id || actor->id == actor2->id)flag |= 1;
                    else flag |= 2;
                }
            }
        } while (--group_size);
    }
    return flag;
}
