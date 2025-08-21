#pragma once

#ifndef ROLLBACK_H
#define ROLLBACK_H 1

#define ROLLBACK_MAX_FRAMES 8
#define ROLLBACK_FRAME_MASK (ROLLBACK_MAX_FRAMES - 1)

void rollback_start();
void rollback_stop();
void rollback_preframe();
void rollback_postframe();
void rollback_rewind(size_t frames);

#endif
