#pragma once
#ifndef PatchUtils_H
#define PatchUtils_H

#include <windows.h>
#include <winuser.h>
#include <stdint.h>
#include <stdio.h>

void mem_write(LPVOID address, const void* data, size_t size);
void hotpatch_jump(void* target, void* replacement);
void hotpatch_rel32(void* target, void* replacement);

#endif