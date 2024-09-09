#pragma once

#ifndef NETCODE_H
#define NETCODE_H 1

#include <winsock2.h>
#include <windows.h>

#include "util.h"
#include "PatchUtils.h"
#include "fake_lag.h"


#define resync_patch_addr (0x0E364C_R)
#define patchA_addr (0x0E357A_R)
#define wsasendto_import_addr (0x3884D4_R)
#define wsarecvfrom_import_addr (0x3884D8_R)
#define createmutex_patch_addr (0x01DC61_R)

struct PacketLayout {
    int8_t type;
    unsigned char data[];
};

void resync_patch(uint8_t value);
void run_resync_logic(uint64_t new_timestamp);
int WSAAPI my_WSASendTo(SOCKET s, LPWSABUF lpBuffers, DWORD dwBufferCount, LPDWORD lpNumberOfBytesSent, DWORD dwFlags, const sockaddr* lpTo, int iTolen, LPWSAOVERLAPPED lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);
int WSAAPI my_WSARecvFrom(SOCKET s, LPWSABUF lpBuffers, DWORD dwBufferCount, LPDWORD lpNumberOfBytesRecvd, LPDWORD lpFlags, sockaddr* lpFrom, LPINT lpFromLen, LPWSAOVERLAPPED lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

void patch_netplay();

#endif