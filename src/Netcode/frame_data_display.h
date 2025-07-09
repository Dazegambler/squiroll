#pragma once

#ifndef FRAME_DATA_DISPLAY_H
#define FRAME_DATA_DISPLAY_H 1

#include "TF4.h"

bool IsFrameActive(ManbowActor2D* actor1);
bool hasData(ManbowActor2D *actor);
int16_t* GetMetadata(ManbowActor2D* player);

#endif