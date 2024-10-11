#pragma once

#ifndef LOBBY_H
#define LOBBY_H 1

#include <stdlib.h>
#include <stdint.h>
#include <mutex>
#include <optional>

#include <winsock2.h>
#include <windows.h>

#include "log.h"

extern uintptr_t lobby_base_address;

void patch_se_lobby(void* base_address);
SOCKET WSAAPI inherit_punch_socket(int af, int type, int protocol, LPWSAPROTOCOL_INFOW lpProtocolInfo, GROUP g, DWORD dwFlags);
int WSAAPI bind_inherited_socket(SOCKET s, const sockaddr* name, int namelen);
int WSAAPI close_punch_socket(SOCKET s);

extern std::mutex to_be_punched_mutex;
extern std::optional<sockaddr_storage> to_be_punched;

#if CONNECTION_LOGGING & CONNECTION_LOGGING_UDP_PACKETS
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

void recvfrom_log(
    void* data,
    size_t data_length,
    sockaddr* from,
    int from_length
);
#else
#define WSASendTo_log(...) WSASendTo(__VA_ARGS__)
#define recvfrom_log(...) EVAL_NOOP(__VA_ARGS__)
#endif

void send_lobby_punch_wait();

#endif