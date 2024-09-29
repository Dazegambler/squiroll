#pragma once

#ifndef NETCODE_H
#define NETCODE_H 1

#include <stdlib.h>
#include <stdint.h>
#include <squirrel.h>

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
    PACKET_TYPE_PUNCH = 0x84,
    PACKET_TYPE_IPV6_TEST = 0x88,
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

// size: 0x4+
struct PacketPunchWait {
    PacketType type; // 0x0
    uint8_t is_ipv6; // 0x1
    uint16_t local_port; // 0x2
    alignas(4) unsigned char ip[]; // 0x4
};

static inline constexpr uint8_t LOCAL_IS_IPV6_MASK = 0b01;
static inline constexpr uint8_t DEST_IS_IPV6_MASK = 0b10;

// size: 0x8+
struct PacketPunchConnect {
    PacketType type; // 0x0
    uint8_t is_ipv6; // 0x1
    uint16_t local_port; // 0x2
    uint16_t dest_port; // 0x4
    // 0x6
    alignas(4) unsigned char ips[]; // 0x8
};

// size: 0x4
struct PacketPunch {
    PacketType type; // 0x0
    uint8_t is_ipv6; // 0x1
    uint16_t remote_port; // 0x2
    alignas(4) unsigned char ip[]; // 0x4
};

#endif