#pragma once

#ifndef PACKET_TYPES_H
#define PACKET_TYPES_H 1

#include <stdint.h>

#include "znet.h"

using namespace zero::net;

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
    PACKET_TYPE_LOBBY_NAME = 0x80, // 128
    PACKET_TYPE_PUNCH_PING = 0x81, // 129
    PACKET_TYPE_PUNCH_WAIT = 0x82, // 130
    PACKET_TYPE_PUNCH_CONNECT = 0x83, // 131
    PACKET_TYPE_PUNCH_PEER = 0x84, // 132
    PACKET_TYPE_PUNCH = 0x85, // 133
    PACKET_TYPE_PUNCH_SELF = 0x86, // 134 Same format as PACKET_TYPE_PUNCH_PEER
    PACKET_TYPE_LOBBY_NAME_WAIT = 0x87, // 135
    PACKET_TYPE_IPV6_TEST = 0x88, // 136
    PACKET_TYPE_PUNCH_DELAY_PING = 0x89, // 137
    PACKET_TYPE_PUNCH_DELAY_PONGA = 0x8A, // 138
    PACKET_TYPE_PUNCH_DELAY_PONGB = 0x8B, // 139
};

struct PacketLayout {
    PacketType type;
    unsigned char data[];
};

enum NicknameSource : uint8_t {
    AUTO_GENERATED_NAME = 0,
    DISCORD_USERID = 1,
};

static inline constexpr size_t MAX_NICKNAME_LENGTH = 32;

// size: 0x8+
struct PacketLobbyName {
    PacketType type; // 0x0
    // 0x1
    uint32_t length; // 0x4
    char name[]; // 0x8
};
static_assert(sizeof(PacketLobbyName) == 0x8);

#define LOBBY_NAME_PACKET_SIZE(len) (sizeof(PacketLobbyName) + (len))

// size: 0x1
struct PacketPunchPing {
    PacketType type; // 0x0
    // 0x1
};
static_assert(sizeof(PacketPunchPing) == 0x1);

// size: 0x10
struct PacketIPv6Test {
    PacketType type; // 0x0
    unsigned char padding[7]; // 0x1
    alignas(8) LARGE_INTEGER tsc; // 0x8
    // 0x10
};
static_assert(sizeof(PacketIPv6Test) == 0x10, "");

// size: 0x1
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

    //ipaddr_any local_ip() const {
        //return ipaddr_any(this->is_ipv6, this->local_port, this->ip);
    //}
};
static_assert(sizeof(PacketPunchWait) == 0x1);

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

    ipaddr_any local_ip() const {
        return ipaddr_any(this->is_ipv6 & LOCAL_IS_IPV6_MASK, this->local_port, this->local_ip_buf);
    }

    ipaddr_any dest_ip() const {
        return ipaddr_any(this->is_ipv6 & DEST_IS_IPV6_MASK, this->dest_port, this->dest_ip_buf);
    }
};
*/

// size: 0x14
struct PacketPunchConnect {
    PacketType type; // 0x0
    uint8_t is_ipv6; // 0x1
    uint16_t dest_port; // 0x2
    alignas(4) unsigned char dest_ip_buf[sizeof(IP6_ADDRESS)]; // 0x4
    // 0x14

    PacketPunchConnect() = default;

    PacketPunchConnect(bool is_ipv6, const char* ip, uint16_t port)
        : type(PACKET_TYPE_PUNCH_CONNECT), is_ipv6(is_ipv6), dest_port(port)
    
    {
        inet_pton(!is_ipv6 ? AF_INET : AF_INET6, ip, &this->dest_ip_buf);
    }

    ipaddr_any dest_ip() const {
        return ipaddr_any(this->is_ipv6, this->dest_port, this->dest_ip_buf);
    }

    sockaddr_any dest_sock() const {
        return sockaddr_any(this->is_ipv6, this->dest_port, this->dest_ip_buf);
    }
};
static_assert(sizeof(PacketPunchConnect) == 0x14);

// size: 0x14
struct PacketPunchPeer {
    PacketType type; // 0x0
    uint8_t is_ipv6; // 0x1
    uint16_t remote_port; // 0x2
    alignas(4) unsigned char ip[sizeof(IP6_ADDRESS)]; // 0x4
    // 0x14

    PacketPunchPeer() = default;

    PacketPunchPeer(bool is_ipv6, uint16_t port, const void* ip)
        : type(PACKET_TYPE_PUNCH_PEER), is_ipv6(is_ipv6), remote_port(port)
    {
        if (is_ipv6) {
            *(IP6_ADDRESS*)this->ip = *(IP6_ADDRESS*)ip;
        } else {
            *(IP4_ADDRESS*)this->ip = *(IP4_ADDRESS*)ip;
        }
    }

    inline PacketPunchPeer(const sockaddr_any& addr) : PacketPunchPeer(addr.is_ipv6(), get_port(addr), addr.get_ip_ptr()) {}
};
static_assert(sizeof(PacketPunchPeer) == 0x14);

// size: 0x1
struct PacketPunch {
    PacketType type; // 0x0
    // 0x1
};
static_assert(sizeof(PacketPunch) == 0x1);

// size: 0x14
struct PacketPunchDelayPing {
    PacketType type; // 0x0
    uint8_t flags; // 0x1
    uint16_t dest_port; // 0x2
    alignas(4) unsigned char dest_ip_buf[sizeof(IP6_ADDRESS)]; // 0x4
    // 0x14

    PacketPunchDelayPing() = default;

    PacketPunchDelayPing(const sockaddr_storage& addr)
        : type(PACKET_TYPE_PUNCH_DELAY_PING)
    {
        this->dest_port = ntoh<uint16_t>(((sockaddr_in*)&addr)->sin_port);
        if ((this->flags = addr.ss_family == AF_INET6 ? 0x80 : 0x00)) {
            *(in6_addr*)&this->dest_ip_buf = ((sockaddr_in6*)&addr)->sin6_addr;
        } else {
            *(in_addr*)&this->dest_ip_buf = ((sockaddr_in*)&addr)->sin_addr;
        }
    }

    ipaddr_any dest_ip() const {
        return ipaddr_any(this->flags & 0x80, this->dest_port, this->dest_ip_buf);
    }

    sockaddr_any dest_sock() const {
        return sockaddr_any(this->flags & 0x80, this->dest_port, this->dest_ip_buf);
    }
};
static_assert(sizeof(PacketPunchDelayPing) == 0x14);

// size: 0x2
struct PacketPunchDelayPong {
    PacketType type; // 0x0
    uint8_t index; // 0x1
    // 0x2
};
static_assert(sizeof(PacketPunchDelayPong) == 0x2);

// size: 0x14
struct PacketPunchSelf {
    PacketType type; // 0x0
    uint8_t is_ipv6; // 0x1
    uint16_t remote_port; // 0x2
    alignas(4) unsigned char ip[sizeof(IP6_ADDRESS)]; // 0x4
    // 0x14

    PacketPunchSelf() = default;

    PacketPunchSelf(bool is_ipv6, uint16_t port, const void* ip)
        : type(PACKET_TYPE_PUNCH_SELF), is_ipv6(is_ipv6), remote_port(port)
    {
        if (is_ipv6) {
            *(IP6_ADDRESS*)this->ip = *(IP6_ADDRESS*)ip;
        } else {
            *(IP4_ADDRESS*)this->ip = *(IP4_ADDRESS*)ip;
        }
    }

    inline PacketPunchSelf(const sockaddr_any& addr) : PacketPunchSelf(addr.is_ipv6(), get_port(addr), addr.get_ip_ptr()) {}
};
static_assert(sizeof(PacketPunchSelf) == 0x14);

#endif