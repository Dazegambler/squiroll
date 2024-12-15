#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <string.h>
#include <limits.h>
#include <string>
#include <vector>

#include "netcode.h"
#include "util.h"
#include "alloc_man.h"
#include "patch_utils.h"
#include "log.h"
#include "file_replacement.h"
#include "config.h"
#include "lobby.h"
#include "better_game_loop.h"
#include "discord.h"

#include <shared.h>

using namespace std::literals::string_literals;
using namespace std::literals::string_view_literals;

#if !MINGW_COMPAT
#pragma comment (lib, "Ws2_32.lib")
#endif

const uintptr_t base_address = (uintptr_t)GetModuleHandleA(NULL);
uintptr_t libact_base_address = 0;

uint64_t qpc_second_frequency;
uint64_t qpc_frame_frequency;
uint64_t qpc_milli_frequency;
uint64_t qpc_micro_frequency;

/*
void Cleanup() {
}
*/

struct ScriptAPI {
    uint8_t dummy[0xF8];
    bool load_plugins_from_pak;
};

static const auto patch_se_upnp = [](void* base_address) {
#if ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(based_pointer(base_address, 0x1C4BB), my_malloc);
    hotpatch_jump(based_pointer(base_address, 0x21229), my_calloc);
    hotpatch_jump(based_pointer(base_address, 0x1C509), my_realloc);
    hotpatch_jump(based_pointer(base_address, 0x215AD), my_free);
    hotpatch_jump(based_pointer(base_address, 0x2D3BF), my_recalloc);
    hotpatch_jump(based_pointer(base_address, 0x32413), my_msize);
#endif
};

static auto patch_se_information = [](void* base_address) {
#if ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(based_pointer(base_address, 0x1B853), my_malloc);
    hotpatch_jump(based_pointer(base_address, 0x1BBE9), my_calloc);
    hotpatch_jump(based_pointer(base_address, 0x1B8A1), my_realloc);
    hotpatch_jump(based_pointer(base_address, 0x1BFAE), my_free);
    hotpatch_jump(based_pointer(base_address, 0x25FF0), my_recalloc);
    hotpatch_jump(based_pointer(base_address, 0x2B406), my_msize);
#endif

    // Timeout for update to prevent lag on main menu
    // Currently removed completely via squirrel instead
    //mem_write(based_pointer(base_address, 0xED3B), 10000);
};

static auto patch_se_trust = [](void* base_address) {
#if ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    //hotpatch_jump(based_pointer(base_address, 0x5BA7), my_malloc);
    //hotpatch_jump(based_pointer(base_address, 0x5C92), my_calloc);
    //hotpatch_jump(based_pointer(base_address, 0x936E), my_realloc);
    //hotpatch_jump(based_pointer(base_address, 0x5B6D), my_free);
    //hotpatch_jump(based_pointer(base_address, 0x78AB), my_recalloc);
    //hotpatch_jump(based_pointer(base_address, 0x933B), my_msize);
#endif

    /*
    static constexpr const uint8_t data[] = {
        0xB8, 0x01, 0x00, 0x00, 0x00,   // MOV EAX, 1
        0xC3,                           // RET
        0xCC                            // INT3
    };
    mem_write(based_pointer(base_address, 0x13C0), data);
    */
};

typedef void* thisfastcall act_script_plugin_load_t(
    void* self,
    thisfastcall_edx(int dummy_edx, )
    const char* plugin_path
);

void* thisfastcall patch_act_script_plugin(
    void* self,
    thisfastcall_edx(int dummy_edx,)
    const char* plugin_path
) {
    void* base_address = based_pointer<act_script_plugin_load_t>(libact_base_address, 0x1CC60)(
        self,
        thisfastcall_edx(dummy_edx,)
        plugin_path
    );

    if (base_address) {
        log_printf("Applying patches for \"%s\" at %p from ACT\n", plugin_path, base_address);
        if (!strcmp(plugin_path, "data/plugin/se_lobby.dll")) {
            patch_se_lobby(base_address);
            goto plugin_load_end;
        }
        if constexpr (!IS_CONSTEXPR(patch_se_upnp(nullptr))) {
            if (!strcmp(plugin_path, "data/plugin/se_upnp.dll")) {
                patch_se_upnp(base_address);
                goto plugin_load_end;
            }
        }
        if constexpr (!IS_CONSTEXPR(patch_se_information(nullptr))) {
            if (!strcmp(plugin_path, "data/plugin/se_information.dll")) {
                patch_se_information(base_address);
                goto plugin_load_end;
            }
        }
        if constexpr (!IS_CONSTEXPR(patch_se_trust(nullptr))) {
            if (!strcmp(plugin_path, "data/plugin/se_trust.dll")) {
                patch_se_trust(base_address);
                goto plugin_load_end;
            }
        }
    }

plugin_load_end:
    return base_address;
}

static void patch_se_libact(void* base_address) {
    libact_base_address = (uintptr_t)base_address;

#if ALLOCATION_PATCH_TYPE == PATCH_SQUIRREL_ALLOCS
    //hotpatch_rel32(based_pointer(base_address, 0xC4BE5), my_malloc);
    //hotpatch_rel32(based_pointer(base_address, 0xC4C89), my_realloc);
    //hotpatch_rel32(based_pointer(base_address, 0xC4C75), my_free);
#elif ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(based_pointer(base_address, 0x134632), my_malloc);
    hotpatch_jump(based_pointer(base_address, 0x12C67B), my_calloc);
    hotpatch_jump(based_pointer(base_address, 0x13BD53), my_realloc);
    hotpatch_jump(based_pointer(base_address, 0x12C6D8), my_free);
    hotpatch_jump(based_pointer(base_address, 0x138F44), my_recalloc);
    hotpatch_jump(based_pointer(base_address, 0x141C26), my_msize);
#endif

    hotpatch_rel32(based_pointer(base_address, 0x15F7C), patch_act_script_plugin);
};

#define load_plugin_from_pak_addr (0x12DDD0_R)

void* thisfastcall patch_exe_script_plugin(
    void* self,
    thisfastcall_edx(int dummy_edx,)
    const char* plugin_path
) {
    void* base_address = ((act_script_plugin_load_t*)load_plugin_from_pak_addr)(
        self,
        thisfastcall_edx(dummy_edx,)
        plugin_path
    );

    if (base_address) {
        log_printf("Applying patches for \"%s\" at %p from EXE\n", plugin_path, base_address);
        if (!strcmp(plugin_path, "data/plugin/se_libact.dll")) {
            patch_se_libact(base_address);
            goto plugin_load_end;
        }
        if (!strcmp(plugin_path, "data/plugin/se_lobby.dll")) {
            patch_se_lobby(base_address);
            goto plugin_load_end;
        }
        if constexpr (!IS_CONSTEXPR(patch_se_upnp(nullptr))) {
            if (!strcmp(plugin_path, "data/plugin/se_upnp.dll")) {
                patch_se_upnp(base_address);
                goto plugin_load_end;
            }
        }
        if constexpr (!IS_CONSTEXPR(patch_se_information(nullptr))) {
            if (!strcmp(plugin_path, "data/plugin/se_information.dll")) {
                patch_se_information(base_address);
                goto plugin_load_end;
            }
        }
        if constexpr (!IS_CONSTEXPR(patch_se_trust(nullptr))) {
            if (!strcmp(plugin_path, "data/plugin/se_trust.dll")) {
                patch_se_trust(base_address);
                goto plugin_load_end;
            }
        }
    }
    else {
        if (!strcmp(plugin_path, "data/plugin\\data/plugin/se_libact.dll.dll")) {
            base_address = (void*)GetModuleHandleW(L"Netcode.dll");
        }
    }

plugin_load_end:
    return base_address;
}

#define sq_vm_malloc_call_addr (0x186745_R)
#define sq_vm_realloc_call_addr (0x18675A_R)
#define sq_vm_free_call_addr (0x186737_R)

#define malloc_base_addr (0x312D61_R)
#define calloc_base_addr (0x3122EA_R)
#define realloc_base_addr (0x312DAF_R)
#define free_base_addr (0x312347_R)
#define recalloc_base_addr (0x3182DF_R)
#define msize_base_addr (0x31ED30_R)

#define WSASend_import_addr (0x3884D0_R)
#define WSASendTo_import_addr (0x3884D4_R)
#define WSARecvFrom_import_addr (0x3884D8_R)
#define bind_import_addr (0x3884E0_R)
#define closesocket_import_addr (0x388514_R)

#define patch_act_script_plugin_hook_addr (0x127ADC_R)

#define createmutex_patch_addr (0x01DC61_R)

// Basic thcrap style replacement mode
#define file_replacement_hook_addrA (0x23FAA_R)
#define file_replacement_read_addrA (0x2DFA1_R)
#define file_replacement_read_addrB (0x2DFED_R)
#define CloseHandle_import_addr (0x3881DC_R)

// No encryption replacement mode
#define file_replacement_hook_addrB (0x23F98_R)

#define load_th155_pak_call_addr (0x1DE1E_R)
#define load_th155b_pak_call_addr (0x1DE79_R)
#define parse_archive_addr (0x25420_R)
#define rsa_decrypt_addr (0x26940_R)

#define IsProcessorFeaturePresent_import_addr (0x388308_R)

static void patch_sockets() {
#if (NETPLAY_PATCH_TYPE == NETPLAY_DISABLE) && (CONNECTION_LOGGING & CONNECTION_LOGGING_UDP_PACKETS)
    hotpatch_icall(0x170501_R, WSASendTo_log);
#endif

    hotpatch_icall(0x1702F3_R, bind_inherited_socket);
    hotpatch_icall(0x170641_R, inherit_punch_socket);
    hotpatch_icall(0x170382_R, close_punch_socket);
    hotpatch_icall(0x1703ED_R, close_punch_socket);

    // This regular send call looks unused, so
    // just break it and see if anything dies.
    mem_write(0x17045A_R, INT3_BYTES);

    //mem_write(0x1709C7_R, INT3_BYTES);
    //mem_write(0x170F44_R, INT3_BYTES);
}

static void patch_allocman() {
#if ALLOCATION_PATCH_TYPE == PATCH_SQUIRREL_ALLOCS
    hotpatch_rel32(sq_vm_malloc_call_addr, my_malloc);
    hotpatch_rel32(sq_vm_realloc_call_addr, my_realloc);
    hotpatch_rel32(sq_vm_free_call_addr, my_free);
#elif ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(malloc_base_addr, my_malloc);
    hotpatch_jump(calloc_base_addr, my_calloc);
    hotpatch_jump(realloc_base_addr, my_realloc);
    hotpatch_jump(free_base_addr, my_free);
    hotpatch_jump(recalloc_base_addr, my_recalloc);
    hotpatch_jump(msize_base_addr, my_msize);
#endif
}

#if FILE_REPLACEMENT_TYPE != FILE_REPLACEMENT_NONE
static void patch_file_loading() {

#if FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_BASIC_THCRAP
    hotpatch_call(file_replacement_hook_addrA, file_replacement_hook);

    static constexpr uint8_t patch[] = { 0xE9, 0x8C, 0x00, 0x00, 0x00, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC };
    mem_write(file_replacement_hook_addrA + 5, patch);

    hotpatch_icall(file_replacement_read_addrA, file_replacement_read);
    hotpatch_icall(file_replacement_read_addrB, file_replacement_read);

    hotpatch_import(CloseHandle_import_addr, close_handle_hook);

#elif FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_NO_CRYPT

    hotpatch_call(file_replacement_hook_addrB, file_replacement_hook);

    static constexpr uint8_t patch[] = {
        0x85, 0xD2,                         // TEST EDX, EDX
        0x0F, 0x85, 0xBF, 0x00, 0x00, 0x00, // JNZ Rx24064
        0x0F, 0x1F, 0x44, 0x00, 0x00        // NOP
    };
    mem_write(file_replacement_hook_addrB + 5, patch);

#endif

}
#endif

static inline void disable_original_game_logging() {
    hotpatch_ret(0x25270_R, 0);
}

typedef bool thisfastcall parse_archive_t(
    void* self,
    thisfastcall_edx(int dummy_edx, )
    const char* filename,
    void* idk
);

static uint8_t* rsa_cache = nullptr;
static uint8_t* rsa_cache_cur = nullptr;
static uint8_t* rsa_cache_end = nullptr;
static char cache_path[MAX_PATH];
static FILE* cache_write_file = nullptr;

[[noreturn]] static void cache_corrupt() {
    DeleteFileW(L"th155.pak.cache");
    DeleteFileW(L"th155b.pak.cache");
    MessageBoxA(NULL, "The RSA cache seems to be corrupt or outdated.\nPlease restart your game.", "squiroll", MB_ICONERROR);
    ExitProcess(1);
}

static bool thisfastcall parse_archive_hook(void* self, thisfastcall_edx(int dummy_edx,) const char* filename, void* idk) {
    snprintf(cache_path, sizeof(cache_path), "%s.cache", filename);
    FILE* cache_file = fopen(cache_path, "rb");
    if (expect(cache_file != NULL, true)) {
        fseek(cache_file, 0, SEEK_END);
        size_t rsa_cache_len = ftell(cache_file);
        rewind(cache_file);
        rsa_cache_cur = rsa_cache = (uint8_t*)malloc(rsa_cache_len);
        rsa_cache_end = rsa_cache + rsa_cache_len;
        fread(rsa_cache, 1, rsa_cache_len, cache_file);
        fclose(cache_file);
        cache_file = NULL;
    } else {
        cache_write_file = cache_file = fopen(cache_path, "wb");
    }

    bool ret = ((parse_archive_t*)parse_archive_addr)(self, thisfastcall_edx(dummy_edx,) filename, idk);

    if (expect(!cache_file, true)) {
        if (expect(rsa_cache_cur != rsa_cache_end, false)) {
            log_printf("%s didn't use the whole cache! 0x%zX vs 0x%zX\n", filename, (size_t)(rsa_cache_cur - rsa_cache), (size_t)(rsa_cache_end - rsa_cache));
            cache_corrupt();
        }
        free(rsa_cache);
        rsa_cache = nullptr;
        rsa_cache_cur = nullptr;
        rsa_cache_end = nullptr;
    } else {
        fclose(cache_file);
        cache_write_file = nullptr;
    }
    return ret;
}

typedef int thisfastcall rsa_decrypt_t(
    void* self,
    thisfastcall_edx(int dummy_edx, )
    void* src,
    void* dst
);

static int thisfastcall rsa_decrypt_hook(void* self, thisfastcall_edx(int dummy_edx,) void* src, void* dst) {
    FILE* cache_file = cache_write_file;
    if (expect(!cache_file, true)) {
        if (expect(rsa_cache_cur + 0x40 > rsa_cache_end, false)) {
            log_printf("%s is truncated!\n", cache_path);
            cache_corrupt();
        }
        memcpy(dst, rsa_cache_cur, 0x40);
        rsa_cache_cur += 0x40;
    } else {
        memset(dst, 0, 0x40); // rsa_decrypt doesn't always fill the whole buffer because src is padded
        if (((rsa_decrypt_t*)rsa_decrypt_addr)(self, thisfastcall_edx(dummy_edx, ) src, dst) == -1) {
            return -1;
        }
        fwrite(dst, 0x40, 1, cache_file);
    }
    return 0;
}

static void patch_archive_parsing() {
    hotpatch_rel32(load_th155_pak_call_addr, parse_archive_hook);
    hotpatch_rel32(load_th155b_pak_call_addr, parse_archive_hook);

    static constexpr uintptr_t rsa_decrypt_calls[] = { 0x25874, 0x258F7, 0x25954, 0x259EC, 0x25DCE, 0x25E49, 0x25E81, 0x25EB0 };

    uintptr_t base = base_address;
    nounroll for (size_t i = 0; i < countof(rsa_decrypt_calls); ++i) {
        hotpatch_rel32(based_pointer(base, rsa_decrypt_calls[i]), rsa_decrypt_hook);
    }
}

static BOOL __stdcall IsProcessorFeaturePresent_hook(DWORD ProcessorFeature) {
    if (ProcessorFeature == PF_FASTFAIL_AVAILABLE)
        return FALSE;
    return IsProcessorFeaturePresent(ProcessorFeature);
}

static void cdecl parse_command_line(const char* str) {
    //log_printf("Command line: \"%s\"\n", str);
    switch (str[0]) {
        case 'w': case 'W':
            log_printf("Watch from boot \"%s\"\n", str + 1);
            break;
        case 'c': case 'C':
            log_printf("Connect from boot \"%s\"\n", str + 1);
            break;
    }
}

// Initialization code shared by th155r and thcrap use
// Executes before the start of the process
bool common_init(
#if !DISABLE_ALL_LOGGING_FOR_BUILD
    LogType log_type
#endif
) {
    init_config_file();

    if (expect(GAME_VERSION != 1211, false)) {
        return false;
    }

#if !DISABLE_ALL_LOGGING_FOR_BUILD
    if (log_type != NO_LOGGING) {
        enable_debug_console(log_type == LOG_TO_PARENT_CONSOLE);
        patch_throw_logs();
    }
    else {
        log_printf = printf_dummy;
        log_fprintf = fprintf_dummy;
#if !ALWAYS_DISABLE_ORIGINAL_GAME_LOGGING
        // Disable the original game's printf use
        // when logging is disabled
        disable_original_game_logging();
#endif
    }
#endif

#if !DISABLE_ALL_LOGGING_FOR_BUILD || ALWAYS_DISABLE_ORIGINAL_GAME_LOGGING
    disable_original_game_logging();
#endif

    hotpatch_rel32(0x1DC5A_R, parse_command_line);

    // Turn off scroll lock to simplify static management for the toggle func
    SetScrollLockState(false);

    patch_allocman();

    // Allow launching multiple instances of the game
    mem_write(createmutex_patch_addr, PATCH_BYTES<0x68, 0x00, 0x00, 0x00, 0x00>); //mutex patch

    patch_netplay();

    LARGE_INTEGERX qpc_freq;
    QueryPerformanceFrequency(&qpc_freq);

    qpc_second_frequency = (uint64_t)qpc_freq;
    qpc_frame_frequency = (uint64_t)qpc_freq / 60; // frames per second
    qpc_milli_frequency = (uint64_t)qpc_freq / 1000; // millisecond per second
    qpc_micro_frequency = (uint64_t)qpc_freq / 1000000; // microsecond per second

    patch_sockets();

    hotpatch_rel32(patch_act_script_plugin_hook_addr, patch_exe_script_plugin);

    //mem_write(0x1DEAD_R, INFINITE_LOOP_BYTES); // Replaces a TEST ECX, ECX

#if FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_NO_CRYPT
    patch_file_loading();
#endif

    if (get_cache_rsa_enabled()) {
        patch_archive_parsing();
    }

    // Disable fastfail to allow exception handlers to catch more crashes
    hotpatch_import(IsProcessorFeaturePresent_import_addr, IsProcessorFeaturePresent_hook);

    if (get_better_game_loop_enabled()) {
        init_better_game_loop();
    }

#if ENABLE_DISCORD_RICH_PRESENCE
    if ()
    discord_rpc_start();
    discord_rpc_set_large_img_key("mainicon");
    discord_rpc_set_details("Idle");
    discord_rpc_commit();
#endif

    return true;
}

static void yes_tampering() {
    static constexpr uintptr_t tamper_patch_addrs[] = {
        0x12E820,
        //0x130630,
        0x132AF0
    };
    
    uintptr_t base = base_address;
    nounroll for (size_t i = 0; i < countof(tamper_patch_addrs); ++i) {
        hotpatch_ret(based_pointer(base, tamper_patch_addrs[i]), 0);
    }
}

typedef BOOL cdecl globalconfig_get_boolean_t(const char* key, const BOOL default_value);

#if !DISABLE_ALL_LOGGING_FOR_BUILD
static bool enable_thcrap_console = false;
#endif

extern "C" {
    // FUNCTION REQUIRED FOR THE LIBRARY
    // th155r init function
    dll_export int stdcall netcode_init(InitFuncData* init_data) {
        if (
            common_init(
#if !DISABLE_ALL_LOGGING_FOR_BUILD
                init_data->log_type
#endif
            )
        ) {
            yes_tampering();
#if FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_BASIC_THCRAP
            patch_file_loading();
#endif
            return 0;
        }
        return 1;
    }
    
    // thcrap init function
    // Thcrap already removes the tamper protection,
    // so that code is unnecessary to include here.
    dll_export void cdecl netcode_mod_init(void* param) {
        common_init(
#if !DISABLE_ALL_LOGGING_FOR_BUILD
            enable_thcrap_console ? LOG_TO_PARENT_CONSOLE : NO_LOGGING
#endif
        );
    }
    
    // thcrap plugin init
    dll_export int stdcall thcrap_plugin_init() {
        if (HMODULE thcrap_handle = GetModuleHandleW(L"thcrap.dll")) {
            if (auto runconfig_game_get = (const char*(*)())GetProcAddress(thcrap_handle, "runconfig_game_get")) {
                const char* game_str = runconfig_game_get();
                if (game_str && !strcmp(game_str, "th155")) {
#if !DISABLE_ALL_LOGGING_FOR_BUILD
                    if (printf_t* log_func = (printf_t*)GetProcAddress(thcrap_handle, "log_printf")) {
                        log_printf = log_func;
                    }
#endif
                    if (mbox_t* log_func = (mbox_t*)GetProcAddress(thcrap_handle, "log_mbox")) {
                        log_mbox = log_func;
                    }
                    //if (patchhook_register_t* patchhook_register_func = (patchhook_register_t*)GetProcAddress(thcrap_handle, "patchhook_register")) {
                        //patchhook_register = patchhook_register_func;
                    //}
#if !DISABLE_ALL_LOGGING_FOR_BUILD
                    if (globalconfig_get_boolean_t* globalconfig_get_boolean = (globalconfig_get_boolean_t*)GetProcAddress(thcrap_handle, "globalconfig_get_boolean")) {
                        enable_thcrap_console = globalconfig_get_boolean("console", false);
                    }
#endif
                    return 0;
                }
            }
        }
        return 1;
    }
}

BOOL WINAPI DllMain(HINSTANCE hinst, DWORD dwReason, LPVOID reserved) {
    if (dwReason == DLL_PROCESS_DETACH) {
        //Cleanup();
    }
    return TRUE;
}