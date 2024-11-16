#pragma once

#ifndef SQ_DEBUG_H
#define SQ_DEBUG_H 1

#include <stdint.h>
#include <stdlib.h>

#include "kite_api.h"

//NATIVE FUNCTIONS
bool CompileScriptBuffer(HSQUIRRELVM v, const char *Src, const char *to);
void show_tree(HSQUIRRELVM v, SQObject Root);
HSQOBJECT SQGetObjectByName(HSQUIRRELVM v, const SQChar *name);
void SQCompilerErrorHandler(HSQUIRRELVM vm, const SQChar* Desc, const SQChar* Src, SQInteger line, SQInteger col);

//SQUIRREL FUNCTIONS
SQInteger sq_print(HSQUIRRELVM v);
SQInteger sq_fprint(HSQUIRRELVM v);
SQInteger sq_show_tree(HSQUIRRELVM v);
SQInteger sq_compile_buffer(HSQUIRRELVM v);
SQInteger sq_throwexception(HSQUIRRELVM v);

#endif