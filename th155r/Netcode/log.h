#pragma once

#ifndef LOG_H
#define LOG_H 1

#include "util.h"

typedef void printf_t(const char* format, ...);

extern printf_t* log_printf;

#endif