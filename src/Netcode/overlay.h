#pragma once

#ifndef OVERLAY_H
#define OVERLAY_H 1

#include "TF4.h"

void overlay_init();
void overlay_destroy();

void overlay_set_hitboxes(ManbowActor2DGroup* group, int p1_flags, int p2_flags);
void overlay_clear();
void overlay_draw();
std::vector<SQObject> GetHitboxes(ManbowActor2DGroup* group);
int debug(ManbowActor2D* player);

#endif
