

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
    bool is_locked;
};

typedef void fastcall lock_func_t(BoostLock* lock);

void fastcall fix_black_screen_lock(BoostLock* lock) {

    uint8_t* mutex_addr = (uint8_t*)lock->mutex_addr;

    auto current_thread = read_fs_dword(0x24);
    if (current_thread != *based_pointer<std::atomic<uint32_t>>(mutex_addr, -0x50)) {
        ((lock_func_t*)(0xF410_R))(lock);
        *based_pointer<std::atomic<uint32_t>>(mutex_addr, -0x50) = current_thread;
    }
    ++mutex_addr[-0x71];
    lock->is_locked = true;
}

void fastcall fix_black_screen_unlock(BoostLock* lock) {

    uint8_t* mutex_addr = (uint8_t*)lock->mutex_addr;
    
    if (expect(!--mutex_addr[-0x71], true)) {
        *based_pointer<std::atomic<uint32_t>>(mutex_addr, -0x50) = 0;
        return ((lock_func_t*)(0xF4C0_R))(lock);
    }
}

static constexpr uintptr_t lock_fix_addrs[] = {
    0x172FD6, // Method 28
    0x178B96, // Method 20
    0x178ED7, // Method 24
    0x1791BF, // Method 10
    0x17CDC9, // Handle packet 9
    0x17CFEB, // Handle packet 11
    0x17D1DB, // Handle packet 12
    0x17D36B, // Handle packet 13
    0x17D5B9, // Handle packet 15
    0x17D687  // Handle packet 16
};
static constexpr uintptr_t unlock_fixA_addrs[] = {
    0x373F74, // Method 28 SEH
    0x3746FC, // Method 20 SEH
    0x37473C, // Method 24 SEH
    0x374774, // Method 10 SEH
    0x17CE02, 0x17CE98, 0x17CEB5, // Handle packet 9
    0x374E04, // Handle packet 9 SEH
    0x374E34  // Handle packet 11 SEH, Handle packet 12 SEH
};

static constexpr uintptr_t unlock_fixB_addrs[] = {
    0x172FF1, 0x173094, // Method 28            C1+, C2+
    0x178C2D, 0x178D5C, // Method 20            C3, C4
    0x178F65, 0x179048, // Method 24            C5, C6
    0x1791D3, 0x179259, // Method 10            C7+, C8+
    0x17D14C, // Handle packet 11               C9+
    0x17D2DB, // Handle packet 12               C9+
    0x17D37F, 0x17D3ED, // Handle packet 13     C10+, C8+
    0x17D5C7, // Handle packet 15               C8+
    0x17D69F, 0x17D706, // Handle packet 16     C11, C8+
};

// CC, F5000000, NOP3
static constexpr uint8_t unlock_fixB1[] = {
    0x8B, 0x4D, 0xCC,                           // MOV ECX, DWORD PTR [EBP-0x34]
    0xFE, 0x49, 0x8F,                           // DEC BYTE PTR [ECX-0x71]
    0x0F, 0x85, 0xF5, 0x00, 0x00, 0x00,         // JNZ
    0x31, 0xD2,                                 // XOR EDX, EDX
    0x87, 0x51, 0xB0,                           // XCHG DWORD PTR [ECX-0x50], EDX
    BASE_NOP3
};

// CC, 32, NOP3
static constexpr uint8_t unlock_fixB2[] = {
    0x8B, 0x4D, 0xCC,                           // MOV ECX, DWORD PTR [EBP-0x34]
    0xFE, 0x49, 0x8F,                           // DEC BYTE PTR [ECX-0x71]
    0x75, 0x32,                                 // JNZ
    0x31, 0xD2,                                 // XOR EDX, EDX
    0x87, 0x51, 0xB0,                           // XCHG DWORD PTR [ECX-0x50], EDX
    BASE_NOP3
};

// E0, 24020000
static constexpr uint8_t unlock_fixB3[] = {
    0x8B, 0x4D, 0xE0,                           // MOV ECX, DWORD PTR [EBP-0x20]
    0xFE, 0x49, 0x8F,                           // DEC BYTE PTR [ECX-0x71]
    0x0F, 0x85, 0x24, 0x02, 0x00, 0x00,         // JNZ
    0x31, 0xD2,                                 // XOR EDX, EDX
    0x87, 0x51, 0xB0,                           // XCHG DWORD PTR [ECX-0x50], EDX
};

// E0, 2F
static constexpr uint8_t unlock_fixB4[] = {
    0x8B, 0x4D, 0xE0,                           // MOV ECX, DWORD PTR [EBP-0x20]
    0xFE, 0x49, 0x8F,                           // DEC BYTE PTR [ECX-0x71]
    0x75, 0x2F,                                 // JNZ
    0x31, 0xD2,                                 // XOR EDX, EDX
    0x87, 0x51, 0xB0,                           // XCHG DWORD PTR [ECX-0x50], EDX
};

// E8, D8010000
static constexpr uint8_t unlock_fixB5[] = {
    0x8B, 0x4D, 0xE8,                           // MOV ECX, DWORD PTR [EBP-0x18]
    0xFE, 0x49, 0x8F,                           // DEC BYTE PTR [ECX-0x71]
    0x0F, 0x85, 0xD8, 0x01, 0x00, 0x00,         // JNZ
    0x31, 0xD2,                                 // XOR EDX, EDX
    0x87, 0x51, 0xB0,                           // XCHG DWORD PTR [ECX-0x50], EDX
};

// E8, 2F
static constexpr uint8_t unlock_fixB6[] = {
    0x8B, 0x4D, 0xE8,                           // MOV ECX, DWORD PTR [EBP-0x18]
    0xFE, 0x49, 0x8F,                           // DEC BYTE PTR [ECX-0x71]
    0x75, 0x2F,                                 // JNZ
    0x31, 0xD2,                                 // XOR EDX, EDX
    0x87, 0x51, 0xB0,                           // XCHG DWORD PTR [ECX-0x50], EDX
};

// EC, DB000000, NOP3
static constexpr uint8_t unlock_fixB7[] = {
    0x8B, 0x4D, 0xEC,                           // MOV ECX, DWORD PTR [EBP-0x14]
    0xFE, 0x49, 0x8F,                           // DEC BYTE PTR [ECX-0x71]
    0x0F, 0x85, 0xDB, 0x00, 0x00, 0x00,         // JNZ
    0x31, 0xD2,                                 // XOR EDX, EDX
    0x87, 0x51, 0xB0,                           // XCHG DWORD PTR [ECX-0x50], EDX
    BASE_NOP3
};

// EC, 32, NOP3
static constexpr uint8_t unlock_fixB8[] = {
    0x8B, 0x4D, 0xEC,                           // MOV ECX, DWORD PTR [EBP-0x14]
    0xFE, 0x49, 0x8F,                           // DEC BYTE PTR [ECX-0x71]
    0x75, 0x32,                                 // JNZ
    0x31, 0xD2,                                 // XOR EDX, EDX
    0x87, 0x51, 0xB0,                           // XCHG DWORD PTR [ECX-0x50], EDX
    BASE_NOP3
};

// E8, 32, NOP3
static constexpr uint8_t unlock_fixB9[] = {
    0x8B, 0x4D, 0xE8,                           // MOV ECX, DWORD PTR [EBP-0x18]
    0xFE, 0x49, 0x8F,                           // DEC BYTE PTR [ECX-0x71]
    0x75, 0x32,                                 // JNZ
    0x31, 0xD2,                                 // XOR EDX, EDX
    0x87, 0x51, 0xB0,                           // XCHG DWORD PTR [ECX-0x50], EDX
    BASE_NOP3
};

// EC, D4010000, NOP3
static constexpr uint8_t unlock_fixB10[] = {
    0x8B, 0x4D, 0xEC,                           // MOV ECX, DWORD PTR [EBP-0x14]
    0xFE, 0x49, 0x8F,                           // DEC BYTE PTR [ECX-0x71]
    0x0F, 0x85, 0xD4, 0x01, 0x00, 0x00,         // JNZ
    0x31, 0xD2,                                 // XOR EDX, EDX
    0x87, 0x51, 0xB0,                           // XCHG DWORD PTR [ECX-0x50], EDX
    BASE_NOP3
};

// EC, AC000000, NOP2
static constexpr uint8_t unlock_fixB11[] = {
    0x8B, 0x4D, 0xEC,                           // MOV ECX, DWORD PTR [EBP-0x14]
    0xFE, 0x49, 0x8F,                           // DEC BYTE PTR [ECX-0x71]
    0x0F, 0x85, 0xAC, 0x00, 0x00, 0x00,         // JNZ
    0x31, 0xD2,                                 // XOR EDX, EDX
    0x87, 0x51, 0xB0,                           // XCHG DWORD PTR [ECX-0x50], EDX
    BASE_NOP2
};

#endif

void patch_netplay() {
    mem_write(patchA_addr, PATCH_BYTES<INT8_MAX>);

#if BETTER_BLACK_SCREEN_FIX
    //mem_write(0x171F66_R, PATCH_BYTES<0x1E>);
    mem_write(0x17C6E6_R, PATCH_BYTES<0x1E>);
    mem_write(0x17C6FB_R, PATCH_BYTES<0x1E>);
    mem_write(0x17C945_R, PATCH_BYTES<0x1E>);
    mem_write(0x171F4B_R, NOP_BYTES(1));
    mem_write(0x171F64_R, PATCH_BYTES<0x89>);
#endif

    resync_patch(160);
    hotpatch_import(wsarecvfrom_import_addr, my_WSARecvFrom);
    hotpatch_import(wsasendto_import_addr, my_WSASendTo);


#if BETTER_BLACK_SCREEN_FIX
    mem_write(0x172FF1_R, unlock_fixB1);
    mem_write(0x173094_R, unlock_fixB2);
    mem_write(0x178C2D_R, unlock_fixB3);
    mem_write(0x178D5C_R, unlock_fixB4);
    mem_write(0x178F65_R, unlock_fixB5);
    mem_write(0x179048_R, unlock_fixB6);
    mem_write(0x1791D3_R, unlock_fixB7);
    mem_write(0x179259_R, unlock_fixB8);
    mem_write(0x17D14C_R, unlock_fixB9);
    mem_write(0x17D2DB_R, unlock_fixB9);
    mem_write(0x17D37F_R, unlock_fixB10);
    mem_write(0x17D3ED_R, unlock_fixB8);
    mem_write(0x17D5C7_R, unlock_fixB8);
    mem_write(0x17D69F_R, unlock_fixB11);
    mem_write(0x17D706_R, unlock_fixB8);

    uintptr_t base = base_address;
    for (size_t i = 0; i < countof(lock_fix_addrs); ++i) {
        hotpatch_rel32(based_pointer(base, lock_fix_addrs[i]), fix_black_screen_lock);
    }
    for (size_t i = 0; i < countof(unlock_fixA_addrs); ++i) {
        hotpatch_rel32(based_pointer(base, unlock_fixA_addrs[i]), fix_black_screen_unlock);
    }
#endif

    /*
    if (get_ipv6_enabled()) {
        mem_write(0x172AAF_R, AF_INET6);
    }
    */
}

