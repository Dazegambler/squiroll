#pragma once
#ifndef AUTOPUNCH_H
#define AUTOPUNCH_H

#include <winsock2.h>
#include <windows.h>
#include <shlobj.h>
#include <shlwapi.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <ws2tcpip.h>

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

int WINAPI my_recvfrom(SOCKET s, char *out_buf, int len, int flags, struct sockaddr *from_original, int *fromlen_original);
int WINAPI my_sendto(SOCKET s, const char *buf, int len, int flags, const struct sockaddr *to_original, int tolen);
int WINAPI my_bind(SOCKET s, const struct sockaddr *name, int namelen);
int WINAPI my_closesocket(SOCKET s);
DWORD WINAPI relay(void *data);
u_long get_relay_ip();
struct socket_data *get_socket_data(SOCKET s);
bool running();
void load();
void unload();
#endif