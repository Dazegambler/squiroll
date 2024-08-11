#pragma once
#ifndef AUTOPUNCH_H
#define AUTOPUNCH_H

#include <winsock2.h>
#include <windows.h>
#include <stdio.h>
#include <time.h>
#include <ws2tcpip.h>
#include "log.h"

struct mapping {
	struct sockaddr_in addr;
	u_short port;
	clock_t last_send;
	clock_t last_refresh;
	bool refresh;
};

struct transient_peer {
	struct sockaddr_in addr;
	clock_t last;
};

struct socket_data {
	SOCKET s;
	HANDLE mutex;
	u_short port;
	bool closed;
	struct mapping *mappings;
	size_t mappings_len;
	size_t mappings_cap;
	struct transient_peer *transient_peers;
	size_t transient_peers_len;
	size_t transient_peers_cap;
};

int WSAAPI my_recvfrom(SOCKET s,LPWSABUF lpBuffers,DWORD dwBufferCount,LPDWORD lpNumberOfBytesRecvd,LPDWORD lpFlags,sockaddr *lpFrom,LPINT lpFromlen,LPWSAOVERLAPPED lpOverlapped,LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);
int WSAAPI my_sendto(SOCKET s,LPWSABUF lpBuffers,DWORD dwBufferCount,LPDWORD lpNumberOfBytesSent,DWORD dwFlags,struct sockaddr *lpTo,int iTolen, LPWSAOVERLAPPED lpOverlapped,LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);
int WSAAPI my_send(SOCKET s,LPWSABUF lpBuffers,DWORD dwBufferCount,LPDWORD lpNumberOfBytesSent,DWORD dwFlags, LPWSAOVERLAPPED lpOverlapped,LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);
int WSAAPI my_bind(SOCKET s, const struct sockaddr *name, int namelen);
int WINAPI my_closesocket(SOCKET s);
DWORD WINAPI relay(void *data);
u_long get_relay_ip();
struct socket_data *get_socket_data(SOCKET s);
bool running();
void autopunch_init();
void autopunch_cleanup();
#endif