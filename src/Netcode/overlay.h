#pragma once

#ifndef OVERLAY_H
#define OVERLAY_H 1

struct ManbowActor2DGroup;
struct ManbowActor2D;

void overlay_init();
void overlay_destroy();

void overlay_set_hitboxes(ManbowActor2DGroup* group, int p1_flags, int p2_flags);
void overlay_clear();
void overlay_draw();
bool IsFrameActive(ManbowActor2DGroup *group);
int IsFrameActive(ManbowActor2DGroup* group,ManbowActor2D* actor1,ManbowActor2D* actor2);
bool hasData(ManbowActor2DGroup *group);

#endif
