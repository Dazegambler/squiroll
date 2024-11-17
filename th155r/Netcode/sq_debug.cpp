#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include "kite_api.h"

#include "file_replacement.h"
#include "log.h"
#include "util.h"
#include "patch_utils.h"

//NATIVE FUNCTIONS

void SQCompilerErrorHandler(HSQUIRRELVM vm, const SQChar* desc, const SQChar* src, SQInteger line, SQInteger col) {
    log_printf( 
        "Squirrel compiler exception: %s\n"
        "<%d,%d> \"%s\"\n",
        src,
        line, col, desc
    );
}

static void print_stack_top_value(HSQUIRRELVM v, int depth) {
    union {
        SQInteger val_int;
        SQFloat val_float;
        SQBool val_bool;
        HSQOBJECT val_obj;
        struct {
            SQUserPointer val_user_ptr;
            SQUserPointer val_type_tag;
        };
        struct {
            const SQChar* val_string;
            SQUnsignedInteger val_closure_params;
            SQUnsignedInteger val_closure_free_vars;
        };
        HSQUIRRELVM val_thread;
    };

    switch (uint32_t val_type = _RAW_TYPE(sq_gettype(v, -1))) {
        case _RT_NULL:
            log_printf("null");
            break;
        case _RT_INTEGER:
            sq_getinteger(v, -1, &val_int);
            log_printf("%" _PRINT_INT_PREC "d", val_int);
            break;
        case _RT_FLOAT:
            sq_getfloat(v, -1, &val_float);
            log_printf("%f", val_float);
            break;
        case _RT_BOOL:
            sq_getbool(v, -1, &val_bool);
            log_printf(val_bool ? "true" : "false");
            break;
        case _RT_STRING:
            sq_getstring(v, -1, &val_string);
            log_printf("\"%s\"", val_string);
            break;
        case _RT_TABLE: case _RT_ARRAY:
            if (sq_getsize(v, -1)) {
                log_printf(val_type == _RT_TABLE ? "{\n" : "[\n");

                sq_pushnull(v);
                while (SQ_SUCCEEDED(sq_next(v, -2))) {
                    //Key|value
                    // -2|-1
                    sq_getstring(v, -2, &val_string);
                    log_printf("%*s\"%s\": ", depth, "", val_string);

                    print_stack_top_value(v, depth + 1);

                    log_printf(",\n");

                    sq_pop(v, 2);
                }
                sq_pop(v, 1);

                log_printf(val_type == _RT_TABLE ? "%*s}" : "%*s]", depth - 1, "");
            } else {
                log_printf(val_type == _RT_TABLE ? "{}" : "[]");
            }
            break;
        case _RT_USERDATA:
            sq_getuserdata(v, -1, &val_user_ptr, &val_type_tag);
            log_printf("UserData %p (%p type, %" _PRINT_INT_PREC "d bytes)", val_user_ptr, val_type_tag, sq_getsize(v, -1));
            break;
        case _RT_CLOSURE: case _RT_NATIVECLOSURE:
            sq_getclosureinfo(v, -1, &val_closure_params, &val_closure_free_vars);
            sq_getclosurename(v, -1);
            if (_RAW_TYPE(sq_gettype(v, -1)) == _RT_STRING) {
                sq_getstring(v, -1, &val_string);
                log_printf(
                    val_type == _RT_CLOSURE
                        ? "Closure \"%s\" (%" _PRINT_INT_PREC "u params, %" _PRINT_INT_PREC "u free)"
                        : "NativeClosure \"%s\" (%" _PRINT_INT_PREC "u params, %" _PRINT_INT_PREC "u free)"
                    , val_string, val_closure_params, val_closure_free_vars
                );
            } else {
                log_printf(
                    val_type == _RT_CLOSURE
                        ? "Closure (%" _PRINT_INT_PREC "u params, %" _PRINT_INT_PREC "u free)"
                        : "NativeClosure (%" _PRINT_INT_PREC "u params, %" _PRINT_INT_PREC "u free)"
                    , val_closure_params, val_closure_free_vars
                );
            }
            sq_pop(v, 1);
            break;
        case _RT_GENERATOR:
            log_printf("Generator");
            break;
        case _RT_USERPOINTER:
            sq_getuserpointer(v, -1, &val_user_ptr);
            log_printf("UserPointer (%p)", val_user_ptr);
            break;
        case _RT_THREAD:
            sq_getthread(v, -1, &val_thread);
            log_printf("Thread (%p)", val_thread);
            break;
        case _RT_FUNCPROTO:
            log_printf("FuncProto");
            break;
        case _RT_CLASS: case _RT_INSTANCE:
            sq_gettypetag(v, -1, &val_type_tag);
            log_printf(val_type == _RT_CLASS ? "Class (%p type)" : "Instance (%p type)", val_type_tag);
            break;
        case _RT_WEAKREF:
            sq_getweakrefval(v, -1);
            log_printf("(WeakRef) ");
            print_stack_top_value(v, depth);
            sq_pop(v, 1);
            break;
        case _RT_OUTER:
            log_printf("Outer");
            break;
        default:
            unreachable;
    }
}

static void CompileScriptBuffer(HSQUIRRELVM v, const char *Src, HSQOBJECT root) {
    if (EmbedData embed = get_new_file_data(Src)) {
        if (SQ_SUCCEEDED(sq_compilebuffer(v, (const SQChar*)embed.data, embed.length, Src, SQTrue))) {
            sq_pushobject(v, root);
            sq_call(v, 1, SQFalse, SQTrue);
            sq_pop(v, -1);
        }
    }
}

//keeping the original version that compiled the string instead just in case
/*void CompileScriptBuffer(HSQUIRRELVM v, const char *Src, SQObject root) {
  bool is_compiled = false;
  if (Src) {
    is_compiled = SQ_SUCCEEDED(sq_compilebuffer(v, Src, strlen(Src), _SC("repl"), SQTrue));
    if (is_compiled) {
        sq_pushobject(v, root);
        sq_call(v, 1, SQFalse, SQTrue);
        sq_pop(v, -1);
    } else{
        sq_throwerror(v, _SC("failed to compile script...\n"));
        sq_throwexception(v,"repl");
    }
  }
}*/

/*
HSQOBJECT SQGetObjectByName(HSQUIRRELVM v, const SQChar *name) {
    sq_pushstring(v, name, -1);
    sq_get(v, -2);
    HSQOBJECT ret = {};
    sq_getstackobj(v, -1, &ret);
    sq_pop(v, 1);
    return ret;
}
*/

//SQUIRREL FUNCTIONS
SQInteger sq_print(HSQUIRRELVM v) {
    const SQChar* str;
    if (sq_gettop(v) != 2 || 
        SQ_FAILED(sq_getstring(v, 2, &str))
    ) {
        return sq_throwerror(v, "Invalid arguments,expected:<string>");
    }

    log_printf("%s", str);
    return 0;
}

SQInteger sq_fprint(HSQUIRRELVM v) {
    const SQChar* str;
    const SQChar* path;
    if (sq_gettop(v) != 3 ||
        SQ_FAILED(sq_getstring(v, 2, &path)) ||
        SQ_FAILED(sq_getstring(v, 3, &str))
    ) {
        return sq_throwerror(v, _SC("invalid arguments...expected: <file> <string>.\n"));
    }
#if SQUNICODE
    if (FILE* file = _wfopen(path, L"a")) {
        log_fprintf(file, "%ls", str);
        fclose(file);
    }
#else
    if (FILE* file = fopen(path, "a")) {
        log_fprintf(file, "%s", str);
        fclose(file);
    }
#endif
    return 0;
}

SQInteger sq_print_value(HSQUIRRELVM v) {
    HSQOBJECT obj;
    if (sq_gettop(v) != 2 || 
        SQ_FAILED(sq_getstackobj(v, 2, &obj))
    ) {
        return sq_throwerror(v, _SC("Invalid arguments... expected: <object>.\n"));
    }
    sq_pushobject(v, obj);
    print_stack_top_value(v, 1);
    sq_pop(v, 1);
    log_printf("\n");
    return 0;
}

SQInteger sq_compile_buffer(HSQUIRRELVM v){
    const SQChar* src;
    HSQOBJECT root;
    if (sq_gettop(v) != 3                       ||
        SQ_FAILED(sq_getstring(v, 2, &src))     ||
        SQ_FAILED(sq_getstackobj(v, 3, &root))
    ) {
        return sq_throwerror(v, _SC("Invalid arguments...\n"
                             "usage: compilebuffer <src> <root>\n"));
    }
    CompileScriptBuffer(v, src, root);
    return 0;
}

SQInteger sq_throwexception(HSQUIRRELVM v) {
    if (sq_gettop(v) > 0) {
        const SQChar* error_msg;
        if (SQ_SUCCEEDED(sq_getstring(v, 2, &error_msg))) {
            log_printf("Squirrel runtime exception: \"%s\"\n", error_msg);
            SQStackInfos sqstack;
            for (
                SQInteger i = 1;
                SQ_SUCCEEDED(sq_stackinfos(v, i, &sqstack));
                ++i
            ) {
                log_printf(
                    *sqstack.source ? " %d | %s (%s)\n" : " %d | %s\n"
                    , sqstack.line, sqstack.funcname ? sqstack.funcname : "Anonymous function", sqstack.source
                );
            }
        }
    }
    return 0;
}