#pragma once

#ifndef KITE_API_SQRAT_H
#define KITE_API_SQRAT_H 1

#include "kite_api.h"

#include <string>

#ifdef __int64
#pragma push_macro("__int64")
#undef __int64
#define MINGW_REDEF_INT64 1
#endif

#include <sqrat.h>

#if MINGW_REDEF_INT64
#pragma pop_macro("__int64")
#endif

#endif