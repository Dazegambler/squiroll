#pragma once

#include <squirrel.h>
#ifndef SQ_DEBUG_H
#define SQ_DEBUG_H 1

#include <stdint.h>
#include <stdlib.h>

#include "kite_api.h"
#include "shared.h"

static SQInteger sq_dummy(HSQUIRRELVM v) {
    return 0;
}

//SQUIRREL FUNCTIONS
SQInteger sq_CompileFile(HSQUIRRELVM v);
SQInteger sq_compile_buffer(HSQUIRRELVM v); 
void CompileAndRun(HSQUIRRELVM v, const char *Src);

#if !DISABLE_ALL_LOGGING_FOR_BUILD
SQInteger sq_print(HSQUIRRELVM v);
SQInteger sq_fprint(HSQUIRRELVM v);
SQInteger sq_print_value(HSQUIRRELVM v);
SQInteger sq_fprint_value(HSQUIRRELVM v);
SQInteger loadCSVBuffer(HSQUIRRELVM v);
#else
#define sq_print sq_dummy
#define sq_fprint sq_dummy
#define sq_print_value sq_dummy
#define sq_fprint_value sq_dummy
#endif

SQInteger sq_deepcopy(HSQUIRRELVM v);

#endif