#pragma once

#ifndef LOG_H
#define LOG_H 1

typedef void printf_t(const char* format, ...);

extern printf_t* log_printf;

#ifdef NDEBUG
#define debug_printf(...) EVAL_NOOP(__VA_ARGS__)
#else
#define debug_printf(...) (log_printf(__VA_ARGS__))
#endif

#endif