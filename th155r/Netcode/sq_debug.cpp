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

#if !DISABLE_ALL_LOGGING_FOR_BUILD
static void print_stack_top_value(FILE* dest, HSQUIRRELVM v, int depth) {
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
            log_fprintf(dest, "null");
            break;
        case _RT_INTEGER:
            sq_getinteger(v, -1, &val_int);
            log_fprintf(dest, "%" _PRINT_INT_PREC "d", val_int);
            break;
        case _RT_FLOAT:
            sq_getfloat(v, -1, &val_float);
            log_fprintf(dest, "%f", val_float);
            break;
        case _RT_BOOL:
            sq_getbool(v, -1, &val_bool);
            log_fprintf(dest, val_bool ? "true" : "false");
            break;
        case _RT_STRING:
            sq_getstring(v, -1, &val_string);
            log_fprintf(dest, "\"%s\"", val_string);
            break;
        case _RT_USERDATA:
            sq_getuserdata(v, -1, &val_user_ptr, &val_type_tag);
            log_fprintf(dest, "UserData %p (%p type, %" _PRINT_INT_PREC "d bytes)", val_user_ptr, val_type_tag, sq_getsize(v, -1));
            break;
        case _RT_CLOSURE: case _RT_NATIVECLOSURE:
            sq_getclosureinfo(v, -1, &val_closure_params, &val_closure_free_vars);
            sq_getclosurename(v, -1);
            if (_RAW_TYPE(sq_gettype(v, -1)) == _RT_STRING) {
                sq_getstring(v, -1, &val_string);
                log_fprintf(dest,
                    val_type == _RT_CLOSURE
                        ? "Closure \"%s\" (%" _PRINT_INT_PREC "u params, %" _PRINT_INT_PREC "u free)"
                        : "NativeClosure \"%s\" (%" _PRINT_INT_PREC "u params, %" _PRINT_INT_PREC "u free)"
                    , val_string, val_closure_params, val_closure_free_vars
                );
            } else {
                log_fprintf(dest,
                    val_type == _RT_CLOSURE
                        ? "Closure (%" _PRINT_INT_PREC "u params, %" _PRINT_INT_PREC "u free)"
                        : "NativeClosure (%" _PRINT_INT_PREC "u params, %" _PRINT_INT_PREC "u free)"
                    , val_closure_params, val_closure_free_vars
                );
            }
            sq_pop(v, 1);
            break;
        case _RT_GENERATOR:
            log_fprintf(dest, "Generator");
            break;
        case _RT_USERPOINTER:
            sq_getuserpointer(v, -1, &val_user_ptr);
            log_fprintf(dest, "UserPointer (%p)", val_user_ptr);
            break;
        case _RT_THREAD:
            sq_getthread(v, -1, &val_thread);
            log_fprintf(dest, "Thread (%p)", val_thread);
            break;
        case _RT_FUNCPROTO:
            log_fprintf(dest, "FuncProto");
            break;
        case _RT_INSTANCE:
            sq_getclass(v, -1);
            sq_remove(v, -2);
        case _RT_CLASS:
            sq_gettypetag(v, -1, &val_type_tag);
            log_fprintf(dest, val_type == _RT_CLASS ? "Class (%p type)" : "Instance (%p type)", val_type_tag);
            goto skip_size_check;

        case _RT_TABLE: case _RT_ARRAY:
            if (sq_getsize(v, -1)) {

        skip_size_check:
                log_fprintf(dest, val_type != _RT_ARRAY ? "{\n" : "[\n");

                sq_pushnull(v);
                while (SQ_SUCCEEDED(sq_next(v, -2))) {
                    //Key|value
                    // -2|-1
                    sq_getstring(v, -2, &val_string);
                    log_fprintf(dest, "%*s\"%s\": ", depth, "", val_string);

                    print_stack_top_value(dest, v, depth + 1);

                    log_fprintf(dest, ",\n");

                    sq_pop(v, 2);
                }
                sq_pop(v, 1);

                log_fprintf(dest, val_type != _RT_ARRAY ? "%*s}" : "%*s]", depth - 1, "");
            } else {
                log_fprintf(dest, val_type != _RT_ARRAY ? "{}" : "[]");
            }
            break;
        case _RT_WEAKREF:
            sq_getweakrefval(v, -1);
            log_fprintf(dest, "(WeakRef) ");
            print_stack_top_value(dest, v, depth);
            sq_pop(v, 1);
            break;
        case _RT_OUTER:
            log_fprintf(dest, "Outer");
            break;
        default:
            unreachable;
    }
}
#endif

 /*
static void show_tree(HSQUIRRELVM v, HSQOBJECT Root) {
    sq_pushobject(v, Root);
    SQObjectType obj_type = sq_gettype(v, -1);
    if (!(obj_type & SQOBJECT_DELEGABLE)){
        log_printf("root object is not delegable\n");
        return;
    }
    if (SQ_SUCCEEDED(sq_tostring(v, -1))) { 
        const SQChar *objStr;
        sq_getstring(v, -1, &objStr);  
        log_printf(">>>>>>%s<<<<<<\n", objStr);
        sq_pop(v, 1); 
    } else {
        SQUserPointer ptr;
        sq_getuserpointer(v, -1, &ptr);
        log_printf(">>>>>>%p<<<<<<\n", ptr);
    }

    sq_pushnull(v);
    while (SQ_SUCCEEDED(sq_next(v, -2))) {
        //Key|value
        // -2|-1
        const SQChar* key;
        sq_getstring(v, -2, &key);

        const SQChar *valstr;
        sq_typeof(v, -1);{
            if (SQ_FAILED(sq_getstring(v, -1, &valstr)))valstr = _SC("Unknown");
            sq_pop(v, 1);
        }
        switch (sq_gettype(v, -1)) {
            //All Value types
            //NULL,
            //INTEGER,
            //FLOAT,
            //STRING,
            //CLOSURE(SQUIRREL FUNCTION),
            //NATIVECLOSURE(C++ FUNCTION),
            //BOOL,
            //INSTANCE,
            //CLASS,
            //ARRAY,
            //TABLE,
            //USERDATA,
            //USERPOINTER,
            //GENERATOR,
            //WEAKREF
            case OT_NULL: {
                log_printf(">%s : %s : NULL\n", key, valstr);
                break;
            }

            case OT_INTEGER: {
                SQInteger val;
                sq_getinteger(v, -1, &val);
                log_printf(">%s : %s : %d\n", key, valstr, val);
                break;
            }

            case OT_FLOAT: {
                SQFloat val;
                sq_getfloat(v, -1, &val);
                log_printf(">%s : %s : %f\n", key, valstr, val);
                break;
            }

            case OT_STRING: {
                const SQChar* val;
                sq_getstring(v, -1, &val);
                log_printf(">%s : %s : %s\n", key, valstr, val);
                break;
            }

            case OT_CLOSURE: {
                SQUnsignedInteger numParams, numFreeVars;
                sq_getclosureinfo(v, -1, &numParams, &numFreeVars);
                log_printf(">%s : %s : %d arguments, %d free variables\n", key, valstr, numParams, numFreeVars);
                break;
            }

            case OT_NATIVECLOSURE: {
                SQUnsignedInteger numParams;
                sq_getclosureinfo(v, -1, &numParams, nullptr);
                log_printf(">%s : %s : %d arguments\n", key, valstr, numParams);
                break;
            }

            case OT_BOOL: {
                SQBool val;
                sq_getbool(v, -1, &val);
                log_printf(">%s : %s : %s\n", key, valstr, bool_str(val));
                break;
            }

            case OT_INSTANCE: {
                sq_push(v, -1);
                const SQChar *className;
                if (SQ_SUCCEEDED(sq_gettypetag(v, -1, (SQUserPointer *)&className))) {
                    log_printf(">%s : %s : %s\n", key, valstr, className);
                } else {
                    log_printf(">%s : %s : unknown\n", key, valstr);
                }
                sq_pop(v, 1);
                break;
            }

            case OT_CLASS: {
                const SQChar *className;
                if (SQ_SUCCEEDED(sq_gettypetag(v, -1, (SQUserPointer *)&className))) {
                    log_printf(">%s : %s : %s\n", key, valstr, className);
                } else {
                    log_printf(">%s : %s : unknown\n", key, valstr);
                }
                break;
            }

            case OT_ARRAY: case OT_TABLE: {
                SQInteger size = sq_getsize(v, -1);
                log_printf(">%s : %s : %d\n",key, valstr, size);
                break;
            }
            default: {
                SQUserPointer val;
                sq_getuserpointer(v, -1, &val);
                log_printf(">%s : %s : %p\n", key, valstr, val);
                break;
            }
        }
        sq_pop(v, 2);
    }

    sq_pop(v, 1);
    log_printf("<<<<<<>>>>>>\n");
}
*/


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

#if !DISABLE_ALL_LOGGING_FOR_BUILD
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
    print_stack_top_value(stdout, v, 1);
    sq_pop(v, 1);
    log_printf("\n");
    return 0;
}

SQInteger sq_fprint_value(HSQUIRRELVM v) {
    HSQOBJECT obj;
    const SQChar* path;
    if (sq_gettop(v) != 3 || 
        SQ_FAILED(sq_getstackobj(v, 2, &obj)) ||
        SQ_FAILED(sq_getstring(v, 3, &path))
    ) {
        return sq_throwerror(v, _SC("Invalid arguments... expected: <object> <file>.\n"));
    }
    if (
#if SQUNICODE
        FILE* file = _wfopen(path, L"a")
#else
        FILE* file = fopen(path, "a")
#endif
    ) {
        sq_pushobject(v, obj);
        print_stack_top_value(file, v, 1);
        sq_pop(v, 1);
        fclose(file);
    }
    return 0;
}
#endif