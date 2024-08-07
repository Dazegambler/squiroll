//#include <windows.h>
//#include <winuser.h>
//#include <stdint.h>
#include "AllocMan.h"
#include "Autopunch.h"
#include "PatchUtils.h"
#include <squirrel.h>

#include "util.h"

const uintptr_t base_address = (uintptr_t)GetModuleHandleA(NULL);

//SQVM Rx4DACE4 initialized at Rx124710
HSQUIRRELVM* VM;

void GetSqVM(){
    VM = (HSQUIRRELVM*)0x4DACE4_R; 
}

#define sq_vm_malloc_call_addr (0x186745_R)
#define sq_vm_realloc_call_addr (0x18675A_R)
#define sq_vm_free_call_addr (0x186737_R)

#define closesocketA_call_addr (0x170383_R)
#define closesocketB_call_addr (0x1703ee_R)
#define bind_call_addr (0x1702f4_R)
#define sendto_call_addr (0x170502_R)
#define recvfrom_call_addr (0x170e5b_R)


void Cleanup()
{
    autopunch_cleanup();
}

void Debug(){
    AllocConsole();
    auto a = freopen("CONIN$","r",stdin);
    a = freopen("CONOUT$","w",stdout);
    a = freopen("CONOUT$","w",stderr);
    SetConsoleTitleW(L"th155r debug");
}

void patch_autopunch(){
    hotpatch_rel32((void*)recvfrom_call_addr,(void*)my_recvfrom);
    hotpatch_rel32((void*)sendto_call_addr,(void*)my_sendto);
    hotpatch_rel32((void*)bind_call_addr,(void*)my_bind);
    hotpatch_rel32((void*)closesocketA_call_addr,(void*)my_closesocket);
    hotpatch_rel32((void*)closesocketB_call_addr,(void*)my_closesocket);

    autopunch_init();
}

void patch_allocman(){
    hotpatch_rel32((void*)sq_vm_malloc_call_addr, (void*)my_malloc);
    hotpatch_rel32((void*)sq_vm_realloc_call_addr, (void*)my_realloc);
    hotpatch_rel32((void*)sq_vm_free_call_addr, (void*)my_free);
}

// Initialization code shared by th155r and thcrap use
// Executes before the start of the process
void common_init() {
    Debug();
    //patch_allocman();
    //patch_autopunch();

}

void yes_tampering()
{
    static constexpr BYTE data[] = {0xC3};
    uintptr_t addrA = 0x12E820_R, addrB = 0x130630_R, addrC = 0x132AF0_R;
    mem_write((LPVOID)addrA, data, sizeof(data));
    mem_write((LPVOID)addrB, data, sizeof(data));
    mem_write((LPVOID)addrC, data, sizeof(data));
}

extern "C"
{
    // FUNCTION REQUIRED FOR THE LIBRARY
    // th155r init function
    __declspec(dllexport) int stdcall netcode_init(int32_t param)
    {
        yes_tampering();
        common_init();
        return 0;
    }
    
    // thcrap init function
    // Thcrap already removes the tamper protection,
    // so that code is unnecessary to include here.
    __declspec(dllexport) void cdecl netcode_mod_init(void* param) {
        common_init();
    }
    
    // thcrap plugin init
    __declspec(dllexport) int stdcall thcrap_plugin_init()
    {
        if (HMODULE thcrap_handle = GetModuleHandleA("thcrap.dll")) {
            if (auto runconfig_game_get = (const char*(*)())GetProcAddress(thcrap_handle, "runconfig_game_get")) {
                const char* game_str = runconfig_game_get();
                if (game_str && !strcmp(game_str, "th155")) {
                    return 0;
                }
            }
        }
        return 1;
    }
}

BOOL WINAPI DllMain(HINSTANCE hinst, DWORD dwReason, LPVOID reserved)
{
    if (dwReason == DLL_PROCESS_DETACH)
    {
        Cleanup();
    }
    return TRUE;
}