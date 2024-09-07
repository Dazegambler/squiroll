#include <string.h>
#include <limits.h>
#include <squirrel.h>

#include "util.h"
#include "AllocMan.h"
#include "Autopunch.h"
#include "PatchUtils.h"
#include "log.h"


const uintptr_t base_address = (uintptr_t)GetModuleHandleA(NULL);
uintptr_t libact_base_address = 0;

//SQVM Rx4DACE4 initialized at Rx124710
HSQUIRRELVM VM;

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

typedef void* thisfastcall act_script_plugin_load_t(
    void* self,
    thisfastcall_edx(int dummy_edx,)
    const char* plugin_path
);

void patch_se_libact(void* base_address);
void patch_se_lobby(void* base_address);
void patch_se_upnp(void* base_address);
void patch_se_information(void* base_address);
void patch_se_trust(void* base_address);

template <const uintptr_t& base, uintptr_t offset>
void* thisfastcall patch_act_script_plugin(
    void* self,
    thisfastcall_edx(int dummy_edx,)
    const char* plugin_path
) {
    void* base_address = based_pointer<act_script_plugin_load_t>(base, offset)(
        self,
        thisfastcall_edx(dummy_edx,)
        plugin_path
    );
    
    if (base_address) {
        if (!strcmp(plugin_path, "data/plugin/se_libact.dll")) {
            patch_se_libact(base_address);
        }
        else if (!strcmp(plugin_path, "data/plugin/se_lobby.dll")) {
            patch_se_lobby(base_address);
        }
        else if (!strcmp(plugin_path, "data/plugin/se_upnp.dll")) {
            patch_se_upnp(base_address);
        }
        else if (!strcmp(plugin_path, "data/plugin/se_information.dll")) {
            patch_se_information(base_address);
        }
        else if (!strcmp(plugin_path, "data/plugin/se_trust.dll")) {
            patch_se_trust(base_address);
        }
    }
    
    return base_address;
}

void patch_se_libact(void* base_address) {
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

    hotpatch_rel32(based_pointer(base_address, 0x15F7C), &patch_act_script_plugin<libact_base_address, 0x1CC60>);
}

void patch_se_lobby(void* base_address) {
#if ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(based_pointer(base_address, 0x41007), my_malloc);
    hotpatch_jump(based_pointer(base_address, 0x402F8), my_calloc);
    hotpatch_jump(based_pointer(base_address, 0x41055), my_realloc);
    hotpatch_jump(based_pointer(base_address, 0x40355), my_free);
    hotpatch_jump(based_pointer(base_address, 0x4DCF1), my_recalloc);
    hotpatch_jump(based_pointer(base_address, 0x53F76), my_msize);
#endif
}

void patch_se_upnp(void* base_address) {
#if ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(based_pointer(base_address, 0x1C4BB), my_malloc);
    hotpatch_jump(based_pointer(base_address, 0x21229), my_calloc);
    hotpatch_jump(based_pointer(base_address, 0x1C509), my_realloc);
    hotpatch_jump(based_pointer(base_address, 0x215AD), my_free);
    hotpatch_jump(based_pointer(base_address, 0x2D3BF), my_recalloc);
    hotpatch_jump(based_pointer(base_address, 0x32413), my_msize);
#endif
}

void patch_se_information(void* base_address) {
#if ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(based_pointer(base_address, 0x1B853), my_malloc);
    hotpatch_jump(based_pointer(base_address, 0x1BBE9), my_calloc);
    hotpatch_jump(based_pointer(base_address, 0x1B8A1), my_realloc);
    hotpatch_jump(based_pointer(base_address, 0x1BFAE), my_free);
    hotpatch_jump(based_pointer(base_address, 0x25FF0), my_recalloc);
    hotpatch_jump(based_pointer(base_address, 0x2B406), my_msize);
#endif
}

void patch_se_trust(void* base_address) {
#if ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(based_pointer(base_address, 0x5BA7), my_malloc);
    hotpatch_jump(based_pointer(base_address, 0x5C92), my_calloc);
    hotpatch_jump(based_pointer(base_address, 0x936E), my_realloc);
    hotpatch_jump(based_pointer(base_address, 0x5B6D), my_free);
    hotpatch_jump(based_pointer(base_address, 0x78AB), my_recalloc);
    hotpatch_jump(based_pointer(base_address, 0x933B), my_msize);
#endif

    static constexpr const uint8_t data[] = { 0x31, 0xC0 };
    mem_write(based_pointer(base_address, 0x15CC), data, sizeof(data));
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

#define sq_vm_init_call_addrA (0x00D6AD_R)
#define sq_vm_init_call_addrB (0x055EFA_R)
#define sq_vm_init_addr (0x024710_R)

#define patch_act_script_plugin_hook_addr (0x127ADC_R)

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
    hotpatch_jump(recalloc_base_addr, my_recalloc);
    hotpatch_jump(msize_base_addr, my_msize);
#endif
}
#pragma region netplay patch

#define resync_patch_addr (0x0E364C_R)
#define patchA_addr (0x0E357A_R)
#define wsasendto_import_addr (0x3884D4_R)
#define wsarecvfrom_import_addr (0x3884D8_R)
#define createmutex_patch_addr (0x01DC61_R)

struct PacketLayout {
	int8_t type;
	unsigned char data[];
};

static bool not_in_match = false
            ,resyncing = false;
static uint8_t lag_packets = 0;
static ULARGE_INTEGER prev_timestamp = {};

//resync_logic
//start
void resync_patch(uint8_t value){
    DWORD old_protect;
    uint8_t* patch_addr = (uint8_t*)resync_patch_addr;
	if (VirtualProtect(patch_addr, 1, PAGE_READWRITE, &old_protect)) {

		static constexpr uint8_t value_table[] = {
			5, 10, 15, INT8_MAX
		};

		*patch_addr = value_table[value / 32];

		VirtualProtect(patch_addr, 1, old_protect, &old_protect);
		FlushInstructionCache(GetCurrentProcess(), patch_addr, 1);
	}
}

void __fastcall run_resync_logic(ULARGE_INTEGER new_timestamp) {
	if (!resyncing) {
		if (
			// BUG (that probably isn't important):
			// Timestamp comparison should be checking QuadPart.
			// If the LowPart happens to be the same but not HighPart
			// then this will be detected as a duplicate timestamp
			prev_timestamp.LowPart != new_timestamp.LowPart &&
			prev_timestamp.HighPart != new_timestamp.HighPart
		) {
			lag_packets = 0;
		}
		else {
			if (++lag_packets >= UINT8_MAX) {
				resyncing = true;
				lag_packets = 0;
                //show message window displaying "resyncing" or something like it
			}
		}
		prev_timestamp = new_timestamp;
	} else {
		if (lag_packets > INT8_MAX) {
			resyncing = false;
			lag_packets = 0;
            //kill message window?
		}
		else {
            resync_patch(lag_packets);
			++lag_packets;
		}
	}
}


int WSAAPI my_WSASendTo(SOCKET s, LPWSABUF lpBuffers, DWORD dwBufferCount, LPDWORD lpNumberOfBytesSent, DWORD dwFlags, const sockaddr* lpTo, int iTolen, LPWSAOVERLAPPED lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine) {
	PacketLayout* packet = (PacketLayout*)lpBuffers[0].buf;

	switch (packet->type) {
		case 9:
			if (not_in_match) {
				if (lpNumberOfBytesSent) {
					*lpNumberOfBytesSent = 1;
				}
				return 0;
			}
			not_in_match = true;
			break;
		case 11:
			not_in_match = false;
			break;
		case 18:
			if (lpBuffers[0].len >= 25) {
				run_resync_logic(*(ULARGE_INTEGER*)&packet->data[16]);
			}
			break;
		case 19:
			if (lpBuffers[0].len >= 26) {
				run_resync_logic(*(ULARGE_INTEGER*)&packet->data[17]);
			}
			break;
	}

	return WSASendTo(s, lpBuffers, dwBufferCount, lpNumberOfBytesSent, dwFlags, lpTo, iTolen, lpOverlapped, lpCompletionRoutine);
}

int WSAAPI my_WSARecvFrom(SOCKET s, LPWSABUF lpBuffers, DWORD dwBufferCount, LPDWORD lpNumberOfBytesRecvd, LPDWORD lpFlags, sockaddr* lpFrom, LPINT lpFromLen, LPWSAOVERLAPPED lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine) {
	int ret = WSARecvFrom(s, lpBuffers, dwBufferCount, lpNumberOfBytesRecvd, lpFlags, lpFrom, lpFromLen, lpOverlapped, lpCompletionRoutine);

	PacketLayout* packet = (PacketLayout*)lpBuffers[0].buf;

	switch (packet->type) {
		case 1: case 2: case 3: case 4: case 5:
		case 6: case 7: case 8: case 9: case 10:
		case 11:
			not_in_match = false;
	}

	return ret;
}

void netplay_patch(){
    uint8_t data[] = {0x7F};
    mem_write((void*)patchA_addr,data,sizeof(data));//first netcode patch
    uint8_t data_mutexa[] = {0x6A,0x00,0x90,0x90,0x90};
    mem_write((void*)createmutex_patch_addr,data_mutexa,sizeof(data_mutexa));//mutex patch
    resync_patch(UINT8_MAX);
    hotpatch_import(wsarecvfrom_import_addr,my_WSARecvFrom);
    hotpatch_import(wsasendto_import_addr,my_WSASendTo);
}

#pragma endregion

BOOL my_ReadFile(
HANDLE       hFile,
LPVOID       lpBuffer,
DWORD        nNumberOfBytesToRead,
LPDWORD     lpNumberOfBytesRead,
LPOVERLAPPED lpOverlapped
){
    BOOL original = ReadFile(hFile,lpBuffer,nNumberOfBytesToRead,lpNumberOfBytesRead,lpOverlapped);
    if (!original){
        return FALSE;
    }
    
    return TRUE;
}

typedef HSQUIRRELVM (*sq_vm_init)(void);
sq_vm_init sq_vm_init_ptr = (sq_vm_init)sq_vm_init_addr;

#define update_addr (0x008F50_R)
typedef void (*update_test)(void);
update_test update_ptr = (update_test)update_addr;

HSQUIRRELVM my_sq_vm_init(){
    VM = sq_vm_init_ptr();
    return VM;
}

// Initialization code shared by th155r and thcrap use
// Executes before the start of the process
void common_init() {
#ifndef NDEBUG
    Debug();
#endif
    patch_allocman();

    netplay_patch();
    hotpatch_rel32(sq_vm_init_call_addrA,my_sq_vm_init);
    //hotpatch_rel32(sq_vm_init_call_addrB,my_sq_vm_init); //not sure why its called twice but pretty sure the first call is enough

    //patch_autopunch();
    
    //hotpatch_import(CreateFileA_import_addr,my_createfileA);

    //hotpatch_import(ReadFile_import_addr,my_readfile);

    //hotpatch_rel32(patch_act_script_plugin_hook_addr, &patch_act_script_plugin<base_address, 0x12DDD0>);

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