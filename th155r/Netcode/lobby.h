#pragma once

#ifndef LOBBY_H
#define LOBBY_H 1

#include <stdlib.h>
#include <stdint.h>

#include <winsock2.h>
#include <windows.h>


#define LOG_BASE_GAME_SENDTO_RECVFROM 1

extern uintptr_t lobby_base_address;

void patch_se_lobby(void* base_address);
SOCKET WSAAPI inherit_punch_socket(int af, int type, int protocol, LPWSAPROTOCOL_INFOW lpProtocolInfo, GROUP g, DWORD dwFlags);
int WSAAPI bind_inherited_socket(SOCKET s, const sockaddr* name, int namelen);
int WSAAPI close_punch_socket(SOCKET s);

int WSAAPI WSASendTo_log(
    SOCKET s,
    LPWSABUF lpBuffers,
    DWORD dwBufferCount,
    LPDWORD lpNumberOfBytesSent,
    DWORD dwFlags,
    const sockaddr* lpTo,
    int iTolen,
    LPWSAOVERLAPPED lpOverlapped,
    LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine
);

int WSAAPI WSARecvFrom_log(
    SOCKET s,
    LPWSABUF lpBuffers,
    DWORD dwBufferCount,
    LPDWORD lpNumberOfBytesRecvd,
    LPDWORD lpFlags,
    sockaddr* lpFrom,
    LPINT lpFromlen,
    LPWSAOVERLAPPED lpOverlapped,
    LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine
);

#endif