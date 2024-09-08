#pragma once

#ifndef FILE_REPLACEMENT_H
#define FILE_REPLACEMENT_H 1

#include <windows.h>
#include "util.h"

//typedef int (*func_patch_t)(void* file_inout, size_t size_out, size_t size_in, const char* fn, void* patch);
//typedef size_t (*func_patch_size_t)(const char* fn, void* patch, size_t patch_size);

//typedef void __stdcall patchhook_register_t(const char *ext, func_patch_t patch_func, func_patch_size_t patch_size_func);

//extern patchhook_register_t* patchhook_register;

naked void file_replacement_hook();
BOOL WINAPI file_replacement_read(HANDLE handle, LPVOID buffer, DWORD buffer_size, LPDWORD bytes_read, LPOVERLAPPED overlapped);
BOOL WINAPI close_handle_hook(HANDLE handle);

//void file_replacement_thcrap();

#endif