#pragma once

#ifndef LOG_H
#define LOG_H 1

#include <stdio.h>
#include "util.h"

typedef void cdecl printf_t(const char* format, ...);
typedef void cdecl fprintf_t(FILE* stream, const char* format, ...);

extern printf_t* log_printf;
extern fprintf_t* log_fprintf;

#ifdef NDEBUG
#define debug_printf(...) EVAL_NOOP(__VA_ARGS__)
#define debug_fprintf(...) EVAL_NOOP(__VA_ARGS__)
#else
#define debug_printf(...) (log_printf(__VA_ARGS__))
#define debug_fprintf(...) (log_fprintf(__VA_ARGS__))
#endif

#endif