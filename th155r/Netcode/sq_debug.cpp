#include "kite_api.h"
#if __has_builtin(__builtin_offsetof)
#ifdef offsetof
#undef offsetof
#endif
#define offsetof(s, m) __builtin_offsetof(s, m)
#endif

#include "file_replacement.h"
#include "log.h"
#include "util.h"
#include "sq_debug.h"
#include "patch_utils.h"

//NATIVE FUNCTIONS

void SQCompilerErrorHandler(HSQUIRRELVM vm, const SQChar* desc, const SQChar* src, SQInteger line, SQInteger col) {
    log_printf( 
        "Squirrel compiler exception:%s\n"
        "<%d,%d>%s\n",
        src,
        line, col, desc
    );
}

void show_tree(HSQUIRRELVM v, SQObject Root) {
    sq_pushobject(v, Root);
    if (SQ_FAILED(sq_gettype(v, -1))){
        //sq_throwerror(v, _SC("Invalid arguments... expected: <object>.\n"));
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
            /*
            NULL,
            INTEGER,
            FLOAT,
            STRING,
            CLOSURE(SQUIRREL FUNCTION),
            NATIVECLOSURE(C++ FUNCTION),
            BOOL,
            INSTANCE,
            CLASS,
            ARRAY,
            TABLE,
            USERDATA,
            USERPOINTER,
            GENERATOR,
            WEAKREF
            */
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
                log_printf(">%s : %s : %s\n", key, valstr, val ? "true" : "false");
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

void CompileScriptBuffer(HSQUIRRELVM v, const char *Src, SQObject root) {
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

HSQOBJECT SQGetObjectByName(HSQUIRRELVM v, const SQChar *name) {
    sq_pushstring(v, name, -1);
    sq_get(v, -2);
    HSQOBJECT ret = {};
    sq_getstackobj(v, -1, &ret);
    sq_pop(v, 1);
    return ret;
}

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

SQInteger sq_show_tree(HSQUIRRELVM v) {
    SQObject pObj;
    if (sq_gettop(v) != 2 || 
        SQ_FAILED(sq_getstackobj(v, 2, &pObj))
    ){
        return sq_throwerror(v, _SC("Invalid arguments... expected: <object>.\n"));
    }
    show_tree(v, pObj);
    return 0;
}

SQInteger sq_compile_buffer(HSQUIRRELVM v){
    const SQChar* src;
    SQObject root;
    if (sq_gettop(v) != 3                       ||
        SQ_FAILED(sq_getstring(v, 2, &src))     ||
        SQ_FAILED(sq_getstackobj(v, 3, &root))
    ){
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
            log_printf("Squirrel runtime exception: %s\n", error_msg);
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