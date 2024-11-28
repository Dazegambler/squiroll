#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <string>
#include <mutex>
#include <charconv>
#include <system_error>
#include <bit>

#include <winsock2.h>
#include <ws2tcpip.h>
//#include <MSWSock.h>
#include <windns.h>
#include <synchapi.h>

#include "util.h"
#include "config.h"
#include "patch_utils.h"
#include "alloc_man.h"
#include "log.h"
#include "netcode.h"
#include "lobby.h"

#define ONLY_LOG_CUSTOM_PACKETS 0

#if CONNECTION_LOGGING & CONNECTION_LOGGING_LOBBY_DEBUG
#define lobby_debug_printf(...) log_printf(__VA_ARGS__)
#else
#define lobby_debug_printf(...) EVAL_NOOP(__VA_ARGS__)
#endif

#if PUNCH_BOOST_TYPE & PUNCH_BOOST_PROCESS_PRIORITY
#define BOOST_PROCESS_PRIORITY_START() \
DWORD prev_process_priority = GetPriorityClass(CurrentProcessPseudoHandle()); \
SetPriorityClass(CurrentProcessPseudoHandle(), REALTIME_PRIORITY_CLASS)
#define BOOST_PROCESS_PRIORITY_END() SetPriorityClass(CurrentProcessPseudoHandle(), prev_process_priority)
#else
#define BOOST_PROCESS_PRIORITY_START() require_semicolon()
#define BOOST_PROCESS_PRIORITY_END() require_semicolon()
#endif

#if PUNCH_BOOST_TYPE & PUNCH_BOOST_THREAD_PRIORITY
#define BOOST_THREAD_PRIORITY_START() \
int prev_thread_priority = GetThreadPriority(CurrentThreadPseudoHandle()); \
SetThreadPriority(CurrentThreadPseudoHandle(), THREAD_PRIORITY_TIME_CRITICAL)
#define BOOST_THREAD_PRIORITY_END() SetThreadPriority(CurrentThreadPseudoHandle(), prev_thread_priority)
#else
#define BOOST_THREAD_PRIORITY_START() require_semicolon()
#define BOOST_THREAD_PRIORITY_END() require_semicolon()
#endif

#if PUNCH_BOOST_TYPE & PUNCH_BOOST_TIMER_PRECISION
static UINT minimum_timer_precision = 1;
#define BOOST_TIMER_PRECISION_START() timeBeginPeriod(minimum_timer_precision)
#define BOOST_TIMER_PRECISION_END() timeEndPeriod(minimum_timer_precision)
#else
#define BOOST_TIMER_PRECISION_START() require_semicolon()
#define BOOST_TIMER_PRECISION_END() require_semicolon()
#endif

#define PUNCH_BOOST_START() \
BOOST_PROCESS_PRIORITY_START(); \
BOOST_THREAD_PRIORITY_START(); \
BOOST_TIMER_PRECISION_START()

#define PUNCH_BOOST_END() \
BOOST_TIMER_PRECISION_END(); \
BOOST_THREAD_PRIORITY_END(); \
BOOST_PROCESS_PRIORITY_END()

#if !MINGW_COMPAT
#define SOCKADDR_IN4_LITERAL(ip, port) (sockaddr_in){ .sin_family = AF_INET, .sin_port = port, .sin_addr = ip }
#define SOCKADDR_IN6_LITERAL(ip, port) (sockaddr_in6){ .sin6_family = AF_INET6, .sin6_port = port, .sin6_addr = ip }
#else
#define SOCKADDR_IN4_LITERAL(ip, port) (sockaddr_in){ AF_INET, port, ip }
#define SOCKADDR_IN6_LITERAL(ip, port) (sockaddr_in6){ AF_INET6, port, 0, ip }
#endif

#define INIT_SOCKADDR_IN4(sockaddr, ip, port) \
PUSH_WARNINGS() \
IGNORE_DESIGNATED_INITIALIZER_WARNING() \
*(sockaddr_in*)&sockaddr = SOCKADDR_IN4_LITERAL(ip, port); \
POP_WARNINGS()

#define INIT_SOCKADDR_IN6(sockaddr, ip, port) \
PUSH_WARNINGS() \
IGNORE_DESIGNATED_INITIALIZER_WARNING() \
*(sockaddr_in6*)&sockaddr = SOCKADDR_IN6_LITERAL(ip, port); \
POP_WARNINGS()

// size: 0x4F4
struct AsyncLobbyClient {

    void* vftable; // 0x0

    unsigned char __unknown_A[0x4]; // 0x4

    int __socket_state; // 0x8
    SOCKET lobby_tcp_socket; // 0xC

    unsigned char __unknown_B[0x104]; // 0x10

    uint32_t __uint_114; // 0x114
    SOCKET __socket_array_118[64]; // 0x118
    void* __innerA_ptr_218; // 0x218
    bool ssl_enabled; // 0x21C

    unsigned char __padding_A[0x3]; // 0x21D

    uint32_t __time_220; // 0x220

    unsigned char __unknown_C[0x4]; // 0x224

    long long __longlong_228; // 0x228
    long long __longlong_230; // 0x230
    std::string server_string; // 0x238
    std::string port_string; // 0x250
    //std::mutex __mutex_268; // 0x268
    unsigned char __mutex_dummy_268[0x30]; // 0x268

    unsigned char __dummy_A[0x40]; // 0x298

    std::string __last_host_used; // 0x2D8
    std::string lobby_prefix; // 0x2F0
    std::string current_nickname; // 0x308
    std::string __string_320; // 0x320
    std::string current_channel; // 0x338
    std::string __lobby_nameA; // 0x350
    std::string password; // 0x368
    std::string __lobby_nameB; // 0x380
    std::string version_signature; // 0x398
    std::string user_data_str; // 0x3B0 external_port as string
    std::string match_host; // 0x3C8
    std::string __match_user_data_str; // 0x3E0 opponent port?
    uint32_t local_port; // 0x3F8
    int __dword_3FC; // 0x3FC
    int __int_400; // 0x400
    int __int_404; // 0x404
    int __dword_408; // 0x408

    unsigned char __innerB_40C[0x8]; // 0x40C

    int __dword_414; // 0x414
    uint32_t __time_418; // 0x418
    int __dword_41C; // 0x41C
    bool __bool_420; // 0x420

    unsigned char __padding_B[0x3];// 0x421

    std::string __opponent_nickname; // 0x424
    bool __bool_43C; // 0x43C

    unsigned char __padding_C[0x3]; // 0x43D

    std::string __recv_str; // 0x440

    unsigned char __queue_458[0x18]; // 0x458

    unsigned char __unknown_D[0x7C]; // 0x470

    int __lobby_state; // 0x4EC
    int32_t max_nickname_length; // 0x4F0
    // 0x4F4
};

static_assert(sizeof(AsyncLobbyClient) == 0x4F8);
static_assert(__builtin_offsetof(AsyncLobbyClient, current_nickname) == 0x308);

static_assert(__builtin_offsetof(PacketLobbyName, type) == 0);

static int init_sockaddr(sockaddr_storage& out, bool is_ipv6, const char* ip, uint16_t port) {
    if (!is_ipv6) {
        out.ss_family = AF_INET;
        ((sockaddr_in*)&out)->sin_port = hton(port);
        inet_pton(AF_INET, ip, &((sockaddr_in*)&out)->sin_addr);
        return sizeof(sockaddr_in);
    } else {
        out.ss_family = AF_INET6;
        ((sockaddr_in6*)&out)->sin6_port = hton(port);
        inet_pton(AF_INET6, ip, &((sockaddr_in6*)&out)->sin6_addr);
        return sizeof(sockaddr_in6);
    }
}

static u_long NON_BLOCKING_SOCKET = true;
static u_long BLOCKING_SOCKET = false;
template <bool state>
static inline bool set_blocking_state(SOCKET sock) {
    if constexpr (state) {
        return ::ioctlsocket(sock, FIONBIO, &BLOCKING_SOCKET);
    } else {
        return ::ioctlsocket(sock, FIONBIO, &NON_BLOCKING_SOCKET);
    }
}

uintptr_t lobby_base_address = 0;

static SpinLock punch_lock;

static SOCKET punch_socket = INVALID_SOCKET;
static bool punch_socket_is_loaned = false;
static bool punch_socket_is_inherited = false;

static sockaddr_storage lobby_addr = {};
//static sockaddr_storage local_addr = {};
static size_t lobby_addr_length = 0;
//static size_t local_addr_length = 0;

std::atomic<uint32_t> users_in_room = {};

#if PUNCH_START_TYPE == PUNCH_START_USE_ATOMIC
std::atomic<bool> start_punch = {};
#elif PUNCH_START_TYPE == PUNCH_START_USE_EVENT
WaitableEvent start_punch;
#endif

#if PUNCH_SLEEP_TYPE == PUNCH_SLEEP_USE_TIMER
WaitableTimer punch_timer;
#endif

bool addr_is_lobby(const sockaddr* addr, int addr_len) {
    return addr_len == lobby_addr_length && !memcmp(addr, &lobby_addr, addr_len);
}

#if CONNECTION_LOGGING & CONNECTION_LOGGING_UDP_PACKETS
static sockaddr_storage SENDTO_ADDR = {};
static sockaddr_storage RECVFROM_ADDR = {};
static int SENDTO_ADDR_LEN = 0;
static int RECVFROM_ADDR_LEN = 0;
static uint8_t SENDTO_TYPE = UINT8_MAX;
static uint8_t RECVFROM_TYPE = UINT8_MAX;
#endif

template<bool abandon_message = true>
inline void abandon_punch_socket_no_lock() {
    if constexpr (abandon_message) {
        lobby_debug_printf("Abandoning the punch socket.\n");
    }
#if CONNECTION_LOGGING & CONNECTION_LOGGING_UDP_PACKETS
    SENDTO_ADDR = {};
    RECVFROM_ADDR = {};
    SENDTO_ADDR_LEN = 0;
    RECVFROM_ADDR_LEN = 0;
    SENDTO_TYPE = UINT8_MAX;
    RECVFROM_TYPE = UINT8_MAX;
#endif
    punch_socket_is_loaned = false;
    punch_socket_is_inherited = false;
}

template<bool abandon_message = true>
void abandon_punch_socket() {
    std::lock_guard<SpinLock> lock(punch_lock);

    return abandon_punch_socket_no_lock<abandon_message>();
}

// EXE hook, overrides ref count
int WSAAPI close_punch_socket(SOCKET s) {
    if (s != INVALID_SOCKET) {
        std::lock_guard<SpinLock> lock(punch_lock);

        if (s == punch_socket) {
            lobby_debug_printf("Closing the punch socket. Bad? A\n");
            //CancelIoEx((HANDLE)s, NULL);
            //return 0;
            punch_socket = INVALID_SOCKET;
            abandon_punch_socket_no_lock<false>();
        }
    }

    return closesocket(s);
}

SOCKET get_punch_socket() {
    // Uncomment this if more logic is added
    //std::lock_guard<SpinLock> lock(punch_lock);

    return punch_socket;
}

inline void enable_addr_reuse(SOCKET sock) {
    static const BOOL enable = TRUE;
    ::setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (const char*)&enable, sizeof(BOOL));
}

inline SOCKET create_punch_socket_no_lock(uint16_t port) {
    SOCKET sock = WSASocketW(AF_INET, SOCK_DGRAM, IPPROTO_UDP, NULL, 0, WSA_FLAG_OVERLAPPED);
    if (sock != INVALID_SOCKET) {
        sockaddr_storage bind_addr;
        int bind_addr_length;
        switch (lobby_addr.ss_family) {
            case AF_INET:
                INIT_SOCKADDR_IN4(bind_addr, INADDR_ANY, hton(port));
                bind_addr_length = sizeof(sockaddr_in);
                break;
            case AF_INET6:
                INIT_SOCKADDR_IN6(bind_addr, IN6ADDR_ANY_INIT, hton(port));
                bind_addr_length = sizeof(sockaddr_in6);
                break;
            default:
                goto fail;
        };
        //enable_addr_reuse(sock);
        lobby_debug_printf("BNDA:%u\n", port);
        if (!bind(sock, (const sockaddr*)&bind_addr, bind_addr_length)) {
#if CONNECTION_LOGGING & CONNECTION_LOGGING_LOBBY_DEBUG
            bind_addr_length = sizeof(sockaddr_storage);
            getsockname(sock, (sockaddr*)&bind_addr, &bind_addr_length);
            lobby_debug_printf("BNDC:%u\n", ntoh<uint16_t>(((sockaddr_in*)&bind_addr)->sin_port));
#endif
            punch_socket = sock;
            return sock;
        }
    fail:
        lobby_debug_printf("UDP bindA fail (%u):%u\n", port, WSAGetLastError());
        closesocket(sock);
        sock = INVALID_SOCKET;
    } else {
        lobby_debug_printf("UDP socket fail:%u\n", WSAGetLastError());
    }
    return sock;
}

SOCKET create_punch_socket(uint16_t port) {
    std::lock_guard<SpinLock> lock(punch_lock);

    return create_punch_socket_no_lock(port);
}

SOCKET get_or_create_punch_socket(uint16_t port) {
    std::lock_guard<SpinLock> lock(punch_lock);

    SOCKET sock = punch_socket;
    if (sock == INVALID_SOCKET) {
        sock = create_punch_socket_no_lock(port);
    }
    return sock;
}

/*
SOCKET recreate_punch_socket(uint16_t port) {
    std::lock_guard<SpinLock> lock(punch_lock);

    SOCKET sock = punch_socket;
    punch_socket = INVALID_SOCKET;
    if (sock != INVALID_SOCKET) {
        abandon_punch_socket_no_lock();
    }

    return create_punch_socket_no_lock(port);
}
*/

SOCKET get_or_recreate_punch_socket(uint16_t port) {
    std::lock_guard<SpinLock> lock(punch_lock);

    SOCKET sock = punch_socket;
    if (sock != INVALID_SOCKET) {
        if (!punch_socket_is_inherited) {
            return sock;
        }
        punch_socket = INVALID_SOCKET;
        abandon_punch_socket_no_lock();
        //::shutdown(sock, SD_BOTH);
        //CancelIoEx((HANDLE)sock, NULL);
        //closesocket(sock);
    }
    
    return create_punch_socket_no_lock(port);
}

SOCKET WSAAPI inherit_punch_socket(int af, int type, int protocol, LPWSAPROTOCOL_INFOW lpProtocolInfo, GROUP g, DWORD dwFlags) {

    std::lock_guard<SpinLock> lock(punch_lock);

    if (!punch_socket_is_inherited) {
        SOCKET sock_ret = punch_socket;
        if (sock_ret == INVALID_SOCKET) {
            sock_ret = WSASocketW(af, type, protocol, lpProtocolInfo, g, dwFlags);
            if (
                sock_ret != INVALID_SOCKET &&
                type == SOCK_DGRAM &&
                protocol == IPPROTO_UDP
            ) {
                //enable_addr_reuse(sock_ret);
                punch_socket_is_loaned = true;
                punch_socket = sock_ret;
            }
        }
        punch_socket_is_inherited = sock_ret != INVALID_SOCKET;
        return sock_ret;
    }
    else {
        // For some reason the client tries
        // to open the socket twice
        return INVALID_SOCKET;
    }
}

int WSAAPI bind_inherited_socket(SOCKET s, const sockaddr* name, int namelen) {
    {
        std::lock_guard<SpinLock> lock(punch_lock);

        if (
            // Somehow uncommenting this makes things less reliable
            // even though it shouldn't do anything? Why?
            //s == punch_socket &&
            !punch_socket_is_loaned
        ) {
            return 0;
        }
    }
    
    uint16_t port = 0;
    switch (name->sa_family) {
        case AF_INET:
            port = ((const sockaddr_in*)name)->sin_port;
            break;
        case AF_INET6:
            port = ((const sockaddr_in6*)name)->sin6_port;
            break;
    }
    port = ntoh(port);
    lobby_debug_printf("BNDB:%u (PUNCH: %s)\n", port, bool_str(s == punch_socket));
    
    int ret = bind(s, name, namelen);

    if (ret) {
        lobby_debug_printf("UDP bindB fail (%u):%u\n", port, WSAGetLastError());
    }

    return ret;
}

static constexpr size_t DELAY_PACKET_COUNT = 5;

static_assert(std::bit_width(DELAY_PACKET_COUNT - 1) <= 7 && DELAY_PACKET_COUNT <= 64);

static int64_t sending_times[DELAY_PACKET_COUNT] = {};
static char pong_recv[sizeof(PacketPunchDelayPong) + 64];

using delay_mask_t = UBitIntType<std::max(DELAY_PACKET_COUNT, (size_t)32)>;

static constexpr uint64_t DELAY_PACKET_SPACING_MS = 5;
static constexpr uint64_t DELAY_RECV_SPACING_MS = 1;
static constexpr uint64_t MAX_PACKET_END_DELAY_MS = 2000;
static constexpr uint64_t MAX_PUNCH_START_DELAY_MS = 2000;

#if SYNC_TYPE == SYNC_USE_MILLISECONDS
static constexpr uint64_t DELAY_PACKET_SPACING = DELAY_PACKET_SPACING_MS;
static constexpr uint64_t DELAY_RECV_SPACING = DELAY_RECV_SPACING_MS;
static constexpr uint64_t MAX_PACKET_END_DELAY = MAX_PACKET_END_DELAY_MS;
static constexpr uint64_t MAX_PUNCH_START_DELAY = MAX_PUNCH_START_DELAY_MS;
#elif SYNC_TYPE == SYNC_USE_MICROSECONDS
static constexpr uint64_t DELAY_PACKET_SPACING = DELAY_PACKET_SPACING_MS * 1000;
static constexpr uint64_t DELAY_RECV_SPACING = 100;
static constexpr uint64_t MAX_PACKET_END_DELAY = MAX_PACKET_END_DELAY_MS * 1000;
static constexpr uint64_t MAX_PUNCH_START_DELAY = MAX_PUNCH_START_DELAY_MS * 1000;
#endif

// Function for telling the server what the external port of this
// client is for a lobby based match. This should not be delayed
// relative to the start of the hooks.
template<bool is_welcome = false>
static void send_lobby_name_packet(SOCKET sock, const char* nickname, size_t length) {
    PacketLobbyName* name_packet = (PacketLobbyName*)_alloca(LOBBY_NAME_PACKET_SIZE(length));
    if constexpr (is_welcome) {
        name_packet->type = PACKET_TYPE_LOBBY_NAME_WAIT;
    } else {
        name_packet->type = PACKET_TYPE_LOBBY_NAME;
    }
    name_packet->length = length;
    memcpy(name_packet->name, nickname, length);

    int success = sendto(sock, (const char*)name_packet, LOBBY_NAME_PACKET_SIZE(length), 0, (const sockaddr*)&lobby_addr, lobby_addr_length);
    lobby_debug_printf(!is_welcome ? "Sending nickA (%zu):%s\n" : "Sending nickB (%zu):%s\n", length, nickname);
    if (success != SOCKET_ERROR) {
        if constexpr (is_welcome) {
            respond_to_punch_ping = true;
        }
    } else {
        lobby_debug_printf("FAILED nick:%u\n", WSAGetLastError());
    }
}

// Function for telling the server what the external port of this
// client is for a direct connect match. The server also sends
// extra packets periodically so that it can remove a client that
// left the waiting menu from the internal data structures.
void send_lobby_punch_wait() {
    PacketPunchWait packet;
    //new (&packet) PacketPunchWait(local_addr, local_addr_length);
    new (&packet) PacketPunchWait();

    int ret = sendto(punch_socket, (const char*)&packet, sizeof(PacketPunchWait), 0, (const sockaddr*)&lobby_addr, lobby_addr_length);
    if (ret > 0) {
        respond_to_punch_ping = true;
    } else {
        lobby_debug_printf("FAILED wait:%u\n", WSAGetLastError());
    }
}

static WSABUF PUNCH_BUF = {
    .len = sizeof(PUNCH_PACKET),
    .buf = (CHAR*)&PUNCH_PACKET
};

static void send_punch_packets(SOCKET sock, const sockaddr* addr, int addr_len) {
    DWORD idc;
    for (size_t i = 0; i < 30; ++i) {
        WSASendTo_log(sock, &PUNCH_BUF, 1, &idc, 0, addr, addr_len, NULL, NULL);
    }
}

void send_punch_response(bool is_ipv6, const void* ip, uint16_t port) {
    sockaddr_storage addr;
    if (!is_ipv6) {
        INIT_SOCKADDR_IN4(addr, *(in_addr*)ip, hton(port));
    } else {
        INIT_SOCKADDR_IN6(addr, *(in6_addr*)ip, hton(port));
    }
    
    SOCKET sock = punch_socket;
    if (sock != INVALID_SOCKET) {
        START_PUNCH_SET_FLAG();
        send_punch_packets(sock, (const sockaddr*)&addr, !is_ipv6 ? sizeof(sockaddr_in) : sizeof(sockaddr_in6));
    }
}

void send_punch_delay_pong(SOCKET sock, const void* buf, size_t length) {
    sendto(sock, (const char*)buf, length, 0, (const sockaddr*)&lobby_addr, lobby_addr_length);
}

template <bool is_lobby>
static inline void send_delayed_punch_packets(SOCKET sock, const sockaddr_storage& addr, int addr_len) {
    PUNCH_BOOST_START();

    set_blocking_state<false>(sock);

    PacketPunchDelayPing packet;
    new (&packet) PacketPunchDelayPing(addr);

    uint32_t received_number = 0;
    uint64_t total_delay = 0;
    delay_mask_t recv_mask = 0;

    int64_t most_recent_sync_time = current_sync_time();
    int64_t initial_sync_time;
        
    auto recv_multiple_delay_packets = [&](uint64_t sleep_time) lambda_forceinline {
        do {
            sockaddr_storage recv_addr;
            int recv_addr_len = sizeof(sockaddr_storage);
            size_t index;
            int ret = recvfrom(sock, pong_recv, sizeof(pong_recv), 0, (sockaddr*)&recv_addr, &recv_addr_len);
            if (ret > 0) {
                if (
                    ((PacketPunchDelayPong*)pong_recv)->type == PACKET_TYPE_PUNCH_DELAY_PONGB &&
                    (index = ((PacketPunchDelayPong*)pong_recv)->index) < countof(sending_times) &&
                    !(recv_mask & (delay_mask_t)1 << index) &&
                    addr_is_lobby((sockaddr*)&recv_addr, recv_addr_len)
                ) {
                    total_delay += most_recent_sync_time - sending_times[index];
                    recv_mask |= (delay_mask_t)1 << index;
                    if (++received_number == countof(sending_times)) {
                        return true;
                    }
                }
            }
            //else if (ret < 0) {
                //log_printf("recvfrom error %d %d\n", ret, WSAGetLastError());
            //}
            int64_t cur_sync_time;
            if constexpr (DELAY_RECV_SPACING == 1) {
#if PUNCH_SLEEP_TYPE == PUNCH_SLEEP_USE_SPIN
                while (most_recent_sync_time == (cur_sync_time = current_sync_time()));
                most_recent_sync_time = cur_sync_time;
#elif PUNCH_SLEEP_TYPE == PUNCH_SLEEP_USE_TIMER
                cur_sync_time = current_sync_time();
                bool needs_sleep = most_recent_sync_time == cur_sync_time;
                most_recent_sync_time = cur_sync_time;
                if (needs_sleep) {
                    punch_timer.wait_sync(1);
                    most_recent_sync_time = current_sync_time();
                }
#endif
            } else {
#if PUNCH_SLEEP_TYPE == PUNCH_SLEEP_USE_SPIN
                do cur_sync_time = current_sync_time();
                while (cur_sync_time - most_recent_sync_time < DELAY_RECV_SPACING);
                most_recent_sync_time = cur_sync_time;
#elif PUNCH_SLEEP_TYPE == PUNCH_SLEEP_USE_TIMER
                cur_sync_time = current_sync_time();
                int64_t sync_diff = DELAY_RECV_SPACING - (cur_sync_time - most_recent_sync_time);
                most_recent_sync_time = cur_sync_time;
                if (sync_diff > 0) {
                    punch_timer.wait_sync(sync_diff);
                    most_recent_sync_time = current_sync_time();
                }
#endif
            }
        } while (most_recent_sync_time - initial_sync_time < sleep_time);
        return false;
    };

    size_t i = 0;
    while (true) {
        initial_sync_time = most_recent_sync_time;
        sending_times[i] = most_recent_sync_time;
        sendto(sock, (const char*)&packet, sizeof(packet), 0, (const sockaddr*)&lobby_addr, lobby_addr_length);

        if (recv_multiple_delay_packets(DELAY_PACKET_SPACING)) {
            goto finished_receive;
        }

        if (++i >= countof(sending_times)) {
            break;
        }

        // Increment the index in the send packet
        ++packet.flags;
    }

    initial_sync_time = most_recent_sync_time;
    recv_multiple_delay_packets(MAX_PACKET_END_DELAY);
        
    if (received_number) {
finished_receive:
        total_delay /= received_number * 2;

        if constexpr (is_lobby) {
            packet.type = PACKET_TYPE_PUNCH_DELAY_PONGA;
        } else {
            packet.type = PACKET_TYPE_PUNCH_CONNECT;
        }
        sendto(sock, (const char*)&packet, sizeof(packet), 0, (const sockaddr*)&lobby_addr, lobby_addr_length);

#if PUNCH_SLEEP_TYPE == PUNCH_SLEEP_USE_SPIN
        spin_for_sync_time(total_delay);
#elif PUNCH_SLEEP_TYPE == PUNCH_SLEEP_USE_TIMER
        punch_timer.wait_sync(total_delay);
#endif
    }

    send_punch_packets(sock, (const sockaddr*)&addr, addr_len);

#if CONNECTION_LOGGING & CONNECTION_LOGGING_UDP_PACKETS
    log_printf(
#if SYNC_TYPE == SYNC_USE_MILLISECONDS
        "DELAY: %llu ms (%zu responses)\n"
#elif SYNC_TYPE == SYNC_USE_MICROSECONDS
        "DELAY: %llu microseconds (%zu responses)\n"
#endif
        , total_delay, received_number
    );
#endif

    set_blocking_state<true>(sock);

    PUNCH_BOOST_END();
}

void send_lobby_punch_connect(bool is_ipv6, const char* ip, uint16_t port) {
    sockaddr_storage addr = {};
    int addr_len;
    if (!is_ipv6) {
        addr.ss_family = AF_INET;
        ((sockaddr_in*)&addr)->sin_port = hton(port);
        inet_pton(AF_INET, ip, &((sockaddr_in*)&addr)->sin_addr);
        addr_len = sizeof(sockaddr_in);
    } else {
        addr.ss_family = AF_INET6;
        ((sockaddr_in6*)&addr)->sin6_port = hton(port);
        inet_pton(AF_INET6, ip, &((sockaddr_in6*)&addr)->sin6_addr);
        addr_len = sizeof(sockaddr_in6);
    }

    // This ends up blocking the GUI thread, but it's only the direct
    // connect menu, so it's probably fine?
    send_delayed_punch_packets<false>(punch_socket, addr, addr_len);
}

/*
typedef int thisfastcall send_text_t(
    void* self,
    thisfastcall_edx(int dummy_edx,)
    const char* str
);

int thisfastcall log_sent_text(
    void* self,
    thisfastcall_edx(int dummy_edx,)
    const char* str
) {
    lobby_debug_printf("Sending:%s", str);
    return based_pointer<send_text_t>(lobby_base_address, 0x20820)(
        self,
        thisfastcall_edx(dummy_edx,)
        str
    );
}
*/

typedef int thisfastcall lobby_send_string_t(
    AsyncLobbyClient* self,
    thisfastcall_edx(int dummy_edx,)
    const char* str
);

// Function for joining clients to request a match via a
// REQUEST_MATCH message in the lobby.
// Do *not* block in this function, because the host could
// receive multiple match requests and will only acknowledge one.
int thisfastcall lobby_send_string_udp_send_hook_REQUEST(
    AsyncLobbyClient* self,
    thisfastcall_edx(int dummy_edx,)
    const char* str
) {
    SOCKET sock = get_or_recreate_punch_socket(!ScrollLockOn() ? 0 : self->local_port);
    if (sock != INVALID_SOCKET) {
        send_lobby_name_packet(sock, self->current_nickname.data(), self->current_nickname.length());
    }
    return based_pointer<lobby_send_string_t>(lobby_base_address, 0x20820)(
        self,
        thisfastcall_edx(dummy_edx,)
        str
    );
}

// Outdated function for a hosting client to acknowledge a match
// request. Replaced to avoid relying on std::string ABI, but kept
// around just incase the large binary patches of the new version
// end up being an issue.
/*
int thisfastcall lobby_send_string_udp_send_hook_WELCOME(
    AsyncLobbyClient* self,
    thisfastcall_edx(int dummy_edx,)
    const char* str
) {
    SOCKET sock = get_or_create_punch_socket(self->local_port);
    if (sock != INVALID_SOCKET) {
        send_lobby_name_packet<true>(sock, self->current_nickname.data(), self->current_nickname.length());
    }
    return based_pointer<lobby_send_string_t>(lobby_base_address, 0x20820)(
        self,
        thisfastcall_edx(dummy_edx,)
        str
    );
}
*/

// Function for a hosting client to acknowledge a REQUEST_MATCH
// message with a WELCOME message. Any code for hole punching
// host->client should happen here.
// The regular match hosting code runs after this function, so
// it's okay to block.
int fastcall lobby_send_string_udp_send_hook_WELCOME2(
    AsyncLobbyClient* self,
    size_t current_nickname_length,
    const char* str,
    const char* host,
    const char* current_nickname,
    uint16_t port
) {
    SOCKET sock = get_or_create_punch_socket(!ScrollLockOn() ? self->local_port : 0);
    if (sock != INVALID_SOCKET) {
        send_lobby_name_packet<true>(sock, current_nickname, current_nickname_length);
        START_PUNCH_RESET_FLAG();
    }

    int ret = based_pointer<lobby_send_string_t>(lobby_base_address, 0x20820)(
        self,
        thisfastcall_edx(0,)
        str
    );

    if (sock != INVALID_SOCKET) {
        sockaddr_storage client_addr;
        int client_addr_len = init_sockaddr(client_addr, false, host, port);

        PUNCH_BOOST_START();

        START_PUNCH_WAIT(MAX_PUNCH_START_DELAY);
        send_punch_packets(sock, (const sockaddr*)&client_addr, client_addr_len);

        PUNCH_BOOST_END();
    }
    return ret;
}

static constexpr uint8_t lobby_send_welcome_patchA[] = {
    0x56,                                       // PUSH ESI
    0x57,                                       // PUSH EDI
    0x8B, 0xB5, 0xCC, 0xF6, 0xFF, 0xFF,         // MOV ESI, DWORD PTR [EBP-934]
    0xFF, 0x75, 0x08,                           // PUSH DWORD PTR [EBP+8]
    0x8D, 0x8E, 0x24, 0x04, 0x00, 0x00,         // LEA ECX, [ESI+424]
    0xE8, 0xFD, 0x2B, 0x00, 0x00,               // CALL std::string::operator=(const char*)
    0x6A, 0x02,                                 // PUSH 2
    0x8D, 0x8D, 0xC0, 0xF6, 0xFF, 0xFF,         // LEA ECX, [EBP-940]
    0xE8, 0x10, 0x25, 0x00, 0x00,               // CALL std::vector<std::string>::operator[]
    0x89, 0xC7,                                 // MOV EDI, EAX
    0x50,                                       // PUSH EAX
    0x8D, 0x8E, 0xE0, 0x03, 0x00, 0x00,         // LEA ECX, [ESI+3E0]
    0xE8, 0x02, 0x2C, 0x00, 0x00,               // CALL std::string::operator=(const std::string&)
    0x89, 0xF9,                                 // MOV ECX, EDI
    0xE8, 0xDB, 0x2A, 0x00, 0x00,               // CALL std::string::c_str
    0x50,                                       // PUSH EAX
    0xE8, 0xC8, 0x7B, 0x03, 0x00,               // CALL _atoi
    0x59,                                       // POP ECX
    0x89, 0xC7,                                 // MOV EDI, EAX
    0x8D, 0x8E, 0xB0, 0x03, 0x00, 0x00,         // LEA ECX, [ESI+3B0]
    0xE8, 0xC7, 0x2A, 0x00, 0x00,               // CALL std::string::c_str
    0x50,                                       // PUSH EAX
    0xFF, 0xB6, 0xF8, 0x03, 0x00, 0x00,         // PUSH DWORD PTR [ESI+3F8]
    0xFF, 0x75, 0x08,                           // PUSH DWORD PTR [EBP+8]
    0x8D, 0x8E, 0x38, 0x03, 0x00, 0x00,         // LEA ECX, [ESI+338]
    0xE8, 0xB2, 0x2A, 0x00, 0x00,               // CALL std::string::c_str
    0x50,                                       // PUSH EAX
    0x68                                        // PUSH imm32
};

static constexpr uint8_t lobby_send_welcome_patchB[] = {
    0x8D, 0x8D, 0xF0, 0xF7, 0xFF, 0xFF,         // LEA ECX, [EBP-810]
    0x51,                                       // PUSH ECX
    0xE8, 0x50, 0x8E, 0xFF, 0xFF,               // CALL _sprintf
    0x83, 0xC4, 0x18,                           // ADD ESP, 18
    0x57,                                       // PUSH EDI
    0x8D, 0xBE, 0x08, 0x03, 0x00, 0x00,         // LEA EDI, [ESI+308]
    0x89, 0xF9,                                 // MOV ECX, EDI
    0xE8, 0x8F, 0x2A, 0x00, 0x00,               // CALL std::string::c_str
    0x50,                                       // PUSH EAX
    0xFF, 0x75, 0x0C,                           // PUSH DWORD PTR [EBP+C]
    0x8D, 0x95, 0xF0, 0xF7, 0xFF, 0xFF,         // LEA EDX, [EBP-810]
    0x52,                                       // PUSH EDX
    0x89, 0xF9,                                 // MOV ECX, EDI
    0xE8, 0x5D, 0x2A, 0x00, 0x00,               // CALL std::string::length
    0x89, 0xC2,                                 // MOV EDX, EAX
    0x89, 0xF1,                                 // MOV ECX, ESI
    0xE8                                        // CALL rel32
};

static constexpr uint8_t lobby_send_welcome_patchC[] = {
    0x8B, 0x8D, 0xB8, 0xF6, 0xFF, 0xFF,         // MOV ECX, DWORD PTR [EBP-948]
    0x89, 0x8E, 0x18, 0x04, 0x00, 0x00,         // MOV DWORD PTR [ESI+418], ECX
    0xC6, 0x86, 0x20, 0x04, 0x00, 0x00, 0x01,   // MOV BYTE PTR [ESI+420], 1
    0x5F,                                       // POP EDI
    0x5E,                                       // POP ESI
    BASE_NOP(28)
};

typedef msvc_string* cdecl lobby_std_string_concat_t(msvc_string*, msvc_string*, msvc_string*);

// Function for a joining client to acknowledge a WELCOME
// message. Any code for hole punching client->host should happen here.
// The regular match joining code runs after this function, so
// it's okay to block.
msvc_string* fastcall lobby_recv_welcome_hook(
    const char* host,
    msvc_string* port,
    msvc_string* out_str,
    msvc_string* strB
) {

    SOCKET sock = get_punch_socket();
    if (sock != INVALID_SOCKET) {
        sockaddr_storage client_addr;
        int client_addr_len = init_sockaddr(client_addr, false, host, atoi(port->data()));

        send_delayed_punch_packets<true>(sock, client_addr, client_addr_len);
    }

    return based_pointer<lobby_std_string_concat_t>(lobby_base_address, 0x12920)(out_str, strB, port);
}

static constexpr uint8_t lobby_recv_welcome_patchA[] = {
    0x89, 0xC2,                                 // MOV EDX, EAX
    0x8B, 0x4D, 0x0C,                           // MOV ECX, DWORD PTR [EBP+C]
    0xFF, 0xB5, 0xA8, 0xF6, 0xFF, 0xFF,         // PUSH DWORD PTR [EBP-958]
    0x8D, 0x85, 0x48, 0xF7, 0xFF, 0xFF,         // LEA EAX, [EBP-8B8]
    0x50                                        // PUSH EAX
};

static constexpr uint8_t lobby_recv_welcome_patchB[] = {
    0x89, 0xC2,                                 // MOV EDX, EAX
    0x8B, 0x4D, 0x0C,                           // MOV ECX, DWORD PTR [EBP+C]
    0xFF, 0xB5, 0x94, 0xF6, 0xFF, 0xFF,         // PUSH DWORD PTR [EBP-96C]
    0x8D, 0x85, 0x00, 0xF7, 0xFF, 0xFF,         // LEA EAX, [EBP-900]
    0x50                                        // PUSH EAX
};

#if CONNECTION_LOGGING & CONNECTION_LOGGING_LOBBY_PACKETS
int WSAAPI lobby_recv_hook(SOCKET s, char* buf, int len, int flags) {
    int ret = recv(s, buf, len, flags);
    if (ret != SOCKET_ERROR) {
        lobby_debug_printf("RECV:%s", buf);
    }
    return ret;
}
#endif

typedef int thisfastcall lobby_connect_t(
    void* self,
    thisfastcall_edx(int dummy_edx,)
    const char* server,
    const char* port,
    const char* password,
    const char* lobby_nameA,
    const char* lobby_nameB
);

int thisfastcall lobby_connect_hook(
    void* self,
    thisfastcall_edx(int dummy_edx,)
    const char* server,
    const char* port,
    const char* password,
    const char* lobby_nameA,
    const char* lobby_nameB
) {
    return based_pointer<lobby_connect_t>(lobby_base_address, 0x53B0)(
        self,
        thisfastcall_edx(dummy_edx, )
        get_lobby_host(server),
        get_lobby_port(port),
        get_lobby_pass(password),
        lobby_nameA,
        lobby_nameB
    );
}

static inline constexpr addrinfo udp_addr_hint = {
    .ai_flags = AI_NUMERICHOST | AI_NUMERICSERV | AI_ALL,
    .ai_family = AF_INET6,
    .ai_socktype = SOCK_DGRAM,
    .ai_protocol = IPPROTO_UDP
};

neverinline void lobby_test_ipv6() {
    SOCKET sock = ::socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP);
    if (sock != INVALID_SOCKET) {
        //log_printf("IPv6: Socket created\n");

        BOOL val = FALSE;
        setsockopt(sock, IPPROTO_IPV6, IPV6_V6ONLY, (const char*)&val, sizeof(BOOL));

        IP6_ADDRESS ipv6;
        IP6_ADDRESS* ipv6_ptr;
        switch (lobby_addr.ss_family) {
            default:
                goto ipv6_fail;
            case AF_INET:
                ipv6.IP6Dword[0] = 0;
                ipv6.IP6Dword[1] = 0;
                ipv6.IP6Dword[2] = 0xFFFF0000;
                ipv6.IP6Dword[3] = *(IP4_ADDRESS*)&((sockaddr_in*)&lobby_addr)->sin_addr;
                ipv6_ptr = &ipv6;
                break;
            case AF_INET6:
                ipv6_ptr = (IP6_ADDRESS*)&((sockaddr_in6*)&lobby_addr)->sin6_addr;
                break;
        }

        char ip_str[INET6_ADDRSTRLEN];
        inet_ntop(AF_INET6, ipv6_ptr, ip_str, countof(ip_str));

        char port_str[INTEGER_BUFFER_SIZE<uint16_t>]{};
        uint16_to_strbuf(ntoh<uint16_t>(((sockaddr_in*)&lobby_addr)->sin_port), port_str);

        //log_printf("IPv6: Connecting to %s:%s\n", ip_str, port_str);

        addrinfo* addrs;
        if (getaddrinfo(ip_str, port_str, &udp_addr_hint, &addrs) == 0) {
            addrinfo* cur_addr = addrs;
            do {
                if (cur_addr->ai_family == AF_INET6) {
                    if (connect(sock, (const sockaddr*)cur_addr->ai_addr, cur_addr->ai_addrlen) == 0) {
                        freeaddrinfo(addrs);

                        PacketIPv6Test test_packet = {};
                        test_packet.type = PACKET_TYPE_IPV6_TEST;
                        QueryPerformanceCounter(&test_packet.tsc);
                        uint64_t tsc = test_packet.tsc.QuadPart;

                        DWORD timeout = 5000;
                        setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (const char*)&timeout, sizeof(DWORD));

                        u_long nonblocking_state = true;
                        ioctlsocket(sock, FIONBIO, &nonblocking_state);

                        send(sock, (const char*)&test_packet, sizeof(test_packet), 0);

                        test_packet = {};

                        int recv_ret = recv(sock, (char*)&test_packet, sizeof(test_packet), 0);
                        if (
                            recv_ret == sizeof(test_packet) &&
                            test_packet.type == PACKET_TYPE_IPV6_TEST &&
                            tsc == test_packet.tsc.QuadPart
                        ) {
                            closesocket(sock);
                            //log_printf("IPv6: Timed out\n");
                            set_ipv6_state(true);
                            return;
                        }
                        //log_printf("IPv6: Timed out\n");
                        goto ipv6_fail;
                    }
                }
            } while ((cur_addr = cur_addr->ai_next));
            freeaddrinfo(addrs);
            //log_printf("IPv6: Failed to find addr\n");
        }

ipv6_fail:
        closesocket(sock);
    }
    set_ipv6_state(false);
}

int WSAAPI lobby_socket_connect_hook(SOCKET s, const sockaddr* name, int namelen) {
    int ret = connect(s, name, namelen);
    if (ret == 0) {
        memcpy(&lobby_addr, name, lobby_addr_length = namelen);

        //local_addr_length = sizeof(sockaddr_storage);
        //getsockname(s, (sockaddr*)&local_addr, (int*)&local_addr_length);

        //log_printf("Local IP: ");
        //print_sockaddr((sockaddr*)&local_addr);
        //log_printf("\n");

        if (get_ipv6_state() == IPv6NeedsTest) {
            lobby_test_ipv6();
        }
    }
    return ret;
}

int WSAAPI lobby_socket_close_hook(SOCKET s) {
    //memset(&lobby_addr, 0, sizeof(lobby_addr));
    int ret = closesocket(s);
    if (ret == 0) {
        std::lock_guard<SpinLock> lock(punch_lock);

        SOCKET sock = punch_socket;
        punch_socket = INVALID_SOCKET;
        if (
            sock != INVALID_SOCKET &&
            !punch_socket_is_inherited
        ) {
            lobby_debug_printf("Closing the punch socket. Bad? (Lobby close)\n");
            closesocket(sock);
#if CONNECTION_LOGGING & CONNECTION_LOGGING_UDP_PACKETS
            SENDTO_ADDR = {};
            RECVFROM_ADDR = {};
            SENDTO_ADDR_LEN = 0;
            RECVFROM_ADDR_LEN = 0;
            SENDTO_TYPE = UINT8_MAX;
            RECVFROM_TYPE = UINT8_MAX;
#endif
        }
        punch_socket_is_loaned = false;
        punch_socket_is_inherited = false;
    }
    return ret;
}

#if CONNECTION_LOGGING & CONNECTION_LOGGING_UDP_PACKETS

#include "fake_lag.h"

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
) {
    if (lpTo->sa_family == AF_INET) {

        /*
        char sendto_buff[countof(SENDTO_STR)];
        snprintf(sendto_buff, countof(sendto_buff), "SENDTO: %s:%u\n", ip_buffer, port);
        if (strcmp(sendto_buff, SENDTO_STR)) {
            memcpy(SENDTO_STR, sendto_buff, sizeof(SENDTO_STR));
            log_printf("%s", SENDTO_STR);
        }
        */

        uint8_t send_type = *(uint8_t*)lpBuffers[0].buf;
        if (
#if ONLY_LOG_CUSTOM_PACKETS
            send_type >= 0x80 &&
#endif
            (
                iTolen != SENDTO_ADDR_LEN ||
                send_type != SENDTO_TYPE ||
                memcmp(lpTo, &SENDTO_ADDR, iTolen)
            )
        ) {
            SENDTO_TYPE = send_type;
            SENDTO_ADDR_LEN = iTolen;
            memcpy(&SENDTO_ADDR, lpTo, iTolen);

            char ip_buffer[INET_ADDRSTRLEN];
            inet_ntop(AF_INET, &((sockaddr_in*)lpTo)->sin_addr, ip_buffer, countof(ip_buffer));
            uint16_t port = ntoh<uint16_t>(((sockaddr_in*)lpTo)->sin_port);
            lobby_debug_printf("SENDTO: %s:%u type %hhu (PUNCH: %s)\n", ip_buffer, port, send_type, bool_str(s == punch_socket));
        }

        //log_printf("SENDTO: %s:%u\n", ip_buffer, port);
    }
    int ret = WSASendTo(s, lpBuffers, dwBufferCount, lpNumberOfBytesSent, dwFlags, lpTo, iTolen, lpOverlapped, lpCompletionRoutine);
    if (ret == SOCKET_ERROR) {
        int error = WSAGetLastError();
        if (error != WSA_IO_PENDING) {
            lobby_debug_printf("SENDTO: FAIL %u\n", error);
        }
    }
    return ret;
}

#ifdef WSASendTo
#undef WSASendTo
#endif

void recvfrom_log(
    void* data,
    size_t data_length,
    sockaddr* from,
    int from_length
) {
    if (from->sa_family == AF_INET) {
        uint8_t from_type = *(uint8_t*)data;
        if (
#if ONLY_LOG_CUSTOM_PACKETS
            from_type >= 0x80 &&
#endif
            (
                from_length != RECVFROM_ADDR_LEN ||
                from_type != RECVFROM_TYPE ||
                memcmp(from, &RECVFROM_ADDR, from_length)
            )
        ) {
            RECVFROM_TYPE = from_type;
            RECVFROM_ADDR_LEN = from_length;
            memcpy(&RECVFROM_ADDR, from, from_length);

            char ip_buffer[INET_ADDRSTRLEN];
            inet_ntop(AF_INET, &((sockaddr_in*)from)->sin_addr, ip_buffer, countof(ip_buffer));
            uint16_t port = ntoh<uint16_t>(((sockaddr_in*)from)->sin_port);
            lobby_debug_printf("RECVFROM: %s:%u type %hhu\n", ip_buffer, port, from_type);
        }
    }
}

#endif

static constexpr uint8_t lobby_user_count_patchA[] = {
    0x57,                                   // PUSH EDI
    0x56,                                   // PUSH ESI
    0x53,                                   // PUSH EBX
    0x8D, 0x8D, 0x98, 0xFD, 0xFF, 0xFF,     // LEA ECX, [EBP-268]
    0x89, 0xCF,                             // MOV EDI, ECX
    0xE8, 0xA7, 0x30, 0x00, 0x00,           // CALL std::vector<std::string>::size
    0x83, 0xF8, 0x02,                       // CMP EAX, 2
    0x0F, 0x82, 0xF1, 0x00, 0x00, 0x00,     // JB Rx7A13
    0x89, 0xC3,                             // MOV EBX, EAX
    0x6A, 0x01,                             // PUSH 1
    0x89, 0xF9,                             // MOV ECX, EDI
    0xE8, 0x73, 0x30, 0x00, 0x00,           // CALL std::vector<std::string>::operator[]
    0x89, 0x85, 0x18, 0xFD, 0xFF, 0xFF,     // MOV [EBP-2E8], EAX
    0x83, 0xFB, 0x03,                       // CMP EBX, 3
    0x0F, 0x82, 0xAA, 0x00, 0x00, 0x00,     // JB Rx79E6
    0x68,                                   // PUSH imm32
};

static constexpr uint8_t lobby_user_count_patchB[] = {
    0x50,                                   // PUSH EAX
    0xE8, 0x69, 0xAE, 0x00, 0x00,           // CALL std::operator==(std::string& strA, char* strB)
    0x83, 0xC4, 0x08,                       // ADD ESP, 8
    0x84, 0xC0,                             // TEST AL, AL
    0x0F, 0x84, 0xBF, 0x00, 0x00, 0x00,     // JZ Rx7A11
    0x8B, 0xB5, 0xA8, 0xFD, 0xFF, 0xFF,     // MOV ESI, [EBP-258]
    0x81, 0xC6, 0x08, 0x03, 0x00, 0x00,     // ADD ESI, 0x308
    0x56,                                   // PUSH ESI
    0x8D, 0x55, 0xD8,                       // LEA EDX, [EBP-28]
    0x52,                                   // PUSH EDX
    0xE8, 0x68, 0xB1, 0x00, 0x00,           // CALL std::operator==(std::string* strA, std::string* strB)
    0x83, 0xC4, 0x08,                       // ADD ESP, 8
    0x84, 0xC0,                             // TEST AL, AL
    0x0F, 0x84, 0x9E, 0x00, 0x00, 0x00,     // JZ Rx7A11
    0x6A, 0x02,                             // PUSH 2
    0x89, 0xF9,                             // MOV ECX, EDI
    0xE8, 0x24, 0x30, 0x00, 0x00,           // CALL std::vector<std::string>::operator[]
    0x50,                                   // PUSH EAX
    0x83, 0xC6, 0x30,                       // ADD ESI, 0x30
    0x89, 0xF1,                             // MOV ECX, ESI
    0xE8, 0x19, 0x37, 0x00, 0x00,           // CALL std::string::operator=(std::string& str)
    0x68,                                   // PUSH imm32
};

static constexpr uint8_t lobby_user_count_patchC[] = {
    0x8D, 0x4E, 0x48,                       // LEA ECX, [ESI+48]
    0xE8, 0xEC, 0x36, 0x00, 0x00,           // CALL std::string::operator=(char* str)
    0x83, 0xFB, 0x04,                       // CMP EBX, 4
    0x72, 0x17,                             // JB Rx79AE
    0x6A, 0x03,                             // PUSH 3
    0x89, 0xF9,                             // MOV ECX, EDI
    0xE8, 0xFE, 0x2F, 0x00, 0x00,           // CALL std::vector<std::string>::operator[]
    0x89, 0xC1,                             // MOV ECX, EAX
    0xE8, 0xD7, 0x35, 0x00, 0x00,           // CALL std::string::c_str
    0x89, 0xC1,                             // MOV ECX, EAX
    0xE8,                                   // CALL rel32
};

static constexpr uint8_t lobby_user_count_patchD[] = {
    0x89, 0xF1,                             // MOV ECX, ESI
    0xE8, 0xC9, 0x35, 0x00, 0x00,           // CALL std::string::c_str
    0x80, 0x38, 0x3A,                       // CMP BYTE PTR [EAX], 0x3A
    0x75, 0x55,                             // JNE Rx7A11
    0x89, 0xF1,                             // MOV ECX, ESI
    0xE8, 0x9D, 0x35, 0x00, 0x00,           // CALL std::string::length
    0x50,                                   // PUSH EAX
    0x6A, 0x01,                             // PUSH 1
    0x8D, 0xBD, 0x70, 0xFE, 0xFF, 0xFF,     // LEA EDI, [EBP-190]
    0x57,                                   // PUSH EDI
    0x89, 0xF1,                             // MOV ECX, ESI
    0xE8, 0xDC, 0x34, 0x00, 0x00,           // CALL std::string::__substr
    0x50,                                   // PUSH EAX
    0x89, 0xF1,                             // MOV ECX, ESI
    0xE8, 0x84, 0x37, 0x00, 0x00,           // CALL std::string::__sub_rB160
    0x89, 0xF9,                             // MOV ECX, EDI
    0xE8, 0x2D, 0x37, 0x00, 0x00,           // CALL std::string::destructor
    0xEB, 0x2C,                             // JMP Rx7A11
    0xCC,                                   // INT3
    0x6A, 0x00,                             // PUSH 0
    0x89, 0xF9,                             // MOV ECX, EDI
    0xE8, 0xB1, 0x2F, 0x00, 0x00,           // CALL std::vector<std::string>::operator[]
    0x68,                                   // PUSH imm32
};

static constexpr uint8_t lobby_user_count_patchE[] = {
    0x89, 0xC1,                             // MOV ECX, EAX
    0xE8, 0x05, 0x34, 0x00, 0x00,           // CALL std::string::compare(char* str)
    0x85, 0xC0,                             // TEST EAX, EAX
    0x75, 0x12,                             // JNZ Rx7A11
    0x8B, 0x8D, 0x18, 0xFD, 0xFF, 0xFF,     // MOV ECX, [EBP-2E8]
    0xE8, 0x76, 0x35, 0x00, 0x00,           // CALL std::string::c_str
    0x89, 0xC1,                             // MOV ECX, EAX
    0xE8,                                   // CALL rel32
};

static constexpr uint8_t lobby_user_count_patchF[] = {
    0x89, 0xD8,                             // MOV EAX, EBX
    0x5B,                                   // POP EBX
    0x5E,                                   // POP ESI
    0x5F,                                   // POP EDI
};

static void fastcall lobby_user_count_from_str(const char* count) {
    users_in_room = strtoul(count, NULL, 10);
}

void patch_se_lobby(void* base_address) {
    lobby_base_address = (uintptr_t)base_address;

#if ALLOCATION_PATCH_TYPE == PATCH_ALL_ALLOCS
    hotpatch_jump(based_pointer(base_address, 0x41007), my_malloc);
    hotpatch_jump(based_pointer(base_address, 0x402F8), my_calloc);
    hotpatch_jump(based_pointer(base_address, 0x41055), my_realloc);
    hotpatch_jump(based_pointer(base_address, 0x40355), my_free);
    hotpatch_jump(based_pointer(base_address, 0x4DCF1), my_recalloc);
    hotpatch_jump(based_pointer(base_address, 0x53F76), my_msize);
#endif

    //mem_write(based_pointer(base_address, 0x206F8), NOP_BYTES(2));
    //mem_write(based_pointer(base_address, 0x20872), NOP_BYTES(2));

    mem_write(based_pointer(base_address, 0x203AA), NOP_BYTES(55));

    hotpatch_rel32(based_pointer(base_address, 0x8C4C), lobby_connect_hook);

    hotpatch_icall(based_pointer(base_address, 0x202C1), lobby_socket_connect_hook);

    /*
    // lobby_socket_close_reg_swap
    mem_write(based_pointer(base_address, 0x2003E), PATCH_BYTES<
        0x8B, 0x3D, 0xFC,   // MOV ECX, DWORD PTR [EBP-4]
        0x8B, 0x41, 0x0C,   // MOV EAX, DWORD PTR [ECX+C]
        0x50                // PUSH EAX
    >);
    */
    hotpatch_icall(based_pointer(base_address, 0x20045), lobby_socket_close_hook);

    hotpatch_rel32(based_pointer(base_address, 0x6902), lobby_send_string_udp_send_hook_REQUEST);
    //hotpatch_rel32(based_pointer(base_address, 0x84E6), lobby_send_string_udp_send_hook_WELCOME);

    
    mem_write(based_pointer(base_address, 0x846D), lobby_send_welcome_patchA);
    mem_write(based_pointer(base_address, 0x84D0), based_pointer(base_address, 0x182A98));
    mem_write(based_pointer(base_address, 0x84D4), lobby_send_welcome_patchB);
    hotpatch_rel32(based_pointer(base_address, 0x8508), lobby_send_string_udp_send_hook_WELCOME2);
    mem_write(based_pointer(base_address, 0x850C), lobby_send_welcome_patchC);

    mem_write(based_pointer(base_address, 0x864B), lobby_recv_welcome_patchA);
    hotpatch_call(based_pointer(base_address, 0x865D), lobby_recv_welcome_hook);
    mem_write(based_pointer(base_address, 0x87FE), lobby_recv_welcome_patchB);
    hotpatch_call(based_pointer(base_address, 0x8810), lobby_recv_welcome_hook);
    

#if CONNECTION_LOGGING & CONNECTION_LOGGING_LOBBY_PACKETS
    hotpatch_icall(based_pointer(base_address, 0x2070B), lobby_recv_hook);
#endif

    // remove_dupe_host_check
    mem_write(based_pointer(base_address, 0x6610), PATCH_BYTES<0xEB, 0x3A>);


    //mem_write(based_pointer(base_address, 0x83C4), INT3_BYTES);

    //hotpatch_rel32(based_pointer(base_address, 0x4C6F), log_sent_text);
    //hotpatch_rel32(based_pointer(base_address, 0x4D33), log_sent_text);
    //hotpatch_rel32(based_pointer(base_address, 0x52C7), log_sent_text);
    //hotpatch_rel32(based_pointer(base_address, 0x62C7), log_sent_text);
    //hotpatch_rel32(based_pointer(base_address, 0x6902), log_sent_text);
    //hotpatch_rel32(based_pointer(base_address, 0x6E50), log_sent_text);
    //hotpatch_rel32(based_pointer(base_address, 0x6F4D), log_sent_text);
    //hotpatch_rel32(based_pointer(base_address, 0x7084), log_sent_text);
    //hotpatch_rel32(based_pointer(base_address, 0x7436), log_sent_text);
    //hotpatch_rel32(based_pointer(base_address, 0x7643), log_sent_text);
    //hotpatch_rel32(based_pointer(base_address, 0x7C67), log_sent_text);
    //hotpatch_rel32(based_pointer(base_address, 0x7D2D), log_sent_text);
    //hotpatch_rel32(based_pointer(base_address, 0x84E6), log_sent_text);

    mem_write(based_pointer(base_address, 0x7909), lobby_user_count_patchA);
    mem_write(based_pointer(base_address, 0x793D), based_pointer(base_address, 0x182A3C));
    mem_write(based_pointer(base_address, 0x7941), lobby_user_count_patchB);
    mem_write(based_pointer(base_address, 0x7988), based_pointer(base_address, 0x1828D4));
    mem_write(based_pointer(base_address, 0x798C), lobby_user_count_patchC);
    hotpatch_rel32(based_pointer(base_address, 0x79AC), lobby_user_count_from_str);
    mem_write(based_pointer(base_address, 0x79B0), lobby_user_count_patchD);
    mem_write(based_pointer(base_address, 0x79F0), (const char*)"USERS");
    mem_write(based_pointer(base_address, 0x79F4), lobby_user_count_patchE);
    hotpatch_rel32(based_pointer(base_address, 0x7A0D), lobby_user_count_from_str);
    mem_write(based_pointer(base_address, 0x7A11), lobby_user_count_patchF);

#if PUNCH_START_TYPE == PUNCH_START_USE_EVENT
    start_punch.initialize();
#endif

#if PUNCH_BOOST_TYPE & PUNCH_BOOST_TIMER_PRECISION
    TIMECAPS time_caps;
    timeGetDevCaps(&time_caps, sizeof(time_caps));
    minimum_timer_precision = time_caps.wPeriodMin;
#endif

#if PUNCH_SLEEP_TYPE == PUNCH_SLEEP_USE_TIMER
    punch_timer.initialize();
#endif
}