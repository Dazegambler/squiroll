#pragma once

#ifndef ZNET_H
#define ZNET_H 1

#define NOMINMAX 1

// These types aren't even used in the code
// but clang is warning about them anyway
#define _WINSOCK_DEPRECATED_NO_WARNINGS 1

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <wchar.h>

#include <vector>
#include <unordered_map>
#include <mutex>
#include <shared_mutex>
#include <thread>
#include <atomic>
#include <utility>
#include <type_traits>
#include <bit>
#include <atomic>
#include <string>
#include <string_view>
#include <functional>

#if _WIN32
#ifndef ZNET_SUPPORT_WCHAR
#define ZNET_SUPPORT_WCHAR 1
#endif

#define ENABLE_SSL 0

#include <WinSock2.h>
#include <WS2tcpip.h>
#include <MSWSock.h>

#if ENABLE_SSL
#define SECURITY_WIN32
#include <security.h>
#include <schannel.h>
#include <sspi.h>
#endif

#include <windows.h>

#include <WinDNS.h>

typedef int socklen_t;
typedef uint16_t sa_family_t;
typedef uint16_t in_port_t;
#else

#define ENABLE_SSL 0
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <arpa/inet.h>
#include <netdb.h>

typedef int SOCKET;
typedef struct addrinfo ADDRINFOA;
typedef in_addr_t IP4_ADDRESS;
typedef union {
    uint32_t IP6Dword[4];
    uint16_t IP6Word[8];
} IP6_ADDRESS;
#define INVALID_SOCKET (~((SOCKET)0))
#define WSAGetLastError() errno
#endif

using usocklen_t = std::make_unsigned_t<socklen_t>;

#include "common.h"

#if _WIN32
#pragma comment (lib, "Ws2_32.lib")
#pragma comment (lib, "Dnsapi")
#if ENABLE_SSL
#pragma comment (lib, "secur32.lib")
#endif
#endif

namespace zero {

namespace util {
template <typename T>
using SIForSize = std::conditional_t<sizeof(T) == sizeof(int8_t), int8_t,
                  std::conditional_t<sizeof(T) == sizeof(int16_t), int16_t,
                  std::conditional_t<sizeof(T) == sizeof(int32_t), int32_t,
                  std::conditional_t<sizeof(T) == sizeof(int64_t), int64_t,
                  void>>>>;

template <typename T>
using UIForSize = std::conditional_t<sizeof(T) == sizeof(uint8_t), uint8_t,
                  std::conditional_t<sizeof(T) == sizeof(uint16_t), uint16_t,
                  std::conditional_t<sizeof(T) == sizeof(uint32_t), uint32_t,
                  std::conditional_t<sizeof(T) == sizeof(uint64_t), uint64_t,
                  void>>>>;

template <typename T>
static constexpr UIForSize<T> bit_cast_from_size(T value) {
    return std::bit_cast<UIForSize<T>>(value);
}

template <typename T>
static constexpr T bit_cast_to_size(UIForSize<T> value) {
    return std::bit_cast<T>(value);
}

template <typename T>
static constexpr T bswap(T value) {
    auto temp = bit_cast_from_size<T>(value);
    if constexpr (sizeof(T) == sizeof(uint16_t)) {
        temp = __builtin_bswap16(temp);
    }
    else if constexpr (sizeof(T) == sizeof(uint32_t)) {
        temp = __builtin_bswap32(temp);
    }
    else if constexpr (sizeof(T) == sizeof(uint64_t)) {
        temp = __builtin_bswap64(temp);
    }
    return bit_cast_to_size<T>(temp);
}

}

namespace net {

template<typename T>
static inline constexpr T hton(T value) {
    if constexpr (std::endian::native == std::endian::little) {
        return util::bswap(value);
    }
    else if constexpr (std::endian::native == std::endian::big) {
        return value;
    }
    else {
        static_assert(false);
    }
}

template<typename T>
static inline constexpr T ntoh(T value) {
    if constexpr (std::endian::native == std::endian::little) {
        return util::bswap(value);
    }
    else if constexpr (std::endian::native == std::endian::big) {
        return value;
    }
    else {
        static_assert(false);
    }
}

#if ZNET_SUPPORT_WCHAR
#define ZNET_WCHAR_TEST(type) do; while(0)
#else
#define ZNET_WCHAR_TEST(type) if constexpr (std::is_same_v<type, wchar_t>) { static_assert(false, "Wide characters are not supported"); }
#endif

#define ZNET_REQUIRE_IPV6       0b001
#define ZNET_DONT_REQUIRE_IPV6  0b010
#define ZNET_DISABLE_IPV6       0b100

#ifndef ZNET_IPV6_MODE
#define ZNET_IPV6_MODE ZNET_DONT_REQUIRE_IPV6
#endif

#define ZNET_IPV6_MODES(mask) ((ZNET_IPV6_MODE) & (mask))

#if ZNET_IPV6_MODES(ZNET_REQUIRE_IPV6)
static inline constexpr bool enable_ipv6 = true;
#endif
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6)
#if _WIN32
static inline bool enable_ipv6 = false;
#else
static inline bool enable_ipv6 = true;
#endif
#endif
#if ZNET_IPV6_MODES(ZNET_DISABLE_IPV6)
static inline constexpr bool enable_ipv6 = false;
#endif

enum IPType : uint8_t {
    IPv4,
    IPv6
};

// size: 0x20
struct IPv4Header {
    union {
        uint8_t first_byte; // 0x0
        struct {
            uint8_t version : 4;
            uint8_t length : 4;
        };
    };
    uint8_t type_of_service; // 0x1
    uint16_t total_length; // 0x2
    uint16_t id; // 0x4
    union {
        uint16_t offset; // 0x6
        struct {
            uint16_t __zero : 1;
            uint16_t dont_fragment : 1;
            uint16_t more_fragments : 1;
            uint16_t fragment_offset : 13;
        };
    };
    uint8_t time_to_live; // 0x8
    uint8_t protocol; // 0x9
    uint16_t checksum; // 0xA
    in_addr source; // 0xC
    in_addr destination; // 0x10
    // 0x14
};

// size: 0x28
struct IPv6Header {
    union {
        uint32_t first_dword; // 0x0
        struct {
            uint32_t version : 4;
            uint32_t traffic_class : 8;
            uint32_t flow_label : 20;
        };
    };
    uint16_t payload_length; // 0x4
    uint8_t next_header; // 0x6
    uint8_t hop_limit; // 0x7
    in6_addr source; // 0x8
    in6_addr destination; // 0x18
    // 0x28
};

// size: 0x8
struct ICMPHeader {
    uint8_t type; // 0x0
    uint8_t subtype; // 0x1
    uint16_t checksum; // 0x2
    union {
        uint32_t header_data; // 0x4
        struct {
            uint16_t id; // 0x4
            uint16_t sequence_number; // 0x6
        } ping;
    };
    // 0x8
};

enum SocketType : uint8_t {
    TCP,
    UDP,
    ICMP
};

static inline constexpr bool is_ipv6_compatible_with_ipv4(const IP6_ADDRESS& addr) {
    return addr.IP6Dword[0] == 0 && addr.IP6Dword[1] == 0 && addr.IP6Dword[2] == 0xFFFF0000;
}

static inline constexpr IP6_ADDRESS map_ipv4_to_ipv6(IP4_ADDRESS addr) {
    return (IP6_ADDRESS) {
        .IP6Dword = {
            0x00000000, 0x00000000, 0xFFFF0000, addr
        }
    };
}

static inline constexpr IP6_ADDRESS map_ip_to_ipv6(const sockaddr* addr) {
    switch (addr->sa_family) {
        case AF_INET:
            return map_ipv4_to_ipv6(*(const IP4_ADDRESS*)&((const sockaddr_in*)addr)->sin_addr);
        case AF_INET6:
            return *(const IP6_ADDRESS*)&((const sockaddr_in6*)addr)->sin6_addr;
        [[unlikely]] default:
            return {};
    }
}

static inline constexpr bool map_ipv6_to_ipv4(const IP6_ADDRESS& addr, IP4_ADDRESS& out) {
    if (is_ipv6_compatible_with_ipv4(addr)) {
        out = addr.IP6Dword[3];
        return true;
    }
    return false;
}

static inline constexpr bool map_ip_to_ipv4(const sockaddr* addr, IP4_ADDRESS& out) {
    switch (addr->sa_family) {
        case AF_INET:
            out = *(const IP4_ADDRESS*)&((const sockaddr_in*)addr)->sin_addr;
            return true;
        case AF_INET6:
            return map_ipv6_to_ipv4(*(const IP6_ADDRESS*)&((const sockaddr_in6*)addr)->sin6_addr, out);
        [[unlikely]] default:
            return false;
    }
}

template <bool byte_order_matters = true>
static in_port_t get_port(const sockaddr* addr) {
    in_port_t port = 0;
    switch (addr->sa_family) {
        case AF_INET:
            port = ((const sockaddr_in*)addr)->sin_port;
            break;
        case AF_INET6:
            port = ((const sockaddr_in6*)addr)->sin6_port;
            break;
    }
    if constexpr (byte_order_matters) {
        return ntoh(port);
    } else {
        return port;
    }
}

static inline constexpr size_t MAX_ADDR_BUFF_SIZE = (std::max)(INET_ADDRSTRLEN, INET6_ADDRSTRLEN);

static void print_ipv4_full(IP4_ADDRESS addr) {
    union {
        uint32_t temp;
        uint8_t as_bytes[4];
    };
    temp = addr;
    printf(
        "v4: %u.%u.%u.%u"
        , as_bytes[0], as_bytes[1], as_bytes[2], as_bytes[3]
    );
}

static int print_ipv4(IP4_ADDRESS addr) {
    union {
        uint32_t temp;
        uint8_t as_bytes[4];
    };
    temp = addr;
    return printf(
        "%u.%u.%u.%u"
        , as_bytes[0], as_bytes[1], as_bytes[2], as_bytes[3]
    );
}

template<typename T>
static int sprint_ipv4(T* buf, IP4_ADDRESS addr) {
    T* buf_write = buf;
#if !ZNET_SIZE_OPTIMIZE_PRINTS
    buf_write += uint8_to_strbuf(addr, buf_write);
    *buf_write++ = (T)'.';
    addr >>= 8;
    buf_write += uint8_to_strbuf(addr, buf_write);
    *buf_write++ = (T)'.';
    addr >>= 8;
    buf_write += uint8_to_strbuf(addr, buf_write);
    *buf_write++ = (T)'.';
    addr >>= 8;
    buf_write += uint8_to_strbuf(addr, buf_write);
#else
    size_t i = 4;
    while (true) {
        buf_write += uint8_to_strbuf(addr, buf_write);
        if (--i == 0) break;
        *buf_write++ = (T)'.';
        addr >>= 8;
    }
#endif
    return buf_write - buf;
}

static void print_ipv6_full(const IP6_ADDRESS& addr) {
    printf(
        "v6: %0hX:%0hX:%0hX:%0hX:%0hX:%0hX:%0hX:%0hX"
        , ntoh(addr.IP6Word[0]), ntoh(addr.IP6Word[1])
        , ntoh(addr.IP6Word[2]), ntoh(addr.IP6Word[3])
        , ntoh(addr.IP6Word[4]), ntoh(addr.IP6Word[5])
        , ntoh(addr.IP6Word[6]), ntoh(addr.IP6Word[7])
    );
    if (is_ipv6_compatible_with_ipv4(addr)) {
        printf(" ");
        print_ipv4(addr.IP6Dword[3]);
    }
}

static int print_ipv6(const IP6_ADDRESS& addr) {
    if (is_ipv6_compatible_with_ipv4(addr)) {
        return print_ipv4(addr.IP6Dword[3]);
    }
    else {
        return printf(
            "%0hX:%0hX:%0hX:%0hX:%0hX:%0hX:%0hX:%0hX"
            , ntoh(addr.IP6Word[0]), ntoh(addr.IP6Word[1])
            , ntoh(addr.IP6Word[2]), ntoh(addr.IP6Word[3])
            , ntoh(addr.IP6Word[4]), ntoh(addr.IP6Word[5])
            , ntoh(addr.IP6Word[6]), ntoh(addr.IP6Word[7])
        );
    }
}

template<typename T>
static int sprint_ipv6(T* buf, const IP6_ADDRESS& addr) {
    T* buf_write = buf;
#if !ZNET_SIZE_OPTIMIZE_PRINTS
    buf_write += uint16_to_hex_strbuf(ntoh(addr.IP6Word[0]), buf_write);
    *buf_write++ = (T)':';
    buf_write += uint16_to_hex_strbuf(ntoh(addr.IP6Word[1]), buf_write);
    *buf_write++ = (T)':';
    buf_write += uint16_to_hex_strbuf(ntoh(addr.IP6Word[2]), buf_write);
    *buf_write++ = (T)':';
    buf_write += uint16_to_hex_strbuf(ntoh(addr.IP6Word[3]), buf_write);
    *buf_write++ = (T)':';
    buf_write += uint16_to_hex_strbuf(ntoh(addr.IP6Word[4]), buf_write);
    *buf_write++ = (T)':';
    buf_write += uint16_to_hex_strbuf(ntoh(addr.IP6Word[5]), buf_write);
    *buf_write++ = (T)':';
    buf_write += uint16_to_hex_strbuf(ntoh(addr.IP6Word[6]), buf_write);
    *buf_write++ = (T)':';
    buf_write += uint16_to_hex_strbuf(ntoh(addr.IP6Word[7]), buf_write);
#else
    size_t i = 0;
    nounroll while (true) {
        buf_write += uint16_to_hex_strbuf(ntoh(addr.IP6Word[i]), buf_write);
        if (++i == 8) break;
        *buf_write++ = (T)':';
    }
#endif
    return buf_write - buf;
}

template <typename T>
static int sprint_ip(T* buf, bool is_ipv6, const void* addr) {
    IP4_ADDRESS ip4;
    if (is_ipv6) {
        const IP6_ADDRESS& ip6 = *(const IP6_ADDRESS*)addr;
        if (!is_ipv6_compatible_with_ipv4(ip6)) {
            return sprint_ipv6(buf, ip6);
        }
        ip4 = ip6.IP6Dword[3];
    } else {
        ip4 = *(IP4_ADDRESS*)addr;
    }
    return sprint_ipv4(buf, ip4);
}

template <typename T>
static int sprint_ip_and_port(T* buf, bool is_ipv6, const void* addr, uint16_t port) {
    int addr_len = sprint_ip(buf, is_ipv6, addr);
    buf[addr_len++] = (T)':';
    return addr_len + uint16_to_strbuf(port, buf + addr_len);;
}

static void print_sockaddr_full(const sockaddr* addr) {
    switch (addr->sa_family) {
        case AF_INET:
            print_ipv4_full(*(IP4_ADDRESS*)&((const sockaddr_in*)addr)->sin_addr);
            break;
        case AF_INET6:
            print_ipv6_full(*(IP6_ADDRESS*)&((const sockaddr_in6*)addr)->sin6_addr);
            break;
    }
}

static int print_sockaddr(const sockaddr* addr) {
    switch (addr->sa_family) {
        case AF_INET:
            return print_ipv4(*(IP4_ADDRESS*)&((const sockaddr_in*)addr)->sin_addr);
        case AF_INET6:
            return print_ipv6(*(IP6_ADDRESS*)&((const sockaddr_in6*)addr)->sin6_addr);
        default:
            return 0;
    }
}

template<typename T>
static int sprint_sockaddr(const sockaddr* addr, T* buf) {
    switch (addr->sa_family) {
        case AF_INET:
            return sprint_ipv4(buf, *(IP4_ADDRESS*)&((const sockaddr_in*)addr)->sin_addr);
        case AF_INET6:
            return sprint_ipv6(buf, *(IP6_ADDRESS*)&((const sockaddr_in6*)addr)->sin6_addr);
        default:
            return 0;
    }
}

struct ipaddr_any {
    sa_family_t family;
    in_port_t port;
    union {
        IP4_ADDRESS ipv4;
        IP6_ADDRESS ipv6;
    };

    ipaddr_any() = default;

    ipaddr_any(bool is_ipv6, in_port_t port, const void* ip)
        : family(is_ipv6 ? AF_INET6 : AF_INET), port(hton(port))
    {
        if (is_ipv6) {
            this->ipv6 = *(IP6_ADDRESS*)ip;

        }
        else {
            this->ipv4 = *(IP4_ADDRESS*)ip;
        }
    }

    bool compatible_with_ipv4() const {
        switch (this->family) {
            case AF_INET6:
                if (is_ipv6_compatible_with_ipv4(this->ipv6)) {
            case AF_INET:
                    return true;
                }
            default:
                return false;
        }
    }

    const IP4_ADDRESS* compatible_ipv4() const {
        switch (this->family) {
            case AF_INET:
                return &this->ipv4;
            case AF_INET6:
                if (is_ipv6_compatible_with_ipv4(this->ipv6)) {
                    return &this->ipv6.IP6Dword[3];
                }
            default:
                return NULL;
        }
    }
};

template <bool byte_order_matters = true>
static in_port_t get_port(const ipaddr_any& addr) {
    if constexpr (byte_order_matters) {
        return ntoh(addr.port);
    } else {
        return addr.port;
    }
}

struct sockaddr_any {
    sockaddr_storage storage;
    usocklen_t length;

    sockaddr_any() = default;

    sockaddr_any(const sockaddr* addr, usocklen_t length) : length(length) {
        memcpy(&this->storage, addr, length);
    }

    sockaddr_any(bool is_ipv6, in_port_t port, const void* ip) {
        if (is_ipv6) {
            *(sockaddr_in6*)&this->storage = {
                .sin6_family = AF_INET6,
                .sin6_port = hton(port),
                .sin6_addr = *(in6_addr*)ip
            };
            this->length = sizeof(sockaddr_in6);
        } else {
            *(sockaddr_in*)&this->storage = {
                .sin_family = AF_INET,
                .sin_port = hton(port),
                .sin_addr = *(in_addr*)ip
            };
            this->length = sizeof(sockaddr_in);
        }
    }

    sockaddr_any(bool is_ipv6, in_port_t port, const char* ip) {
        this->storage = {};
        if (is_ipv6) {
            this->storage.ss_family = AF_INET6;
            ((sockaddr_in6*)&this->storage)->sin6_port = hton(port);
            ::inet_pton(AF_INET6, ip, &((sockaddr_in6*)&this->storage)->sin6_addr);
            this->length = sizeof(sockaddr_in6);
        } else {
            this->storage.ss_family = AF_INET;
            ((sockaddr_in*)&this->storage)->sin_port = hton(port);
            ::inet_pton(AF_INET, ip, &((sockaddr_in*)&this->storage)->sin_addr);
            this->length = sizeof(sockaddr_in);
        }
    }

    void initialize(const sockaddr* addr, usocklen_t length) {
        memcpy(&this->storage, addr, this->length = length);
    }

    void initialize_v4_to_v6(const sockaddr* addr) {
        this->length = sizeof(sockaddr_in6);
        const sockaddr_in* addr4 = (const sockaddr_in*)addr;
        IP6_ADDRESS temp = map_ipv4_to_ipv6(*(IP4_ADDRESS*)&addr4->sin_addr);
        *(sockaddr_in6*)&this->storage = {
            .sin6_family = AF_INET6,
            .sin6_port = addr4->sin_port,
            .sin6_addr = *(in6_addr*)&temp
        };
    }

    operator sockaddr*() const {
        return (sockaddr*)&this->storage;
    }

    void* get_ip_ptr() const {
        switch (this->storage.ss_family) {
            default:
                return NULL;
            case AF_INET:
                return (void*)&((const sockaddr_in*)&this->storage)->sin_addr;
            case AF_INET6:
                return (void*)&((const sockaddr_in6*)&this->storage)->sin6_addr;
        }
    }

    ipaddr_any get_ip() const {
        ipaddr_any ret;
        switch (this->storage.ss_family) {
            default:
                return {};
            case AF_INET:
                ret.ipv4 = *(IP4_ADDRESS*)&((const sockaddr_in*)&this->storage)->sin_addr;
                break;
            case AF_INET6:
                ret.ipv6 = *(IP6_ADDRESS*)&((const sockaddr_in6*)&this->storage)->sin6_addr;
                break;
        }
        ret.family = this->storage.ss_family;
        ret.port = get_port(*this);
        return ret;
    }

    void store_ip(void* out) const {
        switch (this->storage.ss_family) {
            case AF_INET:
                *(IP4_ADDRESS*)out = *(IP4_ADDRESS*)&((const sockaddr_in*)&this->storage)->sin_addr;
                break;
            case AF_INET6:
                *(IP6_ADDRESS*)out = *(IP6_ADDRESS*)&((const sockaddr_in6*)&this->storage)->sin6_addr;
                break;
        }
    }

    bool is_ipv4() const {
        return this->storage.ss_family == AF_INET;
    }

    bool is_ipv6() const {
        return this->storage.ss_family == AF_INET6;
    }
};

static inline bool ips_match(const sockaddr_any& lhs, const sockaddr_any& rhs) {
    if (lhs.storage.ss_family == rhs.storage.ss_family) {
        switch (lhs.storage.ss_family) {
            case AF_INET:
                return !memcmp(
                    &((const sockaddr_in*)&lhs.storage)->sin_addr,
                    &((const sockaddr_in*)&rhs.storage)->sin_addr,
                    sizeof(IP4_ADDRESS)
                );
            case AF_INET6:
                return !memcmp(
                    &((const sockaddr_in6*)&lhs.storage)->sin6_addr,
                    &((const sockaddr_in6*)&rhs.storage)->sin6_addr,
                    sizeof(IP6_ADDRESS)
                );
        }
    }
    return false;
}

static inline bool ips_match(const ipaddr_any& lhs, const ipaddr_any& rhs) {
    if (lhs.family == rhs.family) {
        switch (lhs.family) {
            case AF_INET:
                return !memcmp(&lhs.ipv4, &rhs.ipv4, sizeof(IP4_ADDRESS));
            case AF_INET6:
                return !memcmp(&lhs.ipv6, &rhs.ipv6, sizeof(IP6_ADDRESS));
        }
    }
    return false;
}

static inline bool ips_match(const sockaddr_any& lhs, const ipaddr_any& rhs) {
    if (lhs.storage.ss_family == rhs.family) {
        switch (lhs.storage.ss_family) {
            case AF_INET:
                return !memcmp(
                    &((const sockaddr_in*)&lhs.storage)->sin_addr,
                    &rhs.ipv4,
                    sizeof(IP4_ADDRESS)
                );
            case AF_INET6:
                return !memcmp(
                    &((const sockaddr_in6*)&lhs.storage)->sin6_addr,
                    &rhs.ipv6,
                    sizeof(IP6_ADDRESS)
                );
        }
    }
    return false;
}

static inline bool ips_match(const ipaddr_any& lhs, const sockaddr_any& rhs) {
    return ips_match(rhs, lhs);
}

static inline bool ports_match(const sockaddr_any& lhs, const sockaddr_any& rhs) {
    return get_port<false>(lhs) == get_port<false>(rhs);
}

static inline bool ports_match(const ipaddr_any& lhs, const ipaddr_any& rhs) {
    return get_port<false>(lhs) == get_port<false>(rhs);
}

static inline bool ports_match(const sockaddr_any& lhs, const ipaddr_any& rhs) {
    return get_port<false>(lhs) == get_port<false>(rhs);
}

static inline bool ports_match(const ipaddr_any& lhs, const sockaddr_any& rhs) {
    return get_port<false>(lhs) == get_port<false>(rhs);
}

#if _WIN32
static inline DNS_STATUS WINAPI dns_query(PCSTR pszName, WORD wType, DWORD Options, PVOID pExtra, PDNS_RECORDA* ppQueryResults, PVOID* pReserved) {
    return ::DnsQuery_A(pszName, wType, Options, pExtra, (PDNS_RECORD*)ppQueryResults, pReserved);
}
static inline DNS_STATUS WINAPI dns_query(PCWSTR pszName, WORD wType, DWORD Options, PVOID pExtra, PDNS_RECORDW* ppQueryResults, PVOID* pReserved) {
    return ::DnsQuery_W(pszName, wType, Options, pExtra, (PDNS_RECORD*)ppQueryResults, pReserved);
}
static inline const wchar_t* inet_ntop(int Family, const void* pAddr, wchar_t* pStringBuf, size_t StringBufSize) {
    return ::InetNtopW(Family, pAddr, pStringBuf, StringBufSize);
}
#endif


template <size_t N>
static inline const char* inet_ntop(int Family, const void* pAddr, char(&str)[N]) {
    return ::inet_ntop(Family, pAddr, str, N);
}

#if _WIN32
template <size_t N>
static inline const wchar_t* inet_ntop(int Family, const void* pAddr, wchar_t(&str)[N]) {
    return ::InetNtopW(Family, pAddr, str, N);
}
static inline int inet_pton(int Family, const wchar_t* pszAddrString, void* pAddrBuf) {
    return ::InetPtonW(Family, pszAddrString, pAddrBuf);
}

static inline int getaddrinfo(const wchar_t* pNodeName, const wchar_t* pServiceName, const ADDRINFOW* pHints, PADDRINFOW* ppResult) {
    return ::GetAddrInfoW(pNodeName, pServiceName, pHints, ppResult);
}
static inline void freeaddrinfo(PADDRINFOW pAddrInfo) {
    return ::FreeAddrInfoW(pAddrInfo);
}

// GetAddrInfoW just crashes for some reason when trying to
// resolve a URL on Windows 7, so the DNS resolution needs
// to be done manually.
// THIS IS DUMB

template <typename T, size_t N> requires(N >= INET_ADDRSTRLEN)
static bool resolve_ipv4_address(const T* server_name, T(&addr_buff)[N]) {
    using PDNS_RECORD = std::conditional_t<std::is_same_v<T, wchar_t>, PDNS_RECORDW, PDNS_RECORDA>;

    PDNS_RECORD records;
    if (expect(dns_query(server_name, DNS_TYPE_A, DNS_QUERY_STANDARD, NULL, &records, NULL) == 0, true)) {
        PDNS_RECORD cur_record = records;
        do {
            switch (cur_record->wType) {
                [[unlikely]] default:
                case DNS_TYPE_CNAME: case DNS_TYPE_AAAA:
                    break;
                case DNS_TYPE_A:
                    inet_ntop(AF_INET, &cur_record->Data.A.IpAddress, addr_buff);
                    goto found_addr;
            }
        } while ((cur_record = cur_record->pNext));
        ::DnsFree(records, DnsFreeRecordList);
    }
    return false;

found_addr:
    ::DnsFree(records, DnsFreeRecordList);
    return true;
}

template <typename T, size_t N> requires(N >= INET6_ADDRSTRLEN)
static bool resolve_ipv6_address(const T* server_name, T(&addr_buff)[N]) {
    using PDNS_RECORD = std::conditional_t<std::is_same_v<T, wchar_t>, PDNS_RECORDW, PDNS_RECORDA>;

    PDNS_RECORD records;
    if (expect(dns_query(server_name, DNS_TYPE_AAAA, DNS_QUERY_STANDARD, NULL, &records, NULL) == 0, true)) {
        PDNS_RECORD cur_record = records;
        do {
            switch (cur_record->wType) {
                [[unlikely]] default:
                case DNS_TYPE_CNAME: case DNS_TYPE_A:
                    break;
                case DNS_TYPE_AAAA:
                    inet_ntop(AF_INET6, &cur_record->Data.AAAA.Ip6Address, addr_buff);
                    goto found_addr;
            }
        } while ((cur_record = cur_record->pNext));
        ::DnsFree(records, DnsFreeRecordList);
    }
    return false;

found_addr:
    ::DnsFree(records, DnsFreeRecordList);
    return true;
}

template <typename T, size_t N> requires(N >= MAX_ADDR_BUFF_SIZE)
static bool resolve_address(const T* server_name, T(&addr_buff)[N]) {
#if ZNET_IPV6_MODES(ZNET_DISABLE_IPV6)
    return resolve_ipv4_address(server_name, addr_buff);
#endif

#if ZNET_IPV6_MODES(ZNET_REQUIRE_IPV6 | ZNET_DONT_REQUIRE_IPV6)
    using PDNS_RECORD = std::conditional_t<std::is_same_v<T, wchar_t>, PDNS_RECORDW, PDNS_RECORDA>;

    WORD type = DNS_TYPE_AAAA;
    DWORD options = DNS_QUERY_DUAL_ADDR;
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6)
    if (!expect(enable_ipv6, true)) {
        type = DNS_TYPE_A;
        options = DNS_QUERY_STANDARD;
    }
#endif
    PDNS_RECORD records;
    if (expect(dns_query(server_name, type, options, NULL, &records, NULL) == 0, true)) {
        PDNS_RECORD cur_record = records;
        do {
            switch (cur_record->wType) {
                [[unlikely]] default:
                case DNS_TYPE_CNAME:
                    break;
                case DNS_TYPE_AAAA:
                    inet_ntop(AF_INET6, &cur_record->Data.AAAA.Ip6Address, addr_buff);
                    goto found_addr;
                case DNS_TYPE_A:
                    IP6_ADDRESS ipv6 = map_ipv4_to_ipv6(cur_record->Data.A.IpAddress);
                    inet_ntop(AF_INET6, &ipv6, addr_buff);
                    goto found_addr;
            }
        } while ((cur_record = cur_record->pNext));
        ::DnsFree(records, DnsFreeRecordList);
    }
    return false;

found_addr:
    ::DnsFree(records, DnsFreeRecordList);
    return true;
#endif
}
#endif

static void print_sockaddr_full(const sockaddr_any& addr) {
    switch (addr.storage.ss_family) {
        case AF_INET:
            print_ipv4_full(*(IP4_ADDRESS*)&((const sockaddr_in*)&addr.storage)->sin_addr);
            break;
        case AF_INET6:
            print_ipv6_full(*(IP6_ADDRESS*)&((const sockaddr_in6*)&addr.storage)->sin6_addr);
            break;
    }
}

static int print_sockaddr(const sockaddr_any& addr) {
    switch (addr.storage.ss_family) {
        case AF_INET:
            return print_ipv4(*(IP4_ADDRESS*)&((const sockaddr_in*)&addr.storage)->sin_addr);
        case AF_INET6:
            return print_ipv6(*(IP6_ADDRESS*)&((const sockaddr_in6*)&addr.storage)->sin6_addr);
        default:
            return 0;
    }
}

template<typename T>
static int sprint_sockaddr(const sockaddr_any& addr, T(&buf)[MAX_ADDR_BUFF_SIZE]) {
    switch (addr.storage.ss_family) {
        case AF_INET:
            return sprint_ipv4(buf, *(IP4_ADDRESS*)&((const sockaddr_in*)&addr.storage)->sin_addr);
        case AF_INET6:
            return sprint_ipv6(buf, *(IP6_ADDRESS*)&((const sockaddr_in6*)&addr.storage)->sin6_addr);
        default:
            return 0;
    }
}

template<SocketType>
static inline SOCKET socket(int af);

template<>
inline SOCKET socket<TCP>(int af) {
    return ::socket(af, SOCK_STREAM, IPPROTO_TCP);
}

template<>
inline SOCKET socket<UDP>(int af) {
    return ::socket(af, SOCK_DGRAM, IPPROTO_UDP);
}

template<>
inline SOCKET socket<ICMP>(int af) {
    return ::socket(af, SOCK_RAW, IPPROTO_ICMP);
}

template<typename T>
static inline int setsockopt(SOCKET s, int level, int optname, const T& optval) {
    return ::setsockopt(s, level, optname, (const char*)&optval, sizeof(optval));
}

template<typename T>
static inline int getsockopt(SOCKET s, int level, int optname, T& optval) {
    socklen_t optlen = sizeof(T);
    return ::getsockopt(s, level, optname, (char*)&optval, &optlen);
}

template<typename T>
static inline int connect(SOCKET s, const T& addr) {
    return ::connect(s, (const sockaddr*)&addr, sizeof(addr));
}

static inline int connect(SOCKET s, const sockaddr_any& addr) {
    return ::connect(s, addr, addr.length);
}

template<typename T>
static inline int bind(SOCKET s, const T& addr) {
    return ::bind(s, (const sockaddr*)&addr, sizeof(addr));
}

static inline int bind(SOCKET s, const sockaddr_any& addr) {
    return ::bind(s, addr, addr.length);
}

static inline int bind_ipv6(SOCKET s, const IP6_ADDRESS& ip, in_port_t local_port) {
    sockaddr_in6 local = {
        .sin6_family = AF_INET6,
        .sin6_port = hton(local_port),
        .sin6_addr = *(const in6_addr*)&ip
    };
    return bind(s, local);
}

static inline int bind_ipv4(SOCKET s, IP4_ADDRESS ip, in_port_t local_port) {
    sockaddr_in local = {
        .sin_family = AF_INET,
        .sin_port = hton(local_port),
        .sin_addr = ip
    };
    return bind(s, local);
}

static inline int bind(SOCKET s, const IP6_ADDRESS& ip, in_port_t local_port) {
#if ZNET_IPV6_MODES(ZNET_REQUIRE_IPV6 | ZNET_REQUIRE_IPV6)
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6)
    if (expect(enable_ipv6, true))
#endif
    {
        return bind_ipv6(s, ip, local_port);
    }
#endif
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6 | ZNET_DISABLE_IPV6)
    if (is_ipv6_compatible_with_ipv4(ip)) {
        return bind_ipv4(s, ip.IP6Dword[3], local_port);
    }
    return -1;
#endif
}

static inline int bind(SOCKET s, const IP4_ADDRESS& ip, in_port_t local_port) {
#if ZNET_IPV6_MODES(ZNET_REQUIRE_IPV6 | ZNET_REQUIRE_IPV6)
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6)
    if (expect(enable_ipv6, true))
#endif
    {
        return bind_ipv6(s, map_ipv4_to_ipv6(ip), local_port);
    }
#endif
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6 | ZNET_DISABLE_IPV6)
    return bind_ipv4(s, ip, local_port);
#endif
}

static inline int bind(SOCKET s, in_port_t local_port) {
#if ZNET_IPV6_MODES(ZNET_REQUIRE_IPV6 | ZNET_REQUIRE_IPV6)
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6)
    if (expect(enable_ipv6, true))
#endif
    {
        return bind_ipv6(s, IN6ADDR_ANY_INIT, local_port);
    }
#endif
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6 | ZNET_DISABLE_IPV6)
    return bind_ipv4(s, INADDR_ANY, local_port);
#endif
}

template<typename T> requires(!std::is_pointer_v<T>)
static inline int send(SOCKET s, const T& data, int flags) {
    return ::send(s, (const char*)&data, sizeof(T), flags);
}

template<typename T>
static inline int send(SOCKET s, const T* data, int flags) {
    return ::send(s, (const char*)data, sizeof(T), flags);
}

template<typename T> requires(!std::is_pointer_v<T>)
static inline int sendto(SOCKET s, const T& data, int flags, const sockaddr* to, int tolen) {
    return ::sendto(s, (const char*)&data, sizeof(T), flags, to, tolen);
}

template<typename T>
static inline int sendto(SOCKET s, const T* data, int flags, const sockaddr* to, int tolen) {
    return ::sendto(s, (const char*)data, sizeof(T), flags, to, tolen);
}

template<typename T> requires(!std::is_pointer_v<T>)
static inline int recv(SOCKET s, T& data, int flags) {
    return ::recv(s, (char*)&data, sizeof(T), flags);
}

template<typename T>
static inline int recv(SOCKET s, T* data, int flags) {
    return ::recv(s, (char*)data, sizeof(T), flags);
}

template<typename T> requires(!std::is_pointer_v<T>)
static inline int recvfrom(SOCKET s, T& data, int flags, sockaddr* from, socklen_t* fromlen) {
    return ::recvfrom(s, (char*)&data, sizeof(T), flags, from, fromlen);
}

template<typename T>
static inline int recvfrom(SOCKET s, T* data, int flags, sockaddr* from, socklen_t* fromlen) {
    return ::recvfrom(s, (char*)data, sizeof(T), flags, from, fromlen);
}

static inline SOCKET accept(SOCKET s, sockaddr_any& addr) {
    addr.length = sizeof(addr.storage);
    return ::accept(s, addr, (socklen_t*)&addr.length);
}

static inline int getpeername(SOCKET s, sockaddr_any& addr) {
    addr.length = sizeof(addr.storage);
    return ::getpeername(s, addr, (socklen_t*)&addr.length);
}

static inline int getsockname(SOCKET s, sockaddr_any& addr) {
    addr.length = sizeof(addr.storage);
    return ::getsockname(s, addr, (socklen_t*)&addr.length);
}

template<typename T> requires(!std::is_pointer_v<T>)
static inline int sendto(SOCKET s, const T& data, int flags, const sockaddr_any& to) {
    return ::sendto(s, (const char*)&data, sizeof(T), flags, to, to.length);
}

template<typename T>
static inline int sendto(SOCKET s, const T* data, int flags, const sockaddr_any& to) {
    return ::sendto(s, (const char*)data, sizeof(T), flags, to, to.length);
}

static inline int sendto(SOCKET s, const char* buf, int len, int flags, const sockaddr_any& to) {
    return ::sendto(s, buf, len, flags, to, to.length);
}

template<typename T> requires(!std::is_pointer_v<T>)
static inline int recvfrom(SOCKET s, T& data, int flags, sockaddr_any& from) {
    from.length = sizeof(from.storage);
    return ::recvfrom(s, (char*)&data, sizeof(T), flags, from, (socklen_t*)&from.length);
}

template<typename T>
static inline int recvfrom(SOCKET s, T* data, int flags, sockaddr_any& from) {
    from.length = sizeof(from.storage);
    return ::recvfrom(s, (char*)data, sizeof(T), flags, from, (socklen_t*)&from.length);
}

static inline int recvfrom(SOCKET s, char* buf, int len, int flags, sockaddr_any& from) {
    from.length = sizeof(from.storage);
    return ::recvfrom(s, buf, len, flags, from, (socklen_t*)&from.length);
}

template<typename S>
struct SocketBase {
    SOCKET sock = INVALID_SOCKET; // 0x0

    inline constexpr SocketBase() = default;
    inline constexpr SocketBase(SOCKET sock) : sock(sock) {};

    inline operator bool() const {
        return this->sock != INVALID_SOCKET;
    }

    inline bool operator!() const {
        return this->sock == INVALID_SOCKET;
    }

    inline operator SOCKET() const {
        return this->sock;
    }

protected:

    static inline constexpr ADDRINFOA tcp_addr_hint_a = {
#if _WIN32
        .ai_flags = AI_NUMERICHOST | AI_NUMERICSERV,
#else
        .ai_flags = AI_NUMERICSERV,
#endif
        .ai_family = AF_UNSPEC,
        .ai_socktype = SOCK_STREAM,
        .ai_protocol = IPPROTO_TCP
    };

    static inline constexpr ADDRINFOA udp_addr_hint_a = {
#if _WIN32
        .ai_flags = AI_NUMERICHOST | AI_NUMERICSERV,
#else
        .ai_flags = AI_NUMERICSERV,
#endif
        .ai_family = AF_UNSPEC,
        .ai_socktype = SOCK_DGRAM,
        .ai_protocol = IPPROTO_UDP
    };

    static inline constexpr ADDRINFOA icmp_addr_hint_a = {
#if _WIN32
        .ai_flags = AI_NUMERICHOST | AI_NUMERICSERV,
#else
        .ai_flags = AI_NUMERICSERV,
#endif
        .ai_family = AF_UNSPEC,
        .ai_socktype = SOCK_RAW,
        .ai_protocol = IPPROTO_ICMP
    };

#if ZNET_SUPPORT_WCHAR
    static inline constexpr ADDRINFOW tcp_addr_hint_w = {
#if _WIN32
        .ai_flags = AI_NUMERICHOST | AI_NUMERICSERV,
#else
        .ai_flags = AI_NUMERICSERV,
#endif
        .ai_family = AF_UNSPEC,
        .ai_socktype = SOCK_STREAM,
        .ai_protocol = IPPROTO_TCP
    };

    static inline constexpr ADDRINFOW udp_addr_hint_w = {
#if _WIN32
        .ai_flags = AI_NUMERICHOST | AI_NUMERICSERV,
#else
        .ai_flags = AI_NUMERICSERV,
#endif
        .ai_family = AF_UNSPEC,
        .ai_socktype = SOCK_DGRAM,
        .ai_protocol = IPPROTO_UDP
    };

    static inline constexpr ADDRINFOW icmp_addr_hint_w = {
#if _WIN32
        .ai_flags = AI_NUMERICHOST | AI_NUMERICSERV,
#else
        .ai_flags = AI_NUMERICSERV,
#endif
        .ai_family = AF_UNSPEC,
        .ai_socktype = SOCK_RAW,
        .ai_protocol = IPPROTO_ICMP
    };
#endif

public:

    template<SocketType socket_type>
    bool initialize() {
#if ZNET_IPV6_MODES(ZNET_REQUIRE_IPV6 | ZNET_DONT_REQUIRE_IPV6)
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6)
        if (expect(enable_ipv6, true))
#endif
        {
            SOCKET sock = zero::net::socket<socket_type>(AF_INET6);
            if (expect(sock != INVALID_SOCKET, true)) {
                zero::net::setsockopt(sock, IPPROTO_IPV6, IPV6_V6ONLY, FALSE);
                this->sock = sock;
                return true;
            }
        }
#endif
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6 | ZNET_DISABLE_IPV6)
        SOCKET sock = zero::net::socket<socket_type>(AF_INET);
        if (expect(sock != INVALID_SOCKET, true)) {
            this->sock = sock;
            return true;
        }
#endif
        return false;
    }

protected:

    inline void close_secondary() {}

public:

    void close() {
        SOCKET sock = this->sock;
        if (sock != INVALID_SOCKET) {
#if _WIN32
            ::closesocket(sock);
#else
            ::close(sock);
#endif
            this->sock = INVALID_SOCKET;
            ((S*)this)->close_secondary();
        }
    }

protected:

    inline bool connect_secondary(const char* server_name) {
        return true;
    }

    inline bool connect_secondary(const wchar_t* server_name) {
        return true;
    }

    template<SocketType socket_type, typename T>
    bool connect_ip_impl(const T* server_name, const T* port_str, const T* ip) const {
        ZNET_WCHAR_TEST(T);

#if ZNET_SUPPORT_WCHAR
        using ADDRINFO = std::conditional_t<std::is_same_v<T, wchar_t>, ADDRINFOW, ADDRINFOA>;
#else
        using ADDRINFO = ADDRINFOA;
#endif

        const ADDRINFO* addr_hint;
#if ZNET_SUPPORT_WCHAR
        if constexpr (std::is_same_v<T, wchar_t>) {
            if constexpr (socket_type == TCP) {
                addr_hint = &tcp_addr_hint_w;
            } else if constexpr (socket_type == UDP) {
                addr_hint = &udp_addr_hint_w;
            } else if constexpr (socket_type == ICMP) {
                addr_hint = &icmp_addr_hint_w;
            }
        } else
#endif
        {
            if constexpr (socket_type == TCP) {
                addr_hint = &tcp_addr_hint_a;
            } else if constexpr (socket_type == UDP) {
                addr_hint = &udp_addr_hint_a;
            } else if constexpr (socket_type == ICMP) {
                addr_hint = &icmp_addr_hint_a;
            }
        }

        ADDRINFO* addrs;
        // GetAddrInfoW sucks
        if (expect(!getaddrinfo(ip, port_str, addr_hint, &addrs), true)) {
            ADDRINFO* cur_addr = addrs;
            do {
                switch (cur_addr->ai_family) {
                    case AF_INET6:
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6)
                        if (expect(enable_ipv6, true))
#endif
                        {
                    case AF_INET:
                            if (expect(::connect(this->sock, (const sockaddr*)cur_addr->ai_addr, cur_addr->ai_addrlen) == 0, true)) {
                                freeaddrinfo(addrs);
                                return ((S*)this)->connect_secondary(server_name);
                            } //else {
                                //printf("Error: %d\n", WSAGetLastError());
                            //}
                        }
                }
                //print_sockaddr(full_sock);
            } while ((cur_addr = cur_addr->ai_next));
            freeaddrinfo(addrs);
        }
        return false;
    }

    template<SocketType socket_type, typename T>
    bool connect_ipv6_impl(const T* server_name, const T* port_str, const T* ip) const {
        ZNET_WCHAR_TEST(T);

#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6 | ZNET_DISABLE_IPV6)
        T addr_buff[INET_ADDRSTRLEN];
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6)
        if (!expect(enable_ipv6, true))
#endif
        {
            IP6_ADDRESS ipv6;
#if ZNET_SUPPORT_WCHAR
            if constexpr (std::is_same_v<T, wchar_t>) {
                inet_pton(AF_INET6, ip, &ipv6);
            } else
#endif
            {
                ::inet_pton(AF_INET6, ip, &ipv6);
            }
            if (!is_ipv6_compatible_with_ipv4(ipv6)) {
                return false;
            }
            inet_ntop(AF_INET, &ipv6.IP6Dword[3], addr_buff);
            ip = addr_buff;
        }
#endif
        return this->connect_ip_impl<socket_type>(server_name, port_str, ip);
    }

    template<SocketType socket_type, typename T>
    bool connect_ipv4_impl(const T* server_name, const T* port_str, const T* ip) const {
        ZNET_WCHAR_TEST(T);

#if ZNET_IPV6_MODES(ZNET_REQUIRE_IPV6 | ZNET_DONT_REQUIRE_IPV6)
        T addr_buff[INET6_ADDRSTRLEN];
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6)
        if (expect(enable_ipv6, true))
#endif
        {
            IP6_ADDRESS ipv6 = (IP6_ADDRESS){
                .IP6Dword = {
                    0x00000000, 0x00000000, 0xFFFF0000, 0
                }
            };
#if ZNET_SUPPORT_WCHAR
            if constexpr (std::is_same_v<T, wchar_t>) {
                inet_pton(AF_INET, ip, &ipv6.IP6Dword[3]);
            } else
#endif
            {
                ::inet_pton(AF_INET, ip, &ipv6.IP6Dword[3]);
            }
            inet_ntop(AF_INET6, &ipv6, addr_buff);
            ip = addr_buff;
        }
#endif
        return this->connect_ip_impl<socket_type>(server_name, port_str, ip);
    }

public:

    bool connect(const sockaddr_any& addr) const {
        return zero::net::connect(this->sock, addr) == 0;
    }

    template<SocketType socket_type>
    bool connect_ipv4(const char* ip, const char* port_str) const {
        return this->connect_ipv4_impl<socket_type, char>(NULL, port_str, ip);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type>
    bool connect_ipv4(const wchar_t* ip, const wchar_t* port_str) const {
        return this->connect_ipv4_impl<socket_type, wchar_t>(NULL, port_str, ip);
    }
#endif

    template<SocketType socket_type>
    bool connect_ipv6(const char* ip, const char* port_str) const {
        return this->connect_ipv6_impl<socket_type, char>(NULL, port_str, ip);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type>
    bool connect_ipv6(const wchar_t* ip, const wchar_t* port_str) const {
        return this->connect_ipv6_impl<socket_type, wchar_t>(NULL, port_str, ip);
    }
#endif

    template<SocketType socket_type>
    bool connect_ip(const char* ip, const char* port_str) const {
        if (strchr(ip, '.')) {
            return this->connect_ipv4<socket_type>(ip, port_str);
        } else {
            return this->connect_ipv6<socket_type>(ip, port_str);
        }
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type>
    bool connect_ip(const wchar_t* ip, const wchar_t* port_str) const {
        if (wcschr(ip, L'.')) {
            return this->connect_ipv4<socket_type>(ip, port_str);
        } else {
            return this->connect_ipv6<socket_type>(ip, port_str);
        }
    }
#endif

    template<SocketType socket_type>
    bool connect(const char* server_name, const char* port_str) const {
#if _WIN32
        char addr_buff[MAX_ADDR_BUFF_SIZE];
        if (zero::net::resolve_address(server_name, addr_buff)) {
            return this->connect_ip_impl<socket_type>(server_name, port_str, addr_buff);
        }
        return false;
#else
        return this->connect_ip_impl<socket_type>(server_name, port_str, server_name);
#endif
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type>
    bool connect(const wchar_t* server_name, const wchar_t* port_str) const {
#if _WIN32
        wchar_t addr_buff[MAX_ADDR_BUFF_SIZE];
        if (zero::net::resolve_address(server_name, addr_buff)) {
            return this->connect_ip_impl<socket_type>(server_name, port_str, addr_buff);
        }
        return false;
#else
        return this->connect_ip_impl<socket_type>(server_name, port_str, server_name);
#endif
    }
#endif

protected:

    bool bind_ipv6(const IP6_ADDRESS& ip, in_port_t local_port) const {
        return zero::net::bind_ipv6(this->sock, ip, local_port) == 0;
    }

    bool bind_ipv4(const IP4_ADDRESS& ip, in_port_t local_port) const {
        return zero::net::bind_ipv4(this->sock, ip, local_port) == 0;
    }

public:

    bool bind(const IP6_ADDRESS& ip, in_port_t local_port) const {
        return zero::net::bind(this->sock, ip, local_port) == 0;
    }

    bool bind(const IP4_ADDRESS& ip, in_port_t local_port) const {
        return zero::net::bind(this->sock, ip, local_port) == 0;
    }

    bool bind(in_port_t local_port) const {
#if ZNET_IPV6_MODES(ZNET_REQUIRE_IPV6 | ZNET_REQUIRE_IPV6)
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6)
        if (expect(enable_ipv6, true))
#endif
        {
            return this->bind_ipv6(IN6ADDR_ANY_INIT, local_port);
        }
#endif
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6 | ZNET_DISABLE_IPV6)
        return this->bind_ipv4(INADDR_ANY, local_port);
#endif
    }

    bool listen(int limit) const {
        return ::listen(this->sock, limit) == 0;
    }

    template<typename T = S>
    T accept(sockaddr_any& addr) const {
        return { zero::net::accept(this->sock, addr) };
    }

    template<typename T = S>
    T accept() const {
        return { ::accept(this->sock, NULL, NULL) };
    }

    bool get_local_addr(sockaddr_any& addr) const {
        return zero::net::getsockname(this->sock, addr) == 0;
    }

    bool get_peer_addr(sockaddr_any& addr) const {
        return zero::net::getpeername(this->sock, addr) == 0;
    }

protected:
    inline size_t receive_impl(void* buffer, size_t recv_length) const {
        int recv_ret = ::recv(this->sock, (char*)buffer, recv_length, 0);
        if (expect(recv_ret <= 0, false)) {
            recv_ret = 0;
        }
        return recv_ret;
    }

    inline size_t receive_from_impl(void* buffer, size_t recv_length, sockaddr_any& addr) const {
        addr.length = sizeof(addr.storage);
        int recv_ret = ::recvfrom(this->sock, (char*)buffer, recv_length, 0, addr, (socklen_t*)&addr.length);
        if (expect(recv_ret <= 0, false)) {
            recv_ret = 0;
        }
        return recv_ret;
    }

public:

    size_t receive(void* buffer, size_t recv_length) const {
        return ((const S*)this)->receive_impl(buffer, recv_length);
    }

    size_t receive(void* buffer, size_t recv_length, sockaddr_any& addr) const {
        return ((const S*)this)->receive_from_impl(buffer, recv_length, addr);
    }

    template <typename T, size_t len>
    size_t receive_text(T(&buffer)[len]) const {
        size_t ret = this->receive(buffer, sizeof(buffer) - sizeof(T));
        buffer[ret] = (T)0;
        return ret;
    }

    template <typename T, size_t len>
    size_t receive_text(T(&buffer)[len], sockaddr_any& addr) const {
        size_t ret = this->receive(buffer, sizeof(buffer) - sizeof(T), addr);
        buffer[ret] = (T)0;
        return ret;
    }

    template <typename T>
    size_t receive(T& buffer) const {
        return this->receive(&buffer, sizeof(buffer));
    }

    template <typename T>
    size_t receive(T& buffer, sockaddr_any& addr) const {
        return this->receive(&buffer, sizeof(buffer), addr);
    }

    bool wait_for_incoming_data(size_t timeout) const {
        timeval time;
        time.tv_sec = timeout / 1000;
        time.tv_usec = (timeout % 1000) * 1000;

        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(this->sock, &fds);

        return ::select(0, &fds, NULL, NULL, &time) > 0;
    }

protected:

    inline size_t send_impl(const void* buffer, size_t send_length) const {
        size_t sent = 0;
        while (sent != send_length) {
            int send_ret = ::send(this->sock, &((char*)buffer)[sent], send_length - sent, 0);
            if (expect(send_ret <= 0, false)) {
                return 0;
            }
            sent += send_ret;
        }
        return sent;
    }

    inline size_t send_to_impl(const void* buffer, size_t send_length, const sockaddr_any& addr) const {
        size_t sent = 0;
        while (sent != send_length) {
            int send_ret = zero::net::sendto(this->sock, &((char*)buffer)[sent], send_length - sent, 0, addr);
            if (expect(send_ret <= 0, false)) {
                return 0;
            }
            sent += send_ret;
        }
        return sent;
    }

public:
    size_t send(const void* buffer, size_t send_length) const {
        return ((const S*)this)->send_impl(buffer, send_length);
    }

    size_t send(const void* buffer, size_t send_length, const sockaddr_any& addr) const {
        return ((const S*)this)->send_to_impl(buffer, send_length, addr);
    }

    template <typename T, size_t len>
    inline bool send_text(const T(&str)[len]) const {
        return this->send(&str[0], sizeof(str) - sizeof(T));
    }

    template <typename T, size_t len>
    inline bool send_text(const T(&str)[len], const sockaddr_any& addr) const {
        return this->send(&str[0], sizeof(str) - sizeof(T), addr);
    }

    template <typename T, size_t len>
    inline bool send_text(const T(&str)[len], size_t length) const {
        return this->send(&str[0], length);
    }

    template <typename T, size_t len>
    inline bool send_text(const T(&str)[len], size_t length, const sockaddr_any& addr) const {
        return this->send(&str[0], length, addr);
    }

    template <typename T>
    inline bool send_text(std::basic_string_view<T> str) const {
        return this->send(str.data(), str.length());
    }

    template <typename T>
    inline bool send_text(std::basic_string_view<T> str, const sockaddr_any& addr) const {
        return this->send(str.data(), str.length(), addr);
    }

    template <typename T>
    inline bool send_text(std::basic_string_view<T> str, size_t length) const {
        return this->send(str.data(), length);
    }

    template <typename T>
    inline bool send_text(std::basic_string_view<T> str, size_t length, const sockaddr_any& addr) const {
        return this->send(str.data(), length, addr);
    }

    template <typename T>
    inline bool send(const T& buffer) const {
        return this->send(&buffer, sizeof(T));
    }

    template <typename T>
    inline bool send(const T& buffer, const sockaddr_any& addr) const {
        return this->send(&buffer, sizeof(T), addr);
    }

    bool get_receive_timeout(size_t& timeout) const {
#if _WIN32
        DWORD timeout_val = 0;
#else
        timeval timeout_val = {};
#endif
        bool ret = zero::net::getsockopt(this->sock, SOL_SOCKET, SO_RCVTIMEO, timeout_val) == 0;
#if _WIN32
        timeout = timeout_val;
#else
        timeout = timeout_val.tv_sec * 1000 + timeout_val.tv_usec / 1000;
#endif
        return ret;
    }

    bool set_receive_timeout(size_t timeout) const {
#if _WIN32
        DWORD timeout_val = (DWORD)timeout;
#else
        timeval timeout_val;
        timeout_val.tv_sec = timeout / 1000;
        timeout_val.tv_usec = (timeout % 1000) * 1000;
#endif
        return zero::net::setsockopt(this->sock, SOL_SOCKET, SO_RCVTIMEO, timeout_val);
    }

    bool get_send_timeout(size_t& timeout) const {
#if _WIN32
        DWORD timeout_val = 0;
#else
        timeval timeout_val = {};
#endif
        bool ret = zero::net::getsockopt(this->sock, SOL_SOCKET, SO_SNDTIMEO, timeout_val) == 0;
#if _WIN32
        timeout = timeout_val;
#else
        timeout = timeout_val.tv_sec * 1000 + timeout_val.tv_usec / 1000;
#endif
        return ret;
    }

    bool set_send_timeout(size_t timeout) const {
#if _WIN32
        DWORD timeout_val = (DWORD)timeout;
#else
        timeval timeout_val;
        timeout_val.tv_sec = timeout / 1000;
        timeout_val.tv_usec = (timeout % 1000) * 1000;
#endif
        return zero::net::setsockopt(this->sock, SOL_SOCKET, SO_SNDTIMEO, timeout_val);
    }

    template <bool state>
    bool set_blocking_state() const {
        if constexpr (state) {
            static u_long BLOCKING_SOCKET = false;
            return ::ioctlsocket(sock, FIONBIO, &BLOCKING_SOCKET);
        } else {
            static u_long NON_BLOCKING_SOCKET = true;
            return ::ioctlsocket(sock, FIONBIO, &NON_BLOCKING_SOCKET);
        }
    }

    bool set_blocking_state(bool state) const {
#if _WIN32
        u_long blocking_state = !state;
        return ::ioctlsocket(this->sock, FIONBIO, &blocking_state);
#else
        int flags = ::fcntl(this->sock, F_GETFL, 0);
        flags &= O_NONBLOCK;
        flags |= state ? 0 : O_NONBLOCK;
        return ::fcntl(this->sock, F_SETFL, flags) == 0;
#endif
    }
};

template <typename T>
static inline bool operator==(const SocketBase<T>& lhs, const SOCKET& rhs) {
    return lhs.sock == rhs;
}
template <typename T>
static inline bool operator==(const SOCKET& lhs, const SocketBase<T>& rhs) {
    return lhs == rhs.sock;
}
template <typename T>
static inline bool operator!=(const SocketBase<T>& lhs, const SOCKET& rhs) {
    return lhs.sock != rhs;
}
template <typename T>
static inline bool operator!=(const SOCKET& lhs, const SocketBase<T>& rhs) {
    return lhs != rhs.sock;
}

struct Socket : SocketBase<Socket> {

    using SocketBase<Socket>::SocketBase;

    template<SocketType socket_type>
    static inline Socket create() {
        Socket socket;
        socket.initialize<socket_type>();
        return socket;
    }
};

struct SocketTCP : Socket {

    using Socket::Socket;

    template<typename T>
    T accept(sockaddr_any& addr) const = delete;

    template<typename T>
    T accept() const = delete;

    SocketTCP accept(sockaddr_any& addr) const {
        return this->Socket::accept<SocketTCP>(addr);
    }

    SocketTCP accept() const {
        return this->Socket::accept<SocketTCP>();
    }

    template<SocketType socket_type = TCP>
    inline bool initialize() {
        return this->Socket::initialize<socket_type>();
    }

    inline bool connect(const sockaddr_any& addr) const {
        return this->Socket::connect(addr);
    }

    template<SocketType socket_type = TCP>
    inline bool connect_ipv4(const char* ip, const char* port_str) const {
        return this->Socket::connect_ipv4<socket_type>(ip, port_str);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = TCP>
    inline bool connect_ipv4(const wchar_t* ip, const wchar_t* port_str) const {
        return this->Socket::connect_ipv4<socket_type>(ip, port_str);
    }
#endif

    template<SocketType socket_type = TCP>
    inline bool connect_ipv6(const char* ip, const char* port_str) const {
        return this->Socket::connect_ipv6<socket_type>(ip, port_str);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = TCP>
    inline bool connect_ipv6(const wchar_t* ip, const wchar_t* port_str) const {
        return this->Socket::connect_ipv6<socket_type>(ip, port_str);
    }
#endif

    template<SocketType socket_type = TCP>
    inline bool connect_ip(const char* ip, const char* port_str) const {
        return this->Socket::connect_ip<socket_type>(ip, port_str);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = TCP>
    inline bool connect_ip(const wchar_t* ip, const wchar_t* port_str) const {
        return this->Socket::connect_ip<socket_type>(ip, port_str);
    }
#endif

    template<SocketType socket_type = TCP>
    inline bool connect(const char* server_name, const char* port_str) const {
        return this->Socket::connect<socket_type>(server_name, port_str);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = TCP>
    inline bool connect(const wchar_t* server_name, const wchar_t* port_str) const {
        return this->Socket::connect<socket_type>(server_name, port_str);
    }
#endif

    template<SocketType socket_type = TCP>
    static inline SocketTCP create() {
        SocketTCP socket;
        socket.initialize<socket_type>();
        return socket;
    }
};

template<> bool SocketTCP::initialize<UDP>() = delete;
template<> bool SocketTCP::initialize<ICMP>() = delete;
template<> inline bool SocketTCP::connect_ipv4<UDP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketTCP::connect_ipv4<ICMP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketTCP::connect_ipv6<UDP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketTCP::connect_ipv6<ICMP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketTCP::connect_ip<UDP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketTCP::connect_ip<ICMP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketTCP::connect<UDP>(const char* server_name, const char* port_str) const = delete;
template<> inline bool SocketTCP::connect<ICMP>(const char* server_name, const char* port_str) const = delete;
#if ZNET_SUPPORT_WCHAR
template<> inline bool SocketTCP::connect_ipv4<UDP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketTCP::connect_ipv4<ICMP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketTCP::connect_ipv6<UDP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketTCP::connect_ipv6<ICMP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketTCP::connect_ip<UDP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketTCP::connect_ip<ICMP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketTCP::connect<UDP>(const wchar_t* server_name, const wchar_t* port_str) const = delete;
template<> inline bool SocketTCP::connect<ICMP>(const wchar_t* server_name, const wchar_t* port_str) const = delete;
#endif
template<> inline SocketTCP SocketTCP::create<UDP>() = delete;
template<> inline SocketTCP SocketTCP::create<ICMP>() = delete;

struct SocketUDP : Socket {

    using Socket::Socket;

    template<SocketType socket_type = UDP>
    inline bool initialize() {
        return this->Socket::initialize<socket_type>();
    }

    inline bool connect(const sockaddr_any& addr) const {
        return this->Socket::connect(addr);
    }

    template<SocketType socket_type = UDP>
    inline bool connect_ipv4(const char* ip, const char* port_str) const {
        return this->Socket::connect_ipv4<socket_type>(ip, port_str);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = UDP>
    inline bool connect_ipv4(const wchar_t* ip, const wchar_t* port_str) const {
        return this->Socket::connect_ipv4<socket_type>(ip, port_str);
    }
#endif

    template<SocketType socket_type = UDP>
    inline bool connect_ipv6(const char* ip, const char* port_str) const {
        return this->Socket::connect_ipv6<socket_type>(ip, port_str);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = UDP>
    inline bool connect_ipv6(const wchar_t* ip, const wchar_t* port_str) const {
        return this->Socket::connect_ipv6<socket_type>(ip, port_str);
    }
#endif

    template<SocketType socket_type = UDP>
    inline bool connect_ip(const char* ip, const char* port_str) const {
        return this->Socket::connect_ip<socket_type>(ip, port_str);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = UDP>
    inline bool connect_ip(const wchar_t* ip, const wchar_t* port_str) const {
        return this->Socket::connect_ip<socket_type>(ip, port_str);
    }
#endif

    template<SocketType socket_type = UDP>
    inline bool connect(const char* server_name, const char* port_str) const {
        return this->Socket::connect<socket_type>(server_name, port_str);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = UDP>
    inline bool connect(const wchar_t* server_name, const wchar_t* port_str) const {
        return this->Socket::connect<socket_type>(server_name, port_str);
    }
#endif

    template<SocketType socket_type = UDP>
    static inline SocketUDP create() {
        SocketUDP socket;
        socket.initialize<socket_type>();
        return socket;
    }
};

template<> bool SocketUDP::initialize<TCP>() = delete;
template<> bool SocketUDP::initialize<ICMP>() = delete;
template<> inline bool SocketUDP::connect_ipv4<TCP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketUDP::connect_ipv4<ICMP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketUDP::connect_ipv6<TCP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketUDP::connect_ipv6<ICMP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketUDP::connect_ip<TCP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketUDP::connect_ip<ICMP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketUDP::connect<TCP>(const char* server_name, const char* port_str) const = delete;
template<> inline bool SocketUDP::connect<ICMP>(const char* server_name, const char* port_str) const = delete;
#if ZNET_SUPPORT_WCHAR
template<> inline bool SocketUDP::connect_ipv4<TCP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketUDP::connect_ipv4<ICMP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketUDP::connect_ipv6<TCP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketUDP::connect_ipv6<ICMP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketUDP::connect_ip<TCP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketUDP::connect_ip<ICMP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketUDP::connect<TCP>(const wchar_t* server_name, const wchar_t* port_str) const = delete;
template<> inline bool SocketUDP::connect<ICMP>(const wchar_t* server_name, const wchar_t* port_str) const = delete;
#endif
template<> inline SocketUDP SocketUDP::create<TCP>() = delete;
template<> inline SocketUDP SocketUDP::create<ICMP>() = delete;

struct SocketICMP : Socket {
    template<SocketType socket_type = ICMP>
    inline bool initialize() {
        return this->Socket::initialize<socket_type>();
    }

    inline bool connect(const sockaddr_any& addr) const {
        return this->Socket::connect(addr);
    }

    template<SocketType socket_type = ICMP>
    inline bool connect_ipv4(const char* ip, const char* port_str) const {
        return this->Socket::connect_ipv4<socket_type>(ip, port_str);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = ICMP>
    inline bool connect_ipv4(const wchar_t* ip, const wchar_t* port_str) const {
        return this->Socket::connect_ipv4<socket_type>(ip, port_str);
    }
#endif

    template<SocketType socket_type = ICMP>
    inline bool connect_ipv6(const char* ip, const char* port_str) const {
        return this->Socket::connect_ipv6<socket_type>(ip, port_str);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = ICMP>
    inline bool connect_ipv6(const wchar_t* ip, const wchar_t* port_str) const {
        return this->Socket::connect_ipv6<socket_type>(ip, port_str);
    }
#endif

    template<SocketType socket_type = ICMP>
    inline bool connect_ip(const char* ip, const char* port_str) const {
        return this->Socket::connect_ip<socket_type>(ip, port_str);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = ICMP>
    inline bool connect_ip(const wchar_t* ip, const wchar_t* port_str) const {
        return this->Socket::connect_ip<socket_type>(ip, port_str);
    }
#endif

    template<SocketType socket_type = ICMP>
    inline bool connect(const char* server_name, const char* port_str) const {
        return this->Socket::connect<socket_type>(server_name, port_str);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = ICMP>
    inline bool connect(const wchar_t* server_name, const wchar_t* port_str) const {
        return this->Socket::connect<socket_type>(server_name, port_str);
    }
#endif

    template<SocketType socket_type = ICMP>
    static inline SocketICMP create() {
        SocketICMP socket;
        socket.initialize<socket_type>();
        return socket;
    }
};

template<> bool SocketICMP::initialize<TCP>() = delete;
template<> bool SocketICMP::initialize<UDP>() = delete;
template<> inline bool SocketICMP::connect_ipv4<TCP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketICMP::connect_ipv4<UDP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketICMP::connect_ipv6<TCP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketICMP::connect_ipv6<UDP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketICMP::connect_ip<TCP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketICMP::connect_ip<UDP>(const char* ip, const char* port_str) const = delete;
template<> inline bool SocketICMP::connect<TCP>(const char* server_name, const char* port_str) const = delete;
template<> inline bool SocketICMP::connect<UDP>(const char* server_name, const char* port_str) const = delete;
#if ZNET_SUPPORT_WCHAR
template<> inline bool SocketICMP::connect_ipv4<TCP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketICMP::connect_ipv4<UDP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketICMP::connect_ipv6<TCP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketICMP::connect_ipv6<UDP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketICMP::connect_ip<TCP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketICMP::connect_ip<UDP>(const wchar_t* ip, const wchar_t* port_str) const = delete;
template<> inline bool SocketICMP::connect<TCP>(const wchar_t* server_name, const wchar_t* port_str) const = delete;
template<> inline bool SocketICMP::connect<UDP>(const wchar_t* server_name, const wchar_t* port_str) const = delete;
#endif
template<> inline SocketICMP SocketICMP::create<TCP>() = delete;
template<> inline SocketICMP SocketICMP::create<UDP>() = delete;

#if ENABLE_SSL
struct SocketSSL : SocketBase<SocketSSL> {

    template<SocketType socket_type = TCP>
    inline bool initialize() {
        return this->SocketBase<SocketSSL>::initialize<socket_type>();
    }

    inline bool connect(const sockaddr_any& addr) const {
        return this->SocketBase<SocketSSL>::connect(addr);
    }

    template<SocketType socket_type = TCP>
    inline bool connect_ipv4(const char* ip, const char* port_str) const = delete;

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = TCP>
    inline bool connect_ipv4(const wchar_t* ip, const wchar_t* port_str) const = delete;
#endif

    template<SocketType socket_type = TCP>
    inline bool connect_ipv6(const char* ip, const char* port_str) const = delete;

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = TCP>
    inline bool connect_ipv6(const wchar_t* ip, const wchar_t* port_str) const = delete;
#endif

    template<SocketType socket_type = TCP>
    inline bool connect_ip(const char* ip, const char* port_str) const = delete;

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = TCP>
    inline bool connect_ip(const wchar_t* ip, const wchar_t* port_str) const = delete;
#endif

    template<SocketType socket_type = TCP>
    inline bool connect(const char* server_name, const char* port_str) const {
        return this->SocketBase<SocketSSL>::connect<socket_type>(server_name, port_str);
    }

#if ZNET_SUPPORT_WCHAR
    template<SocketType socket_type = TCP>
    inline bool connect(const wchar_t* server_name, const wchar_t* port_str) const {
        return this->SocketBase<SocketSSL>::connect<socket_type>(server_name, port_str);
    }
#endif

    template<SocketType socket_type = TCP>
    static inline SocketSSL create() {
        SocketSSL socket;
        socket.initialize<socket_type>();
        return socket;
    }

protected:
    bool tls_in_use = false;
    SecPkgContext_StreamSizes tls_sizes;

    // Who knows WTF windows does with these, so
    // don't make any weird promises to the compiler
    mutable CredHandle tls_handle;
    mutable CtxtHandle tls_context;

    static inline constexpr size_t PACKET_BUFFER_SIZE = UINT16_MAX + 1;
    
    static inline constexpr SCHANNEL_CRED tls_cred = {
        .dwVersion = SCHANNEL_CRED_VERSION,
        .grbitEnabledProtocols = SP_PROT_TLS1_2,  // allow only TLS v1.2
        .dwFlags = SCH_USE_STRONG_CRYPTO |          // use only strong crypto alogorithms
                   SCH_CRED_AUTO_CRED_VALIDATION |  // automatically validate server certificate
                   SCH_CRED_NO_DEFAULT_CREDS     // no client certificate authentication
    };

    inline bool connect_secondary(const char* server_name) {
        return this->tls_in_use = this->initialize_tls(server_name);
    }

    inline bool connect_secondary(const wchar_t* server_name) {
        return this->tls_in_use = this->initialize_tls(server_name);
    }

    inline void close_secondary() {
        if (this->tls_in_use) {
            ::DeleteSecurityContext(&this->tls_context);
            ::FreeCredentialsHandle(&this->tls_handle);
        }
    }
    
    // Adapted from this: https://github.com/odzhan/shells/blob/master/s6/tls.c
    template<typename T>
    bool initialize_tls(const T* server_name) {

        SECURITY_STATUS status;
        if constexpr (std::is_same_v<T, wchar_t>) {
            status = ::AcquireCredentialsHandleW(NULL, (LPWSTR)UNISP_NAME_W, SECPKG_CRED_OUTBOUND, NULL, (void*)&tls_cred, NULL, NULL, &this->tls_handle, NULL);
        } else {
            status = ::AcquireCredentialsHandleA(NULL, (LPSTR)UNISP_NAME_A, SECPKG_CRED_OUTBOUND, NULL, (void*)&tls_cred, NULL, NULL, &this->tls_handle, NULL);
        }

        if (expect(status == SEC_E_OK, true)) {

            SecBuffer outbuffers[1] = { 0 };
            outbuffers[0].BufferType = SECBUFFER_TOKEN;
            outbuffers[0].pvBuffer = NULL;
            outbuffers[0].cbBuffer = 0;

            SecBufferDesc outdesc = { SECBUFFER_VERSION, ARRAYSIZE(outbuffers), outbuffers };

            DWORD flags = ISC_REQ_ALLOCATE_MEMORY | ISC_REQ_USE_SUPPLIED_CREDS | ISC_REQ_CONFIDENTIALITY | ISC_REQ_REPLAY_DETECT | ISC_REQ_SEQUENCE_DETECT | ISC_REQ_STREAM | ISC_REQ_MANUAL_CRED_VALIDATION;

            SECURITY_STATUS sec;
            if constexpr (std::is_same_v<T, wchar_t>) {
                sec = ::InitializeSecurityContextW(&this->tls_handle,
                                                   NULL,
                                                   (SEC_WCHAR*)server_name,
                                                   flags,
                                                   0,
                                                   0,
                                                   NULL,
                                                   0,
                                                   &this->tls_context,
                                                   &outdesc,
                                                   &flags,
                                                   NULL);
            } else {
                sec = ::InitializeSecurityContextA(&this->tls_handle,
                                                   NULL,
                                                   (SEC_CHAR*)server_name,
                                                   flags,
                                                   0,
                                                   0,
                                                   NULL,
                                                   0,
                                                   &this->tls_context,
                                                   &outdesc,
                                                   &flags,
                                                   NULL);
            }

            if (sec == SEC_I_CONTINUE_NEEDED) {
                {
                    char* buffer = (char*)outbuffers[0].pvBuffer;
                    size_t size = outbuffers[0].cbBuffer;
                    while (size != 0) {
                        auto send_ret = ::send(this->sock, buffer, size, 0);
                        if (expect(send_ret <= 0, false)) {
                            // failed with disconnect or error
                            goto tls_fail;
                        }
                        size -= send_ret;
                        buffer += send_ret;
                    }
                    ::FreeContextBuffer(outbuffers[0].pvBuffer);
                }

                char packet_buffer[PACKET_BUFFER_SIZE];

                size_t received = 0;
                SecBuffer inbuffers[2] = {};
                do {
                    if (sec == SEC_E_INCOMPLETE_MESSAGE) {
                        int recv_ret = ::recv(this->sock, &packet_buffer[received], sizeof(packet_buffer) - received, 0);
                        if (expect(recv_ret <= 0, false)) {
                            // failed with disconnect or error
                            goto tls_fail;
                        }
                        received += recv_ret;
                    }

                    inbuffers[0].BufferType = SECBUFFER_TOKEN;
                    inbuffers[0].pvBuffer = packet_buffer;
                    inbuffers[0].cbBuffer = received;
                    inbuffers[1].BufferType = SECBUFFER_EMPTY;
                    inbuffers[1].pvBuffer = NULL;
                    inbuffers[1].cbBuffer = 0;

                    outbuffers[0].BufferType = SECBUFFER_TOKEN;
                    outbuffers[0].pvBuffer = NULL;
                    outbuffers[0].cbBuffer = 0;

                    SecBufferDesc indesc = { SECBUFFER_VERSION, ARRAYSIZE(inbuffers), inbuffers };
                    outdesc = { SECBUFFER_VERSION, ARRAYSIZE(outbuffers), outbuffers };

                    flags = ISC_REQ_ALLOCATE_MEMORY | ISC_REQ_USE_SUPPLIED_CREDS | ISC_REQ_CONFIDENTIALITY | ISC_REQ_REPLAY_DETECT | ISC_REQ_SEQUENCE_DETECT | ISC_REQ_STREAM | ISC_REQ_MANUAL_CRED_VALIDATION;

                    if constexpr (std::is_same_v<T, wchar_t>) {
                        sec = ::InitializeSecurityContextW(&this->tls_handle,
                                                           &this->tls_context,
                                                           NULL,
                                                           flags,
                                                           0,
                                                           0,
                                                           &indesc,
                                                           0,
                                                           NULL,
                                                           &outdesc,
                                                           &flags,
                                                           NULL);
                    } else {
                        sec = ::InitializeSecurityContextA(&this->tls_handle,
                                                           &this->tls_context,
                                                           NULL,
                                                           flags,
                                                           0,
                                                           0,
                                                           &indesc,
                                                           0,
                                                           NULL,
                                                           &outdesc,
                                                           &flags,
                                                           NULL);
                    }

                    if (sec == SEC_E_OK || sec == SEC_I_CONTINUE_NEEDED) {
                        char* buffer = (char*)outbuffers[0].pvBuffer;
                        size_t size = outbuffers[0].cbBuffer;
                        if (buffer) {
                            while (size != 0) {
                                auto send_ret = ::send(this->sock, buffer, size, 0);
                                if (expect(send_ret <= 0, false)) {
                                    // failed with disconnect or error
                                    ::FreeContextBuffer(outbuffers[0].pvBuffer);
                                    goto tls_fail;
                                }
                                size -= send_ret;
                                buffer += send_ret;
                            }
                            ::FreeContextBuffer(outbuffers[0].pvBuffer);
                        }
                    }
                    if (sec == SEC_E_INCOMPLETE_MESSAGE) {
                        continue;
                    }
                    if (sec == SEC_E_OK) {
                        if constexpr (std::is_same_v<T, wchar_t>) {
                            ::QueryContextAttributesW(&this->tls_context, SECPKG_ATTR_STREAM_SIZES, &this->tls_sizes);
                        } else {
                            ::QueryContextAttributesA(&this->tls_context, SECPKG_ATTR_STREAM_SIZES, &this->tls_sizes);
                        }
                        return true;
                    }
                    if (FAILED(sec)) {
                        break;
                    }
                    if (inbuffers[1].BufferType == SECBUFFER_EXTRA) {
                        memmove(packet_buffer, &packet_buffer[received - inbuffers[1].cbBuffer], inbuffers[1].cbBuffer);
                        received = inbuffers[1].cbBuffer;
                    } else {
                        received = 0;
                    }
                } while (sec == SEC_I_CONTINUE_NEEDED || sec == SEC_E_INCOMPLETE_MESSAGE || sec == SEC_I_INCOMPLETE_CREDENTIALS);
            tls_fail:
                ::DeleteSecurityContext(&this->tls_context);
            }
            ::FreeCredentialsHandle(&this->tls_handle);
        }
#if _WIN32
        ::closesocket(this->sock);
#else
        ::close(this->sock);
#endif
        this->sock = INVALID_SOCKET;
        return false;
    }

    inline size_t receive_impl(void* buffer, size_t recv_length) const {
        uint8_t* recv_buffer = (uint8_t*)buffer;
        if (expect(!this->tls_in_use, false)) {
            int recv_ret = ::recv(this->sock, (char*)recv_buffer, recv_length, 0);
            if (expect(recv_ret <= 0, false)) {
                recv_ret = 0;
            }
            return recv_ret;
        }
        size_t received_size = 0;
        size_t total_received = 0;

        uint8_t* initial_recv_buffer = recv_buffer;
        
        char packet_buffer[PACKET_BUFFER_SIZE];

        while (recv_length) {

            if (total_received) {
                // Why?
                return total_received;
            }

            if (expect(received_size == sizeof(packet_buffer), false)) {
                // Is this even a possible error?
                return 0;
            }
            int recv_ret = ::recv(this->sock, &packet_buffer[received_size], sizeof(packet_buffer) - received_size, 0);
            if (expect(recv_ret <= 0, false)) {
                return 0;
            }
            received_size += recv_ret;

            while (received_size) {

                SecBuffer buffers[4];
                buffers[0].BufferType = SECBUFFER_DATA;
                buffers[0].pvBuffer = packet_buffer;
                buffers[0].cbBuffer = received_size;
                buffers[1].BufferType = SECBUFFER_EMPTY;
                buffers[2].BufferType = SECBUFFER_EMPTY;
                buffers[3].BufferType = SECBUFFER_EMPTY;

                SecBufferDesc desc = { SECBUFFER_VERSION, ARRAYSIZE(buffers), buffers };

                SECURITY_STATUS sec = ::DecryptMessage(&this->tls_context, &desc, 0, NULL);
                switch (sec) {
                    case SEC_E_OK:
                    {
                        char* decrypted_data = (char*)buffers[1].pvBuffer;
                        size_t decrypt_data_length = buffers[1].cbBuffer;
                        size_t used_length = received_size - (buffers[3].BufferType == SECBUFFER_EXTRA ? buffers[3].cbBuffer : 0);

                        size_t current_write_length;
                        do {
                            current_write_length = (std::min)(recv_length, decrypt_data_length);
                            memcpy(recv_buffer, decrypted_data, current_write_length);
                            recv_buffer += current_write_length;
                            recv_length -= current_write_length;
                            total_received += current_write_length;
                            decrypt_data_length -= current_write_length;
                            decrypted_data += current_write_length;
                        } while (current_write_length != decrypt_data_length);
                        memmove(packet_buffer, &packet_buffer[used_length], received_size - used_length);
                        received_size -= used_length;
                        continue;
                    }
                    case SEC_I_CONTEXT_EXPIRED:
                        return total_received;
                    default:
                        return 0;
                    case SEC_E_INCOMPLETE_MESSAGE:
                        break;
                }
                break;
            }
        }
        return total_received;
    }

    inline size_t send_impl(const void* buffer, size_t send_length) const {

        uint8_t* send_buffer = (uint8_t*)buffer;

        size_t total_sent_length = 0;
        
        char packet_buffer[PACKET_BUFFER_SIZE];

        while (send_length) {
            char* current_send_buffer = (char*)send_buffer;
            size_t current_buffer_read_length = send_length;
            size_t current_send_length = current_buffer_read_length;
            SecBuffer buffers[3];
            if (expect(this->tls_in_use, true)) {
                current_send_buffer = packet_buffer;
                if (current_buffer_read_length > this->tls_sizes.cbMaximumMessage) {
                    current_buffer_read_length = this->tls_sizes.cbMaximumMessage;
                }
                buffers[0].BufferType = SECBUFFER_STREAM_HEADER;
                buffers[0].pvBuffer = current_send_buffer;
                buffers[0].cbBuffer = this->tls_sizes.cbHeader;
                buffers[1].BufferType = SECBUFFER_DATA;
                buffers[1].pvBuffer = &current_send_buffer[this->tls_sizes.cbHeader];
                buffers[1].cbBuffer = current_buffer_read_length;
                buffers[2].BufferType = SECBUFFER_STREAM_TRAILER;
                buffers[2].pvBuffer = &current_send_buffer[this->tls_sizes.cbHeader + current_buffer_read_length];
                buffers[2].cbBuffer = this->tls_sizes.cbTrailer;
                memcpy(buffers[1].pvBuffer, send_buffer, current_buffer_read_length);
                SecBufferDesc desc = { SECBUFFER_VERSION, ARRAYSIZE(buffers), buffers };
                if (expect(::EncryptMessage(&this->tls_context, 0, &desc, 0) != SEC_E_OK, false)) {
                    // this should not happen, but just in case check it
                    return false;
                }
                current_send_length = buffers[0].cbBuffer + buffers[1].cbBuffer + buffers[2].cbBuffer;
            }
            size_t sent = 0;
            while (sent != current_send_length) {
                int send_ret = ::send(this->sock, &current_send_buffer[sent], current_send_length - sent, 0);
                if (expect(send_ret <= 0, false)) {
                    return 0;
                }
                sent += send_ret;
                total_sent_length += send_ret;
            }
            send_buffer += current_buffer_read_length;
            send_length -= current_buffer_read_length;
        }
        return total_sent_length;
    }
};

template<> bool SocketSSL::initialize<UDP>() = delete;
template<> bool SocketSSL::initialize<ICMP>() = delete;
template<> inline bool SocketSSL::connect<UDP>(const char* server_name, const char* port_str) const = delete;
template<> inline bool SocketSSL::connect<ICMP>(const char* server_name, const char* port_str) const = delete;
#if ZNET_SUPPORT_WCHAR
template<> inline bool SocketSSL::connect<UDP>(const wchar_t* server_name, const wchar_t* port_str) const = delete;
template<> inline bool SocketSSL::connect<ICMP>(const wchar_t* server_name, const wchar_t* port_str) const = delete;
#endif
template<> inline SocketSSL SocketSSL::create<UDP>() = delete;
template<> inline SocketSSL SocketSSL::create<ICMP>() = delete;
#endif

/*
struct PingerBase {
    SocketICMP socket;
    sockaddr_any address;

    PingerBase(SocketICMP socket) : socket(socket) {}
};

template<IPType ip_type>
struct Pinger;

template<>
struct Pinger<IPv4> : PingerBase {
    // TODO
};

template<>
struct Pinger<IPv6> : PingerBase {

    struct {
        IPv6Header ip_header;
        struct {
            ICMPHeader header;
            uint32_t payload;
        } data;
    } packet;


    Pinger(SocketICMP socket) : PingerBase(socket) {
        this->packet.ip_header.version = 6;
        this->packet.ip_header.traffic_class = 0;
        this->packet.ip_header.flow_label = 0;
        this->packet.ip_header.payload_length = sizeof(this->packet.data);
        this->packet.ip_header.next_header = 58;
        this->packet.ip_header.hop_limit = 255;
        this->packet.data.header.type = 8; // ICMP_ECHO_REQUEST
        this->packet.data.header.subtype = 0; // PING
        //this->data.header_data
        //this->data.checksum = 0;
    }
};
*/

#if _WIN32
static inline std::atomic<uint8_t> winsock_initialized = { false };

#if ZNET_IPV6_MODES(ZNET_REQUIRE_IPV6 | ZNET_DISABLE_IPV6)
static inline constexpr bool winsock_config_initialized = true;
#endif
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6)
static inline bool winsock_config_initialized = false;
#endif
#endif

static bool enable_winsock(bool prefer_ipv6 = true) {
#if _WIN32
    union {
        WSADATA idgaf_about_winsock_version;
        struct {
            DWORD ipv6_state;
            DWORD ifgaf_about_data_size;
        };
    };
    
    if (expect(!winsock_initialized.exchange(true), false)) {
        winsock_initialized = ::WSAStartup(WINSOCK_VERSION, &idgaf_about_winsock_version) == 0;
#if ZNET_IPV6_MODES(ZNET_DONT_REQUIRE_IPV6)
        if (!winsock_config_initialized) {
            winsock_config_initialized = true;
            if (expect(RegGetValueW(HKEY_LOCAL_MACHINE, L"SYSTEM\\CurrentControlSet\\Services\\Tcpip6\\Parameters", L"DisabledComponents", RRF_RT_REG_DWORD, NULL, &ipv6_state, &ifgaf_about_data_size) == ERROR_SUCCESS, true)) {
                if (ipv6_state != 0xFF) {
                    enable_ipv6 = prefer_ipv6;
                }
            }
        }
#endif
    }
    return winsock_initialized;
#else
    return true;
#endif
}

static inline void disable_winsock() {
#if _WIN32
    if (expect(winsock_initialized.exchange(false), true)) {
        ::WSACleanup();
    }
#endif
}



}

}

#endif