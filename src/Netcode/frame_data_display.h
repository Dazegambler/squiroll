#pragma once

#ifndef FRAME_DATA_DISPLAY_H
#define FRAME_DATA_DISPLAY_H 1

#include "TF4.h"

int IsFrameActive(ManbowActor2DGroup* group,ManbowActor2D* actor1,ManbowActor2D* actor2);
bool IsFrameActive(ManbowActor2DGroup *group);
bool hasData(ManbowActor2DGroup *group);
int GetFrameCount(ManbowActor2D *player);

#endif