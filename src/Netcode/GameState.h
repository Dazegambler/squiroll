#pragma once
#ifndef GAMESTATE_H
#define GAMESTATE_H

struct AnimationController2DState;

struct Actor2DState {
	float pos[3];
	int32_t id;
	float left;
	float top;
	float right;
	float bottom;
	float vx;
	float vy;
	float direction;
	AnimationController2DState anim_controller;
	float ox;
	float oy;
	float skew[3];
	float rotation[3];
	uint8_t active_flags;
	uint32_t collision_group;
	uint32_t collision_mask;
	uint32_t callback_group;
	uint32_t callback_mask;
	float hitLeft;
	float hitTop;
	float hitRight;
	float hitBottom;
	uint32_t group_flags;
	uint32_t list_idx;
	uint32_t unkE4;
	uint32_t id2;
};

#endif
