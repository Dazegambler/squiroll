#pragma once

#ifndef LOBBY_H
#define LOBBY_H 1

#include <stdlib.h>
#include <stdint.h>

#include <winsock2.h>
#include <windows.h>

#include "log.h"

#define PUNCH_BOOST_NONE                0b000
#define PUNCH_BOOST_PROCESS_PRIORITY    0b001
#define PUNCH_BOOST_THREAD_PRIORITY     0b010
#define PUNCH_BOOST_TIMER_PRECISION     0b100
#define PUCNH_BOOST_FULL                0b111

#define PUNCH_BOOST_TYPE PUCNH_BOOST_FULL

#define PUNCH_START_USE_ATOMIC 0
#define PUNCH_START_USE_EVENT 1

#define PUNCH_START_TYPE PUNCH_START_USE_EVENT

#define PUNCH_SLEEP_USE_SPIN 0
#define PUNCH_SLEEP_USE_TIMER 1

#define PUNCH_SLEEP_TYPE PUNCH_SLEEP_USE_SPIN

extern uintptr_t lobby_base_address;

void patch_se_lobby(void* base_address);
SOCKET WSAAPI inherit_punch_socket(int af, int type, int protocol, LPWSAPROTOCOL_INFOW lpProtocolInfo, GROUP g, DWORD dwFlags);
int WSAAPI bind_inherited_socket(SOCKET s, const sockaddr* name, int namelen);
int WSAAPI close_punch_socket(SOCKET s);

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
void send_lobby_punch_connect(bool is_ipv6, const char* ip, uint16_t port);
void send_punch_response(bool is_ipv6, const void* ip, uint16_t port);
void send_punch_delay_pong(SOCKET sock, const void* buf, size_t length);

bool addr_is_lobby(const sockaddr* addr, int addr_len);

extern std::atomic<uint32_t> users_in_room;

#if PUNCH_START_TYPE == PUNCH_START_USE_ATOMIC
extern std::atomic<bool> start_punch;
#define START_PUNCH_SET_FLAG() start_punch = true
#define START_PUNCH_RESET_FLAG() start_punch = false
#define START_PUNCH_WAIT(timeout) wait_until_true(start_punch, (timeout))
#elif PUNCH_START_TYPE == PUNCH_START_USE_EVENT
extern WaitableEvent start_punch;
#define START_PUNCH_SET_FLAG() start_punch.set()
#define START_PUNCH_RESET_FLAG() start_punch.reset()
#define START_PUNCH_WAIT(timeout) start_punch.wait_sync(timeout)
#endif

#endif