#pragma once

#ifndef LOBBY_H
#define LOBBY_H 1

#include <stdlib.h>
#include <stdint.h>

#include <winsock2.h>
#include <windows.h>

extern uintptr_t lobby_base_address;

void patch_se_lobby(void* base_address);
SOCKET WSAAPI inherit_punch_socket(int af, int type, int protocol, LPWSAPROTOCOL_INFOW lpProtocolInfo, GROUP g, DWORD dwFlags);
int WSAAPI confirm_inherited_socket(SOCKET s, const sockaddr* name, int namelen);
int WSAAPI close_punch_socket(SOCKET s);

#endif