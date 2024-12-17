#pragma once

#ifndef NETCODE_H
#define NETCODE_H 1

#include <stdlib.h>
#include <stdint.h>
#include <squirrel.h>

#include <winsock2.h>
#include <ws2tcpip.h>
#include <windns.h>

#include "util.h"
#include "discord.h"

#define ZNET_IPV6_MODE ZNET_DISABLE_IPV6
#define ZNET_SIZE_OPTIMIZE_PRINTS 1
#include "packet_types.h"

#define BETTER_BLACK_SCREEN_FIX 1

extern bool resyncing;

void patch_netplay();

static inline constexpr PacketPunch PUNCH_PACKET = {
    .type = PACKET_TYPE_PUNCH
};

extern char punch_ip_buffer[MAX_ADDR_BUFF_SIZE];
extern size_t punch_ip_len;
extern bool punch_ip_updated;
extern int64_t latency;
extern std::atomic<bool> respond_to_punch_ping;

#endif