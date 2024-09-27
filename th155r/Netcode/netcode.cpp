

#include <winsock2.h>
#include <windows.h>
#include <squirrel.h>

#include "util.h"
#include "PatchUtils.h"
#include "fake_lag.h"
#include "netcode.h"
#include "log.h"
#include "lobby.h"
#include "config.h"

#define resync_patch_addr (0x0E364C_R)
#define patchA_addr (0x0E357A_R)
#define wsasendto_import_addr (0x3884D4_R)
#define wsarecvfrom_import_addr (0x3884D8_R)

struct PacketLayout {
    int8_t type;
    unsigned char data[];
};

static bool not_in_match = true;
SQBool resyncing = SQFalse;
SQBool isplaying = SQFalse;
static uint8_t lag_packets = 0;
static uint64_t prev_timestamp = 0;

static inline constexpr uint8_t RESYNC_THRESHOLD = UINT8_MAX;
static inline constexpr uint8_t RESYNC_DURATION = UINT8_MAX;

/*
TO FIX:
1.crash after attempting to host/connect
after connection loss due to really bad connection
*/

//resync_logic
//start
void resync_patch(uint8_t value) {
    DWORD old_protect;
    uint8_t* patch_addr = (uint8_t*)resync_patch_addr;
    if (VirtualProtect(patch_addr, 1, PAGE_READWRITE, &old_protect)) {
        
        static constexpr int8_t value_table[] = {
            5, 10, 15, 30, 45, 90, INT8_MAX, INT8_MAX
        };
        int8_t new_value = value_table[value / 32];
        *patch_addr = new_value;//value_table[value / 16];

        VirtualProtect(patch_addr, 1, old_protect, &old_protect);
    }
}

#define USE_ORIGINAL_RESYNC 1

void run_resync_logic(uint64_t new_timestamp) {
#if USE_ORIGINAL_RESYNC
    if (!resyncing) {
        if (prev_timestamp != new_timestamp) {
            prev_timestamp = new_timestamp;
            lag_packets = 0;
        }
        else {
            if (++lag_packets >= RESYNC_THRESHOLD) {
                resyncing = SQTrue;
                lag_packets = 0;
            }
        }
    } else {
        if (lag_packets >= RESYNC_DURATION) {
            resyncing = SQFalse;
            lag_packets = 0;
        }
        else {
            resync_patch(lag_packets);
            ++lag_packets;
        }
    }
#else
    uint8_t prev_lag_packets = lag_packets;
    if (prev_timestamp != new_timestamp) {
        prev_timestamp = new_timestamp;

        lag_packets = saturate_sub<uint8_t>(prev_lag_packets, 32u);
    }
    else {
        lag_packets = saturate_add<uint8_t>(prev_lag_packets, 1u);
    }
    if (lag_packets != prev_lag_packets) {
        resync_patch(lag_packets);
    }
#endif
}


int WSAAPI my_WSASendTo(SOCKET s, LPWSABUF lpBuffers, DWORD dwBufferCount, LPDWORD lpNumberOfBytesSent, DWORD dwFlags, const sockaddr* lpTo, int iTolen, LPWSAOVERLAPPED lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine) {

#if NETPLAY_PATCH_TYPE == NETPLAY_VER_103F
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
                run_resync_logic(*(uint64_t*)&packet->data[16]);
            }
            break;
        case 19:
            if (lpBuffers[0].len >= 26) {
                run_resync_logic(*(uint64_t*)&packet->data[17]);
            }
            break;
    }
#endif

#if LOG_BASE_GAME_SENDTO_RECVFROM
    return WSASendTo_log(s, lpBuffers, dwBufferCount, lpNumberOfBytesSent, dwFlags, lpTo, iTolen, lpOverlapped, lpCompletionRoutine);
#else
    return WSASendTo(s, lpBuffers, dwBufferCount, lpNumberOfBytesSent, dwFlags, lpTo, iTolen, lpOverlapped, lpCompletionRoutine);
#endif
}

int WSAAPI my_WSARecvFrom(SOCKET s, LPWSABUF lpBuffers, DWORD dwBufferCount, LPDWORD lpNumberOfBytesRecvd, LPDWORD lpFlags, sockaddr* lpFrom, LPINT lpFromLen, LPWSAOVERLAPPED lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine) {
#if LOG_BASE_GAME_SENDTO_RECVFROM
    int ret = WSARecvFrom_log(s, lpBuffers, dwBufferCount, lpNumberOfBytesRecvd, lpFlags, lpFrom, lpFromLen, lpOverlapped, lpCompletionRoutine);
#else
    int ret = WSARecvFrom(s, lpBuffers, dwBufferCount, lpNumberOfBytesRecvd, lpFlags, lpFrom, lpFromLen, lpOverlapped, lpCompletionRoutine);
#endif

#if NETPLAY_PATCH_TYPE == NETPLAY_VER_103F
    PacketLayout* packet = (PacketLayout*)lpBuffers[0].buf;

    switch (packet->type) {
        case 0: default:
            not_in_match = false;
        case 1: case 2: case 3: case 4: case 5:
        case 6: case 7: case 8: case 9: case 10:
        case 11:
            break;
    }
#endif

    return ret;
}

#if BETTER_BLACK_SCREEN_FIX

struct BoostLock {
    void* mutex_addr;
};

typedef void fastcall lock_func_t(BoostLock* lock);

void fastcall fix_black_screen_lock(BoostLock* lock) {
    uint8_t* mutex_addr = (uint8_t*)lock->mutex_addr;
    if (*based_pointer<uint32_t>(mutex_addr, -0x50) != read_fs_dword(0x24)) {
        ((lock_func_t*)(0xF410_R))(lock);
        *based_pointer<uint32_t>(mutex_addr, -0x50) = read_fs_dword(0x24);
    }
    ++mutex_addr[-0x71];
}

void fastcall fix_black_screen_unlockA(BoostLock* lock) {
    uint8_t* mutex_addr = (uint8_t*)lock->mutex_addr;
    if (!--mutex_addr[-0x71]) {
        *based_pointer<uint32_t>(mutex_addr, -0x50) = 0;
        return ((lock_func_t*)(0xF4C0_R))(lock);
    }
}

uint32_t fastcall fix_black_screen_unlockB(uint8_t* mutex_addr) {
    if (!--mutex_addr[-0x71]) {
        *based_pointer<uint32_t>(mutex_addr, -0x50) = 0;
    }
    return 0x80000000;
}

static constexpr uintptr_t lock_fix_addrs[] = {
    0x172FD6, 0x178B96, 0x178ED7, 0x1791BF, 0x17CDC9,
    0x17CFEB, 0x17D1DB, 0x17D36B, 0x17D5B9, 0x17D687
};
static constexpr uintptr_t unlock_fixA_addrs[] = {
    0x373F74, 0x3746FC, 0x37473C, 0x374774, 0x17CE02,
    0x17CE98, 0x17CEB5, 0x374E04, 0x374E34
};
static constexpr uintptr_t unlock_fixB_addrs[] = {
    0x173005, 0x1730A4, 0x178C3E, 0x178D69, 0x178F76,
    0x179055, 0x1791E7, 0x179269, 0x17D15C, 0x17D2EB,
    0x17D393, 0x17D3FD, 0x17D5D7, 0x17D6B2, 0x17D717
};

#endif

void patch_netplay() {
    static constexpr uint8_t data[] = { INT8_MAX };
    mem_write(patchA_addr, data);


#if BETTER_BLACK_SCREEN_FIX
    static constexpr uint8_t black_screen_patchA[] = { 0x1E };
    static constexpr uint8_t black_screen_patchB[] = { 0x89 };

    mem_write(0x171F66_R, black_screen_patchA);
    mem_write(0x17C6E6_R, black_screen_patchA);
    mem_write(0x17C6FB_R, black_screen_patchA);
    mem_write(0x17C945_R, black_screen_patchA);
    mem_write(0x171F4B_R, NOP_BYTES<1>);
    mem_write(0x171F64_R, black_screen_patchB);
#endif

    resync_patch(160);
    hotpatch_import(wsarecvfrom_import_addr, my_WSARecvFrom);
    hotpatch_import(wsasendto_import_addr, my_WSASendTo);


#if BETTER_BLACK_SCREEN_FIX
    uintptr_t base = base_address;
    for (size_t i = 0; i < countof(lock_fix_addrs); ++i) {
        hotpatch_rel32(based_pointer(base, lock_fix_addrs[i]), fix_black_screen_lock);
    }
    for (size_t i = 0; i < countof(unlock_fixA_addrs); ++i) {
        hotpatch_rel32(based_pointer(base, unlock_fixA_addrs[i]), fix_black_screen_unlockA);
    }
    for (size_t i = 0; i < countof(unlock_fixB_addrs); ++i) {
        hotpatch_call(based_pointer(base, unlock_fixB_addrs[i]), fix_black_screen_unlockB);
    }
#endif

    /*
    if (get_ipv6_enabled()) {
        mem_write(0x172AAF_R, AF_INET6);
    }
    */
}

