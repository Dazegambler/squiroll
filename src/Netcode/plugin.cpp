#include "TF4.h"
#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <squirrel.h>

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
#include "overlay.h"
#include "frame_data_display.h"
#include "rollback.h"

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
    sq_setbool(v, _SC("input_delay"), get_ping_frames());
}

static inline void set_inputp1_constants(HSQUIRRELVM v) {
    sq_setbool(v, _SC("enabled"), get_inputp1_enabled());
    sq_setinteger(v, _SC("X"), get_inputp1_x());
    sq_setinteger(v, _SC("Y"), get_inputp1_y());
    sq_setfloat(v, _SC("SX"), get_inputp1_scale_x());
    sq_setfloat(v, _SC("SY"), get_inputp1_scale_y());
    sq_setinteger(v, _SC("offset"), get_inputp1_offset());
    sq_setinteger(v, _SC("list_max"), get_inputp1_count());
    uint32_t color = get_inputp1_color();
    sq_setfloat(v, _SC("blue"), (float)(uint8_t)color / 255.0f);
    sq_setfloat(v, _SC("green"), (float)(uint8_t)(color >> 8) / 255.0f);
    sq_setfloat(v, _SC("red"), (float)(uint8_t)(color >> 16) / 255.0f);
    sq_setfloat(v, _SC("alpha"), (float)(uint8_t)(color >> 24) / 255.0f);
    int32_t timer = get_inputp1_timer();
    sq_setinteger(v, _SC("timer"), timer > 0 ? timer : 0);
    sq_setstring(v, _SC("notation"), get_inputp1_notation());
    sq_setbool(v, _SC("frame_count"), get_inputp1_frame_count());
}

static inline void set_inputp2_constants(HSQUIRRELVM v) {
    sq_setbool(v, _SC("enabled"), get_inputp2_enabled());
    sq_setinteger(v, _SC("X"), get_inputp2_x());
    sq_setinteger(v, _SC("Y"), get_inputp2_y());
    sq_setfloat(v, _SC("SX"), get_inputp2_scale_x());
    sq_setfloat(v, _SC("SY"), get_inputp2_scale_y());
    sq_setinteger(v, _SC("offset"), get_inputp2_offset());
    sq_setinteger(v, _SC("list_max"), get_inputp2_count());
    uint32_t color = get_inputp2_color();
    sq_setfloat(v, _SC("blue"), (float)(uint8_t)color / 255.0f);
    sq_setfloat(v, _SC("green"), (float)(uint8_t)(color >> 8) / 255.0f);
    sq_setfloat(v, _SC("red"), (float)(uint8_t)(color >> 16) / 255.0f);
    sq_setfloat(v, _SC("alpha"), (float)(uint8_t)(color >> 24) / 255.0f);
    int32_t timer = get_inputp2_timer();
    sq_setinteger(v, _SC("timer"), timer > 0 ? timer : 0);
    sq_setstring(v, _SC("notation"), get_inputp2_notation());
    sq_setbool(v, _SC("frame_count"),get_inputp2_frame_count());
}

static inline void set_frame_data_constants(HSQUIRRELVM v) {
    sq_setbool(v, _SC("enabled"), get_frame_data_enabled());
    sq_setbool(v, _SC("input_flags"), get_frame_data_flags());
    sq_setbool(v, _SC("frame_stepping"), get_frame_data_frame_stepping());
    sq_setbool(v, _SC("framebar"), get_frame_data_framebar());
    sq_setinteger(v, _SC("X"), get_frame_data_x());
    sq_setinteger(v, _SC("Y"), get_frame_data_y());
    sq_setfloat(v, _SC("SX"), get_frame_data_scale_x());
    sq_setfloat(v, _SC("SY"), get_frame_data_scale_y());
    uint32_t color = get_frame_data_color();
    sq_setfloat(v, _SC("blue"), (float)(uint8_t)color / 255.0f);
    sq_setfloat(v, _SC("green"), (float)(uint8_t)(color >> 8) / 255.0f);
    sq_setfloat(v, _SC("red"), (float)(uint8_t)(color >> 16) / 255.0f);
    sq_setfloat(v, _SC("alpha"), (float)(uint8_t)(color >> 24) / 255.0f);
    int32_t timer = get_frame_data_timer();
    sq_setinteger(v, _SC("timer"), timer > 0 ? timer : 0);
}

static inline void set_network_constants(HSQUIRRELVM v) {
    sq_setbool(v, _SC("hide_opponent_name"), get_hide_name_enabled());
    sq_setbool(v,_SC("hide_ip"), get_hide_ip_enabled());
    sq_setbool(v, _SC("share_watch_ip"), get_share_watch_ip_enabled());
    sq_setbool(v, _SC("hide_profile_pictures"), get_hide_profile_pictures_enabled());
    sq_setbool(v, _SC("auto_lobby_state_switch"), get_auto_switch());
    //only add to config file if needed
    //sq_setbool(v, _SC("hide_lobby"), false);//more useful once we get custom lobbies
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

SQInteger update_frame_data_constants(HSQUIRRELVM v) {
    sq_pushroottable(v);

    sq_edit(v, _SC("setting"), [](HSQUIRRELVM v) {
        sq_edit(v, _SC("frame_data"), set_frame_data_constants);
    });

    sq_pop(v, 1);
    return 0;
}

SQInteger update_network_constants(HSQUIRRELVM v) {
    sq_pushroottable(v);

    sq_edit(v, _SC("setting"),[](HSQUIRRELVM v){
        sq_edit(v, _SC("network"),set_network_constants);
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

static void set_clipboard(const char* str, size_t length) {
    OpenClipboard(NULL);
    EmptyClipboard();
    if (length) {
        ++length;
        HGLOBAL clip_mem = GlobalAlloc(GMEM_MOVEABLE, length);
        memcpy(GlobalLock(clip_mem), str, length);
        GlobalUnlock(clip_mem);
        SetClipboardData(CF_TEXT, clip_mem);
    }
    CloseClipboard();
}

SQInteger copy_punch_ip(HSQUIRRELVM v) {
    set_clipboard(punch_ip_buffer, punch_ip_len);
    return 0;
}

SQInteger copy_to_clipboard(HSQUIRRELVM v) {
    const SQChar* str;
    if (
        sq_gettop(v) == 2 &&
        SQ_SUCCEEDED(sq_getstring(v, 2, &str))
    ) {
        set_clipboard(str, strlen(str));
    }
    return 0;
}

SQInteger update_delay(HSQUIRRELVM v){
    SQInteger delay;
    if (
        sq_gettop(v) == 2 &&
        SQ_SUCCEEDED(sq_getinteger(v, 2, &delay))
    ) {
      latency = delay;
    }
    return 0;
}

SQInteger ignore_lobby_punch_ping(HSQUIRRELVM v) {
    respond_to_punch_ping = false;
    return 0;
}

// template<typename T>
// SQInteger ReceiveArray(HSQUIRRELVM v) {
//     if (sq_gettop(v) != 2 || 
//         sq_gettype(v, 2) != OT_ARRAY) {
//         return sq_throwerror(v, _SC("Expected one argument: array of MyClass instances"));
//     }

//     std::vector<T*> objects;

//     sq_push(v, 2);
//     sq_pushnull(v);
//     while (SQ_SUCCEEDED(sq_next(v, -2))) {
//         void* instance = nullptr;
//         sq_getinstanceup(v, -1, &instance, 0);
//         if (!instance) {
//             sq_pop(v, 4);
//             return sq_throwerror(v, _SC("Invalid MyClass instance in array"));
//         }
//         objects.emplace_back((T*)instance);
//         sq_pop(v, 2);
//     }
//     sq_pop(v, 1);
//     return 0;
// }


#define SQPUSH_BOOL_FUNC(val) [](HSQUIRRELVM v) -> SQInteger { sq_pushbool(v, (SQBool)(val)); return 1; }
#define SQPUSH_INT_FUNC(val) [](HSQUIRRELVM v) -> SQInteger { sq_pushinteger(v, (SQInteger)(val)); return 1; }
#define SQPUSH_FLOAT_FUNC(val) [](HSQUIRRELVM v) -> SQInteger { sq_pushfloat(v, (SQFloat)(val)); return 1; }

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
                sq_setfunc(v,_SC("save"),[](HSQUIRRELVM v) -> SQInteger {
                    const char* section;
                    const char* key;
                    const char* value;
                    if (sq_gettop(v) != 4 ||
                        SQ_FAILED(sq_getstring(v, 2, &section)) ||
                        SQ_FAILED(sq_getstring(v, 3, &key)) ||
                        SQ_FAILED(sq_getstring(v, 4, &value))
                    ) {
                        return sq_throwerror(v, "Invalid arguments, expected: <section> <key> <value>");
                    }
                    set_config_string(section,key,value);
                    return 0;
                });
                sq_createtable(v, _SC("misc"), [](HSQUIRRELVM v){
                    sq_setbool(v, _SC("hide_wip"), get_hide_wip_enabled());
                    sq_setbool(v, _SC("skip_intro"), get_skip_intro_enabled()); // This isn't a function because it only runs once anyway
                });
                sq_createtable(v, _SC("network"),[](HSQUIRRELVM v){
                    sq_setfunc(v, _SC("update_consts"), update_network_constants);
                    set_network_constants(v);
                });
                sq_createtable(v, _SC("ping"), [](HSQUIRRELVM v) {
                    sq_setfunc(v, _SC("update_consts"), update_ping_constants);
                    set_ping_constants(v);
                });
                sq_createtable(v, _SC("frame_data"), [](HSQUIRRELVM v) {
                    sq_setfunc(v, _SC("update_consts"), update_frame_data_constants);
                    sq_setfunc(v, _SC("IsFrameActive"), [](HSQUIRRELVM v) -> SQInteger {
                        void* inst;
                        void* p1;
                        void* p2;
                        if (sq_gettop(v) != 4 ||
                            SQ_FAILED(sq_getinstanceup(v, 2, &inst, nullptr)) ||
                            SQ_FAILED(sq_getinstanceup(v, 3, &p1, nullptr)) ||
                            SQ_FAILED(sq_getinstanceup(v, 4, &p2, nullptr))
                        ) {
                            return sq_throwerror(v, "Invalid arguments, expected: <group> <p1> <p2>");
                        }
                        sq_pushinteger(v, IsFrameActive((ManbowActor2DGroup*)inst,(ManbowActor2D*)p1,(ManbowActor2D*)p2));
                        return 1;
                    });
                    sq_setfunc(v, _SC("GetFrameCount"), [](HSQUIRRELVM v)-> SQInteger {
                        void* inst;
                        if (sq_gettop(v) != 2 ||
                            SQ_FAILED(sq_getinstanceup(v, 2, &inst, nullptr))){
                                return sq_throwerror(v, "Invalid arguments, expected: <player>");
                        }
                        sq_pushinteger(v, GetFrameCount((ManbowActor2D*)inst));
                        return 1;
                    });
                    sq_setfunc(v, _SC("GetMetadata"), [](HSQUIRRELVM v)-> SQInteger {
                        void* player;
                        if (sq_gettop(v) != 2 ||
                            SQ_FAILED((sq_getinstanceup(v, 2, &player, nullptr)))
                        ) {
                            return sq_throwerror(v, "Invalid arguments, expected: <player>");
                        }
                        uint16_t* metadata = GetMetadata((ManbowActor2D*)player);
                        sq_newarray(v, 0);
                        for(int i = 0; i <= 23; ++i){
                            sq_pushinteger(v, metadata[i]);
                            sq_arrayappend(v, -2);
                        }
                        return 1;
                    });
                    sq_setfunc(v, _SC("GetHitboxes"), [](HSQUIRRELVM v)-> SQInteger {
                        void* group;
                        if (sq_gettop(v) != 2 ||
                            SQ_FAILED(sq_getinstanceup(v, 2, &group, nullptr))
                        ) {
                            return sq_throwerror(v, "Invalid arguments, expected: <group>");
                        }
                        auto arr = GetHitboxes((ManbowActor2DGroup*)group);
                        sq_newarray(v, 0);
                        for(int i = 0;i<arr.size();i++){
                            sq_pushobject(v, (HSQOBJECT)arr[i]);
                            sq_arrayappend(v, -2);
                        }
                        return 1;
                    });
                    sq_setfunc(v, _SC("hasData"), [](HSQUIRRELVM v) -> SQInteger {
                        void* inst;
                        if (sq_gettop(v) != 2 ||
                            SQ_FAILED(sq_getinstanceup(v, 2, &inst, nullptr))
                        ) {
                            return sq_throwerror(v, "Invalid arguments, expected: <instance>");
                        }
                        sq_pushbool(v, hasData((ManbowActor2D*)inst));
                        return 1;
                    });
                    set_frame_data_constants(v);
                });
                sq_createtable(v, _SC("input_display"), [](HSQUIRRELVM v) {
                    sq_setfunc(v, _SC("update_consts"), update_input_constants);
                    sq_createtable(v, _SC("p1"), set_inputp1_constants);
                    sq_createtable(v, _SC("p2"), set_inputp2_constants);
                });
            });

            sq_createtable(v, _SC("math"),[](HSQUIRRELVM v) {
                sq_setfunc(v,_SC("clamp"),[](HSQUIRRELVM v) -> SQInteger {
                    SQFloat Val,minVal,maxVal;
                    if (sq_gettop(v) != 4 ||
                        SQ_FAILED(sq_getfloat(v, 2, &Val)) ||
                        SQ_FAILED(sq_getfloat(v, 3, &minVal)) ||
                        SQ_FAILED(sq_getfloat(v, 4, &maxVal)) 
                    ) {
                        return sq_throwerror(v, "Invalid arguments, expected: <Val> <minVal> <maxVal>");
                    }
                    SQFloat result = Val < minVal ? minVal : (Val > maxVal ? maxVal : Val);
                    sq_pushfloat(v, result);
                    return 1;
                });
                sq_setfunc(v, _SC("min"),[](HSQUIRRELVM v) -> SQInteger {
                    SQFloat a,b;
                    if (sq_gettop(v) != 3 ||
                        SQ_FAILED(sq_getfloat(v, 2, &a)) ||
                        SQ_FAILED(sq_getfloat(v, 3, &b)) 
                    ) {
                        return sq_throwerror(v, "Invalid arguments, expected: <a> <b>");
                    }
                    sq_getfloat(v, 2, &a);
                    sq_getfloat(v, 3, &b);

                    sq_pushfloat(v, a < b ? a : b);
                    return 1;
                });
                sq_setfunc(v, _SC("max"),[](HSQUIRRELVM v) -> SQInteger {
                    SQFloat a,b;
                    if (sq_gettop(v) != 3 ||
                        SQ_FAILED(sq_getfloat(v, 2, &a)) ||
                        SQ_FAILED(sq_getfloat(v, 3, &b)) 
                    ) {
                        return sq_throwerror(v, "Invalid arguments, expected: <a> <b>");
                    }
                    sq_getfloat(v, 2, &a);
                    sq_getfloat(v, 3, &b);

                    sq_pushfloat(v, a > b ? a : b);
                    return 1;
                });
            });

            // rollback table setup
            sq_createtable(v, _SC("rollback"), [](HSQUIRRELVM v) {
                sq_setfunc(v, _SC("update_delay"), update_delay);
                sq_setfunc(v, _SC("resyncing"), SQPUSH_BOOL_FUNC(resyncing));
                sq_setfunc(v, _SC("get_buffered_frames"), SQPUSH_INT_FUNC(local_buffered_frames));
                sq_setfunc(v, _SC("Reset"), [](HSQUIRRELVM v)-> SQInteger {
                    void* inst;
                    if (sq_gettop(v) != 2 ||
                        SQ_FAILED(sq_getinstanceup(v, 2, &inst, nullptr))){
                            return sq_throwerror(v, "Invalid arguments, expected: <group>");
                    }
                    Reset(v, (ManbowActor2DGroup*)inst);
                    return 0;
                });
                sq_setfunc(v, _SC("Tick"), [](HSQUIRRELVM v)-> SQInteger {
                    if (sq_gettop(v) != 1 ){
                            return sq_throwerror(v, "Invalid arguments, expected: none");
                    }
                    Tick();
                    return 0;
                });
                sq_setfunc(v, _SC("Undo"), [](HSQUIRRELVM v)-> SQInteger {
                    SQInteger frames;
                    if (sq_gettop(v) != 2 ||
                        SQ_FAILED(sq_getinteger(v, 2, &frames))){
                            return sq_throwerror(v, "Invalid arguments, expected: <frames>");
                    }
                    Undo(frames);
                    return 0;
                });
                sq_setfunc(v, _SC("Clear"), [](HSQUIRRELVM v)-> SQInteger {
                    if (sq_gettop(v) != 1 ){
                            return sq_throwerror(v, "Invalid arguments, expected: none");
                    }
                    Clear();
                    return 0;
                });
                sq_setfunc(v, _SC("TickA"), [](HSQUIRRELVM v)-> SQInteger {
                    if (sq_gettop(v) != 2 || 
                    sq_gettype(v, 2) != OT_ARRAY) {
                    return sq_throwerror(v, _SC("Invalid arguments, expected: <actor[]>"));
                    }
                
                    std::vector<ManbowActor2D*> actors;
                
                    sq_push(v, 2);
                    sq_pushnull(v);
                    while (SQ_SUCCEEDED(sq_next(v, -2))) {
                        void* instance;
                        sq_getinstanceup(v, -1, &instance, 0);
                        if (!instance) {
                            sq_pop(v, 4);
                            return sq_throwerror(v, _SC("Invalid class instance in array"));
                        }
                        actors.emplace_back((ManbowActor2D*)instance);
                        sq_pop(v, 2);
                    }
                    sq_pop(v, 1);
                    TickA(actors);
                    return 0;
                });
            });

            sq_createtable(v, _SC("punch"), [](HSQUIRRELVM v) {
                sq_setfunc(v, _SC("init_wait"), start_direct_punch_wait);
                sq_setfunc(v, _SC("init_connect"), start_direct_punch_connect);
                sq_setfunc(v, _SC("get_ip"), get_punch_ip);
                sq_setfunc(v, _SC("reset_ip"), reset_punch_ip);
                sq_setfunc(v, _SC("ip_available"), SQPUSH_BOOL_FUNC(punch_ip_updated));
                sq_setfunc(v, _SC("copy_ip_to_clipboard"), copy_punch_ip);
                sq_setfunc(v, _SC("ignore_ping"), ignore_lobby_punch_ping);
            });

            // debug table setup
            sq_createtable(v, _SC("debug"), [](HSQUIRRELVM v) {
                sq_setfunc(v, _SC("print"), sq_print);
                sq_setfunc(v, _SC("fprint"), sq_fprint);
                sq_setfunc(v, _SC("print_value"), sq_print_value);
                sq_setfunc(v, _SC("fprint_value"), sq_fprint_value);
                sq_setfunc(v, _SC("dev"), SQPUSH_BOOL_FUNC(get_dev_mode_enabled()));
                sq_setfunc(v, _SC("hash"), [](HSQUIRRELVM v) -> SQInteger {
                    if (sq_gettop(v) != 2)
                        return sq_throwerror(v, _SC("Invalid arguments, expected: <object>"));
                
                    SQHash h = sq_gethash(v, 2);
                    sq_pushinteger(v, (SQInteger)h);
                    return 1;
                });
                sq_setfunc(v, _SC("test"), [](HSQUIRRELVM v) -> SQInteger {
                    void* player;
                    if (sq_gettop(v) != 2 ||
                        SQ_FAILED(sq_getinstanceup(v, 2, &player, nullptr))
                    ) {
                        return sq_throwerror(v, "Invalid arguments, expected: <player>");
                    }
                    debug((ManbowActor2D*)player);
                    return 0;
                });
            });

            // modifications to the manbow table
            sq_edit(v, _SC("manbow"), [](HSQUIRRELVM v) {
                sq_setfunc(v, _SC("compilebuffer"), sq_compile_buffer);
                sq_setfunc(v, _SC("LoadCSVBuffer"), loadCSVBuffer);
                sq_setfunc(v, _SC("SetClipboardString"), copy_to_clipboard);
            });

            // custom lobby table
            sq_createtable(v, _SC("lobby"), [](HSQUIRRELVM v) {
                sq_setfunc(v, _SC("user_count"), SQPUSH_INT_FUNC(users_in_room));
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

            // custom render overlays
            sq_createtable(v, _SC("overlay"), [](HSQUIRRELVM v) {
                sq_setfunc(v, _SC("set_hitboxes"), [](HSQUIRRELVM v) -> SQInteger {
                    void* inst;
                    SQInteger p1_flags;
                    SQInteger p2_flags;
                    if (sq_gettop(v) != 4 ||
                        SQ_FAILED(sq_getinstanceup(v, 2, &inst, nullptr)) ||
                        SQ_FAILED(sq_getinteger(v, 3, &p1_flags)) ||
                        SQ_FAILED(sq_getinteger(v, 4, &p2_flags))
                    ) {
                        return sq_throwerror(v, "Invalid arguments, expected: <instance> <integer> <integer>");
                    }
                    overlay_set_hitboxes((ManbowActor2DGroup*)inst, p1_flags, p2_flags);
                    return 0;
                });
                sq_setfunc(v, _SC("clear"), [](HSQUIRRELVM v) -> SQInteger {
                    overlay_clear();
                    return 0;
                });
            });
            overlay_init();

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
        overlay_destroy();
        config_watcher_stop();
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

        config_watcher_check();

        return 1;
    }

    dll_export int stdcall render_preproc() {
        return 0;
    }

    dll_export int stdcall render(int, int) {
        overlay_draw();
        return 0;
    }
}