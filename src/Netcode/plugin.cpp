#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <string>

#include "kite_api.h"
#include "patch_utils.h"

#include "util.h"
#include "log.h"
#include "netcode.h"
#include "config.h"
#include "file_replacement.h"
#include "alloc_man.h"
#include "lobby.h"
#include "sq_debug.h"
#include "discord.h"

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

static HSQUIRRELVM v;

SQInteger r_resync_get(HSQUIRRELVM v) {
    sq_pushbool(v, (SQBool)resyncing);
    return 1;
}

static inline void set_ping_constants(HSQUIRRELVM v) {
    sq_setbool(v, _SC("enabled"), get_ping_enabled());
    sq_setinteger(v, _SC("X"), get_ping_x());
    sq_setinteger(v, _SC("Y"), get_ping_y());
    sq_setfloat(v, _SC("SX"), get_ping_scale_x());
    sq_setfloat(v, _SC("SY"), get_ping_scale_y());
    uint32_t color = get_ping_color();
    sq_setfloat(v, _SC("blue"), (float)(uint8_t)color / 255.0f);
    sq_setfloat(v, _SC("green"), (float)(uint8_t)(color >> 8) / 255.0f);
    sq_setfloat(v, _SC("red"), (float)(uint8_t)(color >> 16) / 255.0f);
    sq_setfloat(v, _SC("alpha"), (float)(uint8_t)(color >> 24) / 255.0f);
    sq_setbool(v, _SC("ping_in_frames"), get_ping_frames());
}

static inline void set_inputp1_constants(HSQUIRRELVM v) {
    sq_setbool(v, _SC("enabled"), get_inputp1_enabled());
    sq_setinteger(v, _SC("X"), get_inputp1_x());
    sq_setinteger(v, _SC("Y"), get_inputp1_y());
    sq_setfloat(v, _SC("SX"), get_inputp1_scale_x());
    sq_setfloat(v, _SC("SY"), get_inputp1_scale_y());
    sq_setinteger(v, _SC("offset"), get_inputp1_offset());
    sq_setinteger(v, _SC("list_max"), get_inputp1_count());
    sq_setbool(v, _SC("spacing"), get_inputp1_spacing());
    uint32_t color = get_inputp1_color();
    sq_setfloat(v, _SC("blue"), (float)(uint8_t)color / 255.0f);
    sq_setfloat(v, _SC("green"), (float)(uint8_t)(color >> 8) / 255.0f);
    sq_setfloat(v, _SC("red"), (float)(uint8_t)(color >> 16) / 255.0f);
    sq_setfloat(v, _SC("alpha"), (float)(uint8_t)(color >> 24) / 255.0f);
    int32_t timer = get_inputp1_timer();
    sq_setinteger(v, _SC("timer"), timer > 0 ? timer : 0);
    sq_setbool(v, _SC("raw_input"), get_inputp1_raw_input());
}

static inline void set_inputp2_constants(HSQUIRRELVM v) {
    sq_setbool(v, _SC("enabled"), get_inputp2_enabled());
    sq_setinteger(v, _SC("X"), get_inputp2_x());
    sq_setinteger(v, _SC("Y"), get_inputp2_y());
    sq_setfloat(v, _SC("SX"), get_inputp2_scale_x());
    sq_setfloat(v, _SC("SY"), get_inputp2_scale_y());
    sq_setinteger(v, _SC("offset"), get_inputp2_offset());
    sq_setinteger(v, _SC("list_max"), get_inputp2_count());
    sq_setbool(v, _SC("spacing"), get_inputp2_spacing());
    uint32_t color = get_inputp2_color();
    sq_setfloat(v, _SC("blue"), (float)(uint8_t)color / 255.0f);
    sq_setfloat(v, _SC("green"), (float)(uint8_t)(color >> 8) / 255.0f);
    sq_setfloat(v, _SC("red"), (float)(uint8_t)(color >> 16) / 255.0f);
    sq_setfloat(v, _SC("alpha"), (float)(uint8_t)(color >> 24) / 255.0f);
    int32_t timer = get_inputp2_timer();
    sq_setinteger(v, _SC("timer"), timer > 0 ? timer : 0);
    sq_setbool(v, _SC("raw_input"), get_inputp2_raw_input());
}

SQInteger update_ping_constants(HSQUIRRELVM v) {
    sq_pushroottable(v);

    sq_edit(v, _SC("setting"), [](HSQUIRRELVM v) {
        sq_edit(v, _SC("ping"), set_ping_constants);
    });

    sq_pop(v, 1);
    return 0;
}

SQInteger update_input_constants(HSQUIRRELVM v) {
    sq_pushroottable(v);

    sq_edit(v, _SC("setting"), [](HSQUIRRELVM v) {
        sq_edit(v, _SC("input_display"), [](HSQUIRRELVM v) {
            sq_edit(v, _SC("p1"), set_inputp1_constants);
            sq_edit(v, _SC("p2"), set_inputp2_constants);
        });
    });

    sq_pop(v, 1);
    return 0;
}

SQInteger start_direct_punch_wait(HSQUIRRELVM v) {
    send_lobby_punch_wait();
    return 0;
}

SQInteger start_direct_punch_connect(HSQUIRRELVM v) {
    const SQChar* ip;
    SQInteger port;
    if (
        sq_gettop(v) == 3 &&
        SQ_SUCCEEDED(sq_getstring(v, 2, &ip)) &&
        SQ_SUCCEEDED(sq_getinteger(v, 3, &port))
    ) {
        send_lobby_punch_connect(false, ip, port);
    }
    return 0;
}

SQInteger get_users_in_room(HSQUIRRELVM v) {
    sq_pushinteger(v, users_in_room);
    //log_printf("Users in room: %u\n", users_in_room.load());
    return 1;
}

SQInteger inc_users_in_room(HSQUIRRELVM v) {
    ++users_in_room;
    return 0;
}

SQInteger dec_users_in_room(HSQUIRRELVM v) {
    if (users_in_room) {
        --users_in_room;
    }
    return 0;
}

SQInteger is_punch_ip_available(HSQUIRRELVM v) {
    sq_pushbool(v, (SQBool)punch_ip_updated);
    return 1;
}

SQInteger get_punch_ip(HSQUIRRELVM v) {
    punch_ip_updated = false;
    sq_pushstring(v, punch_ip_buffer, -1);
    return 1;
}

SQInteger reset_punch_ip(HSQUIRRELVM v) {
    *punch_ip_buffer = '\0';
    punch_ip_len = 0;
    punch_ip_updated = false;
    return 0;
}

SQInteger copy_punch_ip(HSQUIRRELVM v) {
    OpenClipboard(NULL);
    EmptyClipboard();
    if (size_t punch_len = punch_ip_len) {
        ++punch_len;
        HGLOBAL clip_mem = GlobalAlloc(GMEM_MOVEABLE, punch_len);
        memcpy(GlobalLock(clip_mem), punch_ip_buffer, punch_len);
        GlobalUnlock(clip_mem);
        SetClipboardData(CF_TEXT, clip_mem);
    }
    CloseClipboard();
    return 0;
}

SQInteger update_delay(HSQUIRRELVM v){
    SQInteger delay;
    if (
        sq_gettop(v) == 2 &&
        SQ_SUCCEEDED(sq_getinteger(v, 2, &delay)))
    {
      latency = delay;
    }
    return 0;
}

SQInteger ignore_lobby_punch_ping(HSQUIRRELVM v) {
    respond_to_punch_ping = false;
    return 0;
}

SQInteger get_dev_mode(HSQUIRRELVM v) {
    sq_pushbool(v, (SQBool)get_dev_mode_enabled());
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

        sq_setcompilererrorhandler(v, [](HSQUIRRELVM v, const SQChar* desc, const SQChar* src, SQInteger line, SQInteger col) {
#if !DISABLE_ALL_LOGGING_FOR_BUILD
            log_printf(
                "Squirrel compiler exception: %s\n"
                "<%d,%d> \"%s\"\n",
                src,
                line, col, desc
            );
#else
            mboxf("Squirrel Exception", MB_OK | MB_ICONERROR, [=](auto add_text) {
                add_text(
                    "Squirrel compiler exception: %s\n"
                    "<%d,%d> \"%s\"\n",
                    src,
                    line, col, desc
                );
            });
#endif
        });
        sq_newclosure(v, [](HSQUIRRELVM v) -> SQInteger {
            if (sq_gettop(v) > 0) {
                const SQChar* error_msg;
                if (SQ_SUCCEEDED(sq_getstring(v, 2, &error_msg))) {
#if !DISABLE_ALL_LOGGING_FOR_BUILD
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
#else
                    mboxf("Squirrel Exception", MB_OK | MB_ICONERROR, [=](auto add_text) {
                        add_text("Squirrel runtime exception: \"%s\"\n", error_msg);
                        SQStackInfos sqstack;
                        for (
                            SQInteger i = 1;
                            SQ_SUCCEEDED(sq_stackinfos(v, i, &sqstack));
                            ++i
                        ) {
                            add_text(
                                *sqstack.source ? " %d | %s (%s)\n" : " %d | %s\n"
                                , sqstack.line, sqstack.funcname ? sqstack.funcname : "Anonymous function", sqstack.source
                            );
                        }
                    });
#endif
                }
            }
            return 0;
        }, 0);
        sq_seterrorhandler(v);

            // setting table setup
            sq_createtable(v, _SC("setting"), [](HSQUIRRELVM v) {
                sq_setinteger(v, _SC("version"), PLUGIN_VERSION);
                sq_setinteger(v, _SC("revision"), PLUGIN_REVISION);
                sq_createtable(v, _SC("misc"), [](HSQUIRRELVM v){
                    sq_setbool(v,_SC("hide_ip"), get_hide_ip_enabled());
                    sq_setbool(v, _SC("hide_wip"), get_hide_wip_enabled());
                    sq_setbool(v, _SC("hide_name"), get_hide_name_enabled());
                    //only add to config file if needed
                    sq_setbool(v, _SC("hide_lobby"), false);//more useful once we get custom lobbies
                    sq_setbool(v, _SC("skip_intro"), get_skip_intro_enabled());
                });
                sq_createtable(v, _SC("ping"), [](HSQUIRRELVM v) {
                    sq_setfunc(v, _SC("update_consts"), update_ping_constants);
                    set_ping_constants(v);
                });
                sq_createtable(v, _SC("input_display"), [](HSQUIRRELVM v) {
                    sq_setfunc(v, _SC("update_consts"), update_input_constants);
                    sq_createtable(v, _SC("p1"), set_inputp1_constants);
                    sq_createtable(v, _SC("p2"), set_inputp2_constants);
                });
            });

            // rollback table setup
            sq_createtable(v, _SC("rollback"), [](HSQUIRRELVM v) {
                sq_setfunc(v, _SC("update_delay"),update_delay);
                sq_setfunc(v, _SC("resyncing"), r_resync_get);
            });

            sq_createtable(v, _SC("punch"), [](HSQUIRRELVM v) {
                sq_setfunc(v, _SC("init_wait"), start_direct_punch_wait);
                sq_setfunc(v, _SC("init_connect"), start_direct_punch_connect);
                sq_setfunc(v, _SC("get_ip"), get_punch_ip);
                sq_setfunc(v, _SC("reset_ip"), reset_punch_ip);
                sq_setfunc(v, _SC("ip_available"), is_punch_ip_available);
                sq_setfunc(v, _SC("copy_ip_to_clipboard"), copy_punch_ip);
                sq_setfunc(v, _SC("ignore_ping"), ignore_lobby_punch_ping);
            });

            // debug table setup
            sq_createtable(v, _SC("debug"), [](HSQUIRRELVM v) {
                sq_setfunc(v, _SC("print"), sq_print);
                sq_setfunc(v, _SC("fprint"), sq_fprint);
                sq_setfunc(v, _SC("print_value"), sq_print_value);
                sq_setfunc(v, _SC("fprint_value"), sq_fprint_value);
                sq_setfunc(v, _SC("dev"), get_dev_mode);
            });

            // modifications to the manbow table
            sq_edit(v, _SC("manbow"), [](HSQUIRRELVM v) {
                sq_setfunc(v, _SC("compilebuffer"), sq_compile_buffer);
            });

            // custom lobby table
            sq_createtable(v, _SC("lobby"), [](HSQUIRRELVM v) {
                sq_setfunc(v, _SC("user_count"), get_users_in_room);
                sq_setfunc(v, _SC("inc_user_count"), inc_users_in_room);
                sq_setfunc(v, _SC("dec_user_count"), dec_users_in_room);
            });

            // discord rich presence

#if ENABLE_DISCORD_INTEGRATION
#define DISCORD_RPC_FUNC(field) \
[](HSQUIRRELVM v) -> SQInteger { \
    const SQChar* str; \
    if (sq_gettop(v) != 2 || SQ_FAILED(sq_getstring(v, 2, &str))) { \
        return sq_throwerror(v, "Invalid arguments, expected: <string>"); \
    } \
    MACRO_CAT(discord_rpc_set_,field)(str); \
    return 0; \
}
#else
#define DISCORD_RPC_FUNC(field) sq_dummy
#endif

            #define RPC_FIELD(field) \
                sq_setfunc(v, _SC("rpc_set_" MACRO_STR(field)), DISCORD_RPC_FUNC(field));

            sq_createtable(v, _SC("discord"), [](HSQUIRRELVM v) {
                RPC_FIELDS
                sq_setfunc(v, _SC("rpc_commit_details_and_state"),
#if ENABLE_DISCORD_INTEGRATION
                    [](HSQUIRRELVM v) -> SQInteger {
                        const SQChar* details;
                        const SQChar* state;
                        if (sq_gettop(v) != 3 || SQ_FAILED(sq_getstring(v, 2, &details)) || SQ_FAILED(sq_getstring(v, 3, &state))) {
                            return sq_throwerror(v, "Invalid arguments, expected: <string> <string>");
                        }
                        discord_rpc_set_details(details);
                        discord_rpc_set_state(state);
                        discord_rpc_commit();
                        return 0;
                    }
#else
                    sq_dummy
#endif
                );
                sq_setfunc(v, _SC("rpc_commit"), 
#if ENABLE_DISCORD_INTEGRATION
                    [](HSQUIRRELVM v) -> SQInteger {
                        discord_rpc_commit();
                        return 0;
                    }
#else
                    sq_dummy
#endif
                );
            });
            #undef RPC_FIELD

            //this changes the item array in the config menu :)
            //yes i know it's beautiful you don't have to tell me
            // sq_edit(v, _SC("menu"), [](HSQUIRRELVM v) {
            //     sq_edit(v, _SC("config"), [](HSQUIRRELVM v) {
            //         sq_edit(v, _SC("item"), [](HSQUIRRELVM v) {
            //             sq_pushstring(v, _SC("misc"), -1);
            //             if (SQ_SUCCEEDED(sq_arrayappend(v, -2))) {
            //                 log_printf("Succesfully added to array\n");
            //             }
            //         });
            //     });
            // });

            sq_pop(v, 1);
            return 1;
        }
        return -1;
    }

    dll_export int stdcall release_instance() {
        return 1;
    }

    dll_export int stdcall update_frame() {
        /*
        sq_pushroottable(v);

        //saving ::network.IsPlaying to a variable
        sq_edit(v, _SC("network"), [](HSQUIRRELVM v) {
            SQBool is_playing_sq;
            if (sq_readbool(v, _SC("IsPlaying"), &is_playing_sq)) {
                isplaying = is_playing_sq;
            }
        });

        sq_pop(v, 1);
        */

#if ALLOCATION_PATCH_TYPE != PATCH_NO_ALLOCS
        update_allocs();
#endif

        return 1;
    }

    dll_export int stdcall render_preproc() {
        return 0;
    }

    dll_export int stdcall render(int, int) {
        return 0;
    }
}