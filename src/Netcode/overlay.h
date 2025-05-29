#pragma once

#ifndef OVERLAY_H
#define OVERLAY_H 1

#include "TF4.h"

void overlay_init();
void overlay_destroy();

void overlay_set_hitboxes(ManbowActor2DGroup* group, int p1_flags, int p2_flags);
void overlay_clear();
void overlay_draw();
bool IsFrameActive(ManbowActor2DGroup *group);
int IsFrameActive(ManbowActor2DGroup* group,ManbowActor2D* actor1,ManbowActor2D* actor2);
std::vector<SQObject> GetHitboxes(ManbowActor2DGroup* group);
void Rollback(ManbowActor2DGroup* val, ManbowActor2DGroup* tgt);
bool hasData(ManbowActor2DGroup *group);
int GetFrameCount(ManbowActor2D *player);
int debug(ManbowActor2D* player);

#endif
