#include <string.h>

#include <squirrel.h>

#include "util.h"
#include "AllocMan.h"
#include "Autopunch.h"
#include "PatchUtils.h"
#include "CrashHandler.h"
#include "log.h"

const uintptr_t base_address = (uintptr_t)GetModuleHandleA(NULL);

//SQVM Rx4DACE4 initialized at Rx124710
HSQUIRRELVM* VM;

void GetSqVM(){
    VM = (HSQUIRRELVM*)0x4DACE4_R; 
}

void Cleanup() {
    autopunch_cleanup();
}

void Debug() {
    AllocConsole();
    (void)freopen("CONIN$","r",stdin);
    (void)freopen("CONOUT$","w",stdout);
    (void)freopen("CONOUT$","w",stderr);
    SetConsoleTitleW(L"th155r debug");
}

void patch_se_libact(void* base_address) {
#if ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(based_pointer(base_address, 0x134632), my_malloc);
    hotpatch_jump(based_pointer(base_address, 0x12C67B), my_calloc);
    hotpatch_jump(based_pointer(base_address, 0x13BD53), my_realloc);
    hotpatch_jump(based_pointer(base_address, 0x12C6D8), my_free);
    hotpatch_jump(based_pointer(base_address, 0x12C67B), my_recalloc);
    hotpatch_jump(based_pointer(base_address, 0x141C26), my_msize);
#endif
}

void patch_se_lobby(void* base_address) {
#if ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(based_pointer(base_address, 0x41007), my_malloc);
    hotpatch_jump(based_pointer(base_address, 0x402F8), my_calloc);
    hotpatch_jump(based_pointer(base_address, 0x41055), my_realloc);
    hotpatch_jump(based_pointer(base_address, 0x40355), my_free);
    hotpatch_jump(based_pointer(base_address, 0x4DCE6), my_recalloc);
    hotpatch_jump(based_pointer(base_address, 0x53F76), my_msize);
#endif
}

void patch_se_upnp(void* base_address) {
#if ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(based_pointer(base_address, 0x1C4BB), my_malloc);
    hotpatch_jump(based_pointer(base_address, 0x21229), my_calloc);
    hotpatch_jump(based_pointer(base_address, 0x1C509), my_realloc);
    hotpatch_jump(based_pointer(base_address, 0x215AD), my_free);
    hotpatch_jump(based_pointer(base_address, 0x2D3B4), my_recalloc);
    hotpatch_jump(based_pointer(base_address, 0x32413), my_msize);
#endif
}

void patch_se_information(void* base_address) {
#if ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(based_pointer(base_address, 0x1B853), my_malloc);
    hotpatch_jump(based_pointer(base_address, 0x1BBE9), my_calloc);
    hotpatch_jump(based_pointer(base_address, 0x1B8A1), my_realloc);
    hotpatch_jump(based_pointer(base_address, 0x1BFAE), my_free);
    hotpatch_jump(based_pointer(base_address, 0x25FE5), my_recalloc);
    hotpatch_jump(based_pointer(base_address, 0x2B406), my_msize);
#endif
}

void patch_se_trust(void* base_address) {
#if ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(based_pointer(base_address, 0x5BA7), my_malloc);
    hotpatch_jump(based_pointer(base_address, 0x5C92), my_calloc);
    hotpatch_jump(based_pointer(base_address, 0x936E), my_realloc);
    hotpatch_jump(based_pointer(base_address, 0x5B6D), my_free);
    hotpatch_jump(based_pointer(base_address, 0x78A0), my_recalloc);
    hotpatch_jump(based_pointer(base_address, 0x933B), my_msize);
#endif
}

#define sq_vm_malloc_call_addr (0x186745_R)
#define sq_vm_realloc_call_addr (0x18675A_R)
#define sq_vm_free_call_addr (0x186737_R)

#define malloc_base_addr (0x312D61_R)
#define calloc_base_addr (0x3122EA_R)
#define realloc_base_addr (0x312DAF_R)
#define free_base_addr (0x312347_R)
#define recalloc_addr (0x3182D4_R)
#define msize_addr (0x31ED30_R)

#define WSASend_import_addr (0x3884D0_R)
#define WSASendTo_import_addr (0x3884D4_R)
#define WSARecvFrom_import_addr (0x3884D8_R)
#define bind_import_addr (0x3884E0_R)
#define closesocket_import_addr (0x388514_R)

void patch_autopunch() {
    //hotpatch_import(WSARecvFrom_import_addr, my_WSARecvFrom);
    //hotpatch_import(WSASendTo_import_addr, my_WSASendTo);
    //hotpatch_import(WSASend_import_addr, my_WSASend);
    //hotpatch_import(bind_import_addr, my_bind);
    //hotpatch_import(closesocket_import_addr, my_closesocket);

    //autopunch_init();
}

void patch_allocman() {
#if ALLOCATION_PATCH_TYPE == PATCH_SQUIRREL_ALLOCS
    hotpatch_rel32(sq_vm_malloc_call_addr, my_malloc);
    hotpatch_rel32(sq_vm_realloc_call_addr, my_realloc);
    hotpatch_rel32(sq_vm_free_call_addr, my_free);
#elif ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(malloc_base_addr, my_malloc);
    hotpatch_jump(calloc_base_addr, my_calloc);
    hotpatch_jump(realloc_base_addr, my_realloc);
    hotpatch_jump(free_base_addr, my_free);
    hotpatch_jump(recalloc_addr, my_recalloc);
    hotpatch_jump(msize_addr, my_msize);
#endif
}

typedef void* thisfastcall act_script_plugin_GetProcAddress_t(
    void* self,
    thisfastcall_edx(int dummy_edx,)
    void* base_address,
    const char* func_name
);

#define act_script_plugin_GetProcAddress_addr (0x12E4F0_R)

#define patch_act_script_plugin_hook_addr (0x127AF9_R)

void* thisfastcall patch_act_script_plugin(
    void* self,
    thisfastcall_edx(int dummy_edx,)
    void* base_address,
    const char* func_name
) {
    const char* plugin_name = (const char*)stack_return_offset[8]; // SUPER JANK HACK
    
    if (!strcmp(plugin_name, "data/plugin/se_libact.dll")) {
        patch_se_libact(base_address);
    }
    else if (!strcmp(plugin_name, "data/plugin/se_lobby.dll")) {
        patch_se_lobby(base_address);
    }
    else if (!strcmp(plugin_name, "data/plugin/se_upnp.dll")) {
        patch_se_upnp(base_address);
    }
    else if (!strcmp(plugin_name, "data/plugin/se_information.dll")) {
        patch_se_information(base_address);
    }
    else if (!strcmp(plugin_name, "data/plugin/se_trust.dll")) {
        patch_se_trust(base_address);
    }
    
    return ((act_script_plugin_GetProcAddress_t*)act_script_plugin_GetProcAddress_addr)(
        self,
        thisfastcall_edx(dummy_edx,)
        base_address,
        func_name
    );
}

// Initialization code shared by th155r and thcrap use
// Executes before the start of the process
void common_init() {
#ifndef NDEBUG
    Debug();
#endif
    signal(SIGSEGV, signalHandler);
    signal(SIGABRT, signalHandler);
    signal(SIGFPE, signalHandler);
    signal(SIGILL, signalHandler);
    signal(SIGTERM, signalHandler);
    patch_allocman();
    //patch_autopunch();
    
    hotpatch_rel32(patch_act_script_plugin_hook_addr, patch_act_script_plugin);

}

void yes_tampering() {
    hotpatch_ret(0x12E820_R, 0);
    hotpatch_ret(0x130630_R, 0);
    hotpatch_ret(0x132AF0_R, 0);
}

extern "C" {
    // FUNCTION REQUIRED FOR THE LIBRARY
    // th155r init function
    dll_export int stdcall netcode_init(int32_t param) {
        yes_tampering();
        common_init();
        return 0;
    }
    
    // thcrap init function
    // Thcrap already removes the tamper protection,
    // so that code is unnecessary to include here.
    dll_export void cdecl netcode_mod_init(void* param) {
        common_init();
    }
    
    // thcrap plugin init
    dll_export int stdcall thcrap_plugin_init() {
        if (HMODULE thcrap_handle = GetModuleHandleA("thcrap.dll")) {
            if (auto runconfig_game_get = (const char*(*)())GetProcAddress(thcrap_handle, "runconfig_game_get")) {
                const char* game_str = runconfig_game_get();
                if (game_str && !strcmp(game_str, "th155")) {
                    if (printf_t* log_func = (printf_t*)GetProcAddress(thcrap_handle, "log_printf")) {
                        log_printf = log_func;
                    }
                    return 0;
                }
            }
        }
        return 1;
    }
}

BOOL WINAPI DllMain(HINSTANCE hinst, DWORD dwReason, LPVOID reserved) {
    if (dwReason == DLL_PROCESS_DETACH) {
        Cleanup();
    }
    return TRUE;
}