#pragma once

#ifndef LOG_H
#define LOG_H 1

#include <stdio.h>
#include "util.h"
#include "shared.h"

#define ALWAYS_DISABLE_ORIGINAL_GAME_LOGGING 1

#define CONNECTION_LOGGING_NONE				0b000
#define CONNECTION_LOGGING_LOBBY_DEBUG		0b001
#define CONNECTION_LOGGING_LOBBY_PACKETS	0b010
#define CONNECTION_LOGGING_UDP_PACKETS		0b100

#if !DISABLE_ALL_LOGGING_FOR_BUILD

#define CONNECTION_LOGGING (CONNECTION_LOGGING_LOBBY_DEBUG | CONNECTION_LOGGING_LOBBY_PACKETS | CONNECTION_LOGGING_UDP_PACKETS)
//#define CONNECTION_LOGGING CONNECTION_LOGGING_NONE

typedef void cdecl printf_t(const char* format, ...);
typedef void cdecl fprintf_t(FILE* stream, const char* format, ...);

extern printf_t* log_printf;
extern fprintf_t* log_fprintf;

static void cdecl printf_dummy(const char* format, ...) {
}
static void cdecl fprintf_dummy(FILE* stream, const char* format, ...) {
}

#ifdef NDEBUG
#define debug_printf(...) EVAL_NOOP(__VA_ARGS__)
#define debug_fprintf(...) EVAL_NOOP(__VA_ARGS__)
#else
#define debug_printf(...) (log_printf(__VA_ARGS__))
#define debug_fprintf(...) (log_fprintf(__VA_ARGS__))
#endif

void patch_throw_logs();

#else

#define CONNECTION_LOGGING CONNECTION_LOGGING_NONE

#define log_printf(...) EVAL_NOOP(__VA_ARGS__)
#define log_fprintf(...) EVAL_NOOP(__VA_ARGS__)
#define debug_printf(...) EVAL_NOOP(__VA_ARGS__)
#define debug_fprintf(...) EVAL_NOOP(__VA_ARGS__)
#endif

#endif