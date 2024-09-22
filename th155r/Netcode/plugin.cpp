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
#include "config.h"

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

SQInteger r_resync_get(HSQUIRRELVM v) {
    sq_pushbool(v, resyncing);
    return 1;
}

SQInteger update_ping_constants(HSQUIRRELVM v) {
    sq_pushroottable(v);

    sq_pushstring(v, _SC("setting"), -1);
        sq_newtable(v);
        sq_pushstring(v, _SC("ping"), -1);
            sq_newclass(v, SQFalse);
            sq_pushstring(v, _SC("X"), -1);
                sq_pushinteger(v, get_ping_x());
            sq_newslot(v, -3, SQFalse);
            sq_pushstring(v, _SC("Y"), -1);
                sq_pushinteger(v, get_ping_y());
            sq_newslot(v, -3, SQFalse);
            sq_pushstring(v, _SC("SX"), -1);
                sq_pushfloat(v, get_ping_scale_x());
            sq_newslot(v, -3, SQFalse);
            sq_pushstring(v, _SC("SY"), -1);
                sq_pushfloat(v, get_ping_scale_y());
            sq_newslot(v, -3, SQFalse);
        sq_newslot(v, -3, SQFalse);
    sq_newslot(v, -3, SQFalse);

    sq_pop(v, 1);
    return 1;
}

extern "C" {
    dll_export int stdcall init_instance_v2(HostEnvironment* environment) {
        if (
            environment &&
            environment->get_squirrel_vm(v) &&
            environment->get_kite_api(KITE)
        ) {
            // put any important initialization stuff here,
            // like adding squirrel globals/funcs/etc.
            sq_pushroottable(v);

            //config table setup
            sq_pushstring(v, _SC("setting"), -1);
                sq_newtable(v);
                sq_pushstring(v, _SC("version"), -1);
                    sq_pushinteger(v, 69420); //PLACEHOLDER
                sq_newslot(v, -3, SQFalse);
                sq_pushstring(v, _SC("ping"), -1);
                    sq_pushstring(v, _SC("update_consts"), -1);
                        sq_newclosure(v, update_ping_constants, 0);
                    sq_newslot(v, -3, SQFalse);
                sq_newslot(v, -3, SQFalse);
            sq_newslot(v, -3, SQFalse);

            update_ping_constants(v);

            //rollback table setup
            sq_pushstring(v, _SC("rollback"), -1);
                sq_newtable(v);
                sq_pushstring(v, _SC("resyncing"), -1);
                    sq_newclosure(v, r_resync_get, 0);
                sq_newslot(v, -3, SQFalse);
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