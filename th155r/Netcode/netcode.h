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

#define NETPLAY_DISABLE 0
#define NETPLAY_VER_103F 1

#define NETPLAY_PATCH_TYPE NETPLAY_VER_103F

#define BETTER_BLACK_SCREEN_FIX 1

extern SQBool resyncing;

extern SQBool isplaying;

void patch_netplay();


enum PacketType : uint8_t {
	// Original packets
    PACKET_TYPE_0 = 0,
    PACKET_TYPE_1 = 1,
    PACKET_TYPE_2 = 2,
    PACKET_TYPE_3 = 3,
    PACKET_TYPE_4 = 4,
    PACKET_TYPE_5 = 5,
    PACKET_TYPE_6 = 6,
    PACKET_TYPE_7 = 7,
    PACKET_TYPE_8 = 8,
    PACKET_TYPE_9 = 9,
    PACKET_TYPE_10 = 10,
    PACKET_TYPE_11 = 11,
    PACKET_TYPE_12 = 12,
    PACKET_TYPE_13 = 13,
    PACKET_TYPE_14 = 14,
    PACKET_TYPE_15 = 15,
    PACKET_TYPE_16 = 16,
    PACKET_TYPE_17 = 17,
    PACKET_TYPE_18 = 18,
    PACKET_TYPE_19 = 19,

    // Custom packets
    PACKET_TYPE_LOBBY_NAME = 0x80,
    PACKET_TYPE_PUNCH_PING = 0x81,
    PACKET_TYPE_PUNCH_WAIT = 0x82,
    PACKET_TYPE_PUNCH_CONNECT = 0x83,
    PACKET_TYPE_PUNCH_PEER = 0x84,
    PACKET_TYPE_PUNCH = 0x85,
    PACKET_TYPE_PUNCH_SELF = 0x86, // Same format as PACKET_TYPE_PUNCH_PEER
    PACKET_TYPE_LOBBY_NAME_WAIT = 0x87,
    PACKET_TYPE_IPV6_TEST = 0x88,
    PACKET_TYPE_PUNCH_DELAY_PING = 0x89,
    PACKET_TYPE_PUNCH_DELAY_PONGA = 0x8A,
    PACKET_TYPE_PUNCH_DELAY_PONGB = 0x8B,
};

struct PacketLayout {
    PacketType type;
    unsigned char data[];
};

// size: 0x8
struct PacketLobbyName {
    PacketType type; // 0x0
    // 0x1
    uint32_t length; // 0x4
    char name[]; // 0x8
};

// size: 0x1
struct PacketPunchPing {
    PacketType type; // 0x0
    // 0x1
};

// size: 0x10
struct PacketIPv6Test {
    PacketType type; // 0x0
    unsigned char padding[7]; // 0x1
    alignas(8) LARGE_INTEGER tsc; // 0x8
    // 0x10
};

static_assert(sizeof(PacketIPv6Test) == 0x10, "");

#define LOBBY_NAME_PACKET_SIZE(len) (sizeof(PacketLobbyName) + (len))

// size: 0x4
struct PacketPunchWait {
    PacketType type; // 0x0
    //uint8_t is_ipv6; // 0x1
    //uint16_t local_port; // 0x2
    //alignas(4) unsigned char ip[sizeof(IP6_ADDRESS)]; // 0x4
    // 0x14

    //PacketPunchWait() = default;

    PacketPunchWait(
        //const sockaddr_storage& addr, size_t addr_len
    )
        : type(PACKET_TYPE_PUNCH_WAIT)
    
    {
        /*
        this->local_port = ntoh<uint16_t>(((const sockaddr_in*)&addr)->sin_port);
        switch (addr.ss_family) {
            default:
                this->is_ipv6 = false;
                *(IP4_ADDRESS*)this->ip = *(IP4_ADDRESS*)&((const sockaddr_in*)&addr)->sin_addr;
                break;
            case AF_INET6:
                this->is_ipv6 = true;
                *(IP6_ADDRESS*)this->ip = *(IP6_ADDRESS*)&((const sockaddr_in6*)&addr)->sin6_addr;
                break;
        }
        */
    }
};

static inline constexpr uint8_t LOCAL_IS_IPV6_MASK = 0b01;
static inline constexpr uint8_t DEST_IS_IPV6_MASK = 0b10;

// size: 0x8+
/*
struct PacketPunchConnect {
    PacketType type; // 0x0
    uint8_t is_ipv6; // 0x1
    uint16_t local_port; // 0x2
    uint16_t dest_port; // 0x4
    // 0x6
    alignas(4) unsigned char local_ip[sizeof(IP6_ADDRESS)]; // 0x8
    alignas(4) unsigned char dest_ip[sizeof(IP6_ADDRESS)]; // 0x18
    // 0x28
};
*/

struct PacketPunchConnect {
    PacketType type; // 0x0
    uint8_t is_ipv6; // 0x1
    uint16_t dest_port; // 0x2
    alignas(4) unsigned char dest_ip[sizeof(IP6_ADDRESS)]; // 0x4

    PacketPunchConnect() = default;

    PacketPunchConnect(bool is_ipv6, const char* ip, uint16_t port)
        : type(PACKET_TYPE_PUNCH_CONNECT), is_ipv6(is_ipv6), dest_port(port)
    
    {
        inet_pton(!is_ipv6 ? AF_INET : AF_INET6, ip, &this->dest_ip);
    }
};

// size: 0x4
struct PacketPunchPeer {
    PacketType type; // 0x0
    uint8_t is_ipv6; // 0x1
    uint16_t remote_port; // 0x2
    alignas(4) unsigned char ip[sizeof(IP6_ADDRESS)]; // 0x4
    // 0x14
};

// size: 0x1
struct PacketPunch {
    PacketType type; // 0x0
    // 0x1
};

struct PacketPunchDelayPing {
    PacketType type; // 0x0
    uint8_t flags; // 0x1
    uint16_t dest_port; // 0x2
    alignas(4) unsigned char dest_ip[sizeof(IP6_ADDRESS)]; // 0x4

    PacketPunchDelayPing() = default;

    PacketPunchDelayPing(const sockaddr_storage& addr)
        : type(PACKET_TYPE_PUNCH_DELAY_PING)
    {
        this->dest_port = ntoh<uint16_t>(((sockaddr_in*)&addr)->sin_port);
        if ((this->flags = addr.ss_family == AF_INET6 ? 0x80 : 0x00)) {
            *(in_addr6*)&this->dest_ip = ((sockaddr_in6*)&addr)->sin6_addr;
        } else {
            *(in_addr*)&this->dest_ip = ((sockaddr_in*)&addr)->sin_addr;
        }
    }
};

struct PacketPunchDelayPong {
    PacketType type; // 0x0
    uint8_t index; // 0x1
    // 0x2
};

static inline constexpr PacketPunch PUNCH_PACKET = {
    .type = PACKET_TYPE_PUNCH
};

extern char punch_ip_buffer[INET6_ADDRSTRLEN];
extern size_t punch_ip_len;
extern bool punch_ip_updated;

#endif