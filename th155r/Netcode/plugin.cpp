#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include "kite_api.h"
#include "PatchUtils.h"

#include "util.h"
#include "log.h"
#include "netcode.h"

const KiteSquirrelAPI* KITE;

struct HostEnvironment;

typedef int thisfastcall get_value_t(
    const HostEnvironment* self,
    thisfastcall_edx(int dummy_edx,)
    const char* name,
    void** out
);

// size: 0x10
struct HostEnvironmentVftable {
    void *const __validate_environment; // 0x0
    void *const __method_4; // 0x4
    void *const __method_8; // 0x4
    get_value_t *const get_value; // 0xC
    // 0x10
};

// size: unknown
struct HostEnvironment {
    const HostEnvironmentVftable* vftable;

protected:
    template<typename T = void*>
    inline bool thiscall get_value(const char* name, T* out) const {
        return SUCCEEDED(this->vftable->get_value(
            this,
            thisfastcall_edx(0,)
            name,
            (void**)out
        ));
    }

public:

    inline bool get_hwnd(HWND& out) const {
        return this->get_value("HWND", &out);
    }

    inline bool get_hinstance(HINSTANCE& out) const {
        return this->get_value("HINSTANCE", &out);
    }

    // this just returns "Windows"
    inline bool get_platform(const char*& out) const {
        return this->get_value("PLATFORM", &out);
    }

    inline bool get_squirrel_vm(HSQUIRRELVM& out) const {
        return this->get_value("HSQUIRRELVM", &out);
    }

    inline bool get_kite_api(const KiteSquirrelAPI*& out) const {
        return this->get_value("Kite_SquirrelAPI", &out);
    }

    inline bool get_file_open_read_func(void*& out) const {
        return this->get_value("Function_FileOpenRead", &out);
    }

    inline bool get_file_open_write_func(void*& out) const {
        return this->get_value("Function_FileOpenWrite", &out);
    }

    inline bool get_interface_object_graphics(void*& out) const {
        return this->get_value("InterfaceObject_Graphics", &out);
    }

    inline bool get_interface_object_memory(void*& out) const {
        return this->get_value("InterfaceObject_Memory", &out);
    }
};

// SQInteger example_function(HSQUIRRELVM v) {
//     SQBool arg;
//     if (SQ_SUCCEEDED(sq_getbool(v, 2, &arg))) {
//         log_printf("function called from Squirrel with argument: %d\n", arg);
//         sq_pushbool(v, arg); // Return the argument
//     } else {
//         log_printf("function called from Squirrel with no arguments.\n");
//         return 0;
//     }
//     return 1; // Number of return values
// }

HSQUIRRELVM v;

#define sq_setprintfunc_call_addr (0x024769_R)
#define Sq_setcompilererrorhandler_call_addr (0x024757_R)


void sq_print(HSQUIRRELVM v, const SQChar* s, ...) {
    va_list args;
    va_start(args, s);
    log_printf(s, args);
    va_end(args);
}

void sq_printerr(HSQUIRRELVM v, const SQChar* s, ...) {
    va_list args;
    va_start(args, s);
    log_fprintf(stderr,s,args);
    va_end(args);
}

void sq_CompilerErrorHandler(HSQUIRRELVM v, const SQChar* desc, const SQChar* source, SQInteger line, SQInteger column) {
    HANDLE h = GetCurrentThread();
    SuspendThread(h);
    //FILE* out = fopen("compile_error.txt","a");
    log_printf( "Compilation Error in %s at line %d, column %d: %s\n", source, (int)line, (int)column, desc);
    //fclose(out);
}

void my_sq_setprintfunc(HSQUIRRELVM v, SQPRINTFUNCTION printfunc,SQPRINTFUNCTION errfunc)
{
    sq_setprintfunc(v,sq_print,sq_printerr);
}

void my_sq_setcompilererrorhandler(HSQUIRRELVM v,SQCOMPILERERROR f)
{
    sq_setcompilererrorhandler(v,sq_CompilerErrorHandler);
}

SQInteger patch_test(HSQUIRRELVM v){
    return 0;
}

extern "C" {
    dll_export int stdcall init_instance_v2(HostEnvironment* environment) {
        if (
            environment &&
            environment->get_squirrel_vm(v) &&
            environment->get_kite_api(KITE)
        ) {
            
            hotpatch_rel32(sq_setprintfunc_call_addr,my_sq_setprintfunc);
            hotpatch_rel32(Sq_setcompilererrorhandler_call_addr,my_sq_setcompilererrorhandler);
            // put any important initialization stuff here,
            // like adding squirrel globals/funcs/etc.
            sq_pushroottable(v);

            //rollback table setup
            sq_pushstring(v, _SC("rollback"), -1);
            sq_newtable(v);

            //variables setup
            sq_pushstring(v, _SC("resyncing"), -1);
            sq_pushbool(v, resyncing);
            sq_newslot(v, -3, SQFalse);


            //function setup
            // sq_pushstring(v, _SC("example_function"), -1);
            // sq_newclosure(v, example_function, 0);
            // sq_newslot(v, -3, SQFalse);

            //adding the rollback table to global scope
            sq_newslot(v, -3, SQFalse);

            sq_pop(v, 1);
            return 1;
        }
        return -1;
    }

    dll_export int stdcall release_instance() {
        return 1;
    }

    dll_export int stdcall update_frame() {
    
        sq_pushroottable(v);

        //saving ::network.IsPlaying to a variable
        //getting the network table
        sq_pushstring(v,_SC("network"),-1);
        if (SQ_SUCCEEDED(sq_get(v,-2))){
            //Getting the variable
            sq_pushstring(v,_SC("IsPlaying"),-1);
            if (SQ_SUCCEEDED(sq_get(v,-2))){
                if (sq_gettype(v,-1) == OT_BOOL){
                    sq_getbool(v,-1,&isplaying);
                }
                //pop the variable
                sq_pop(v,1);
            }
            //pop the network table
            sq_pop(v,1);
        }
        
        //pop the roottable
        sq_pop(v,1);        
        return 1;
    }

    dll_export int stdcall render_preproc() {
        return 0;
    }

    dll_export int stdcall render(int, int) {
        return 0;
    }
}