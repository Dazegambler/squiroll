#pragma once

#ifndef NETCODE_H
#define NETCODE_H 1

#include <squirrel.h>

#define NETPLAY_DISABLE 0
#define NETPLAY_VER_103F 1

#define NETPLAY_PATCH_TYPE NETPLAY_VER_103F

#define BETTER_BLACK_SCREEN_FIX 1

extern SQBool resyncing;

extern SQBool isplaying;

void patch_netplay();

#endif