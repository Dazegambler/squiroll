#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <string>
//#include <mutex>

#include <winsock2.h>
#include <ws2tcpip.h>
//#include <MSWSock.h>

#include "util.h"
#include "config.h"
#include "PatchUtils.h"
#include "AllocMan.h"
#include "log.h"

struct AsyncLobbyClient {

    void* vftable; // 0x0

    unsigned char __unknown_A[0x4]; // 0x4

    int __lobby_state; // 0x8
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
    // 0x400
};

static_assert(sizeof(AsyncLobbyClient) == 0x400);


uintptr_t lobby_base_address = 0;


static SOCKET punch_socket = INVALID_SOCKET;

static sockaddr_storage lobby_addr = {};
static size_t lobby_addr_length = 0;

bool initialize_punch_socket(uint16_t port) {
    if (punch_socket == INVALID_SOCKET) {
        SOCKET sock = WSASocketW(AF_INET, SOCK_DGRAM, IPPROTO_UDP, NULL, 0, WSA_FLAG_OVERLAPPED);
        int error;
        if (sock != INVALID_SOCKET) {
            sockaddr_storage bind_addr;
            int bind_addr_length;
            switch (lobby_addr.ss_family) {
                    if (0) {
                case AF_INET:
                        *(sockaddr_in*)&bind_addr = (sockaddr_in){
                            AF_INET,
                            __builtin_bswap16(port),
                            INADDR_ANY
                        };
                        bind_addr_length = sizeof(sockaddr_in);
                    }
                    else {
                case AF_INET6:
                        *(sockaddr_in6*)&bind_addr = (sockaddr_in6){
                            .sin6_family = AF_INET6,
                            .sin6_port = __builtin_bswap16(port),
                            .sin6_addr = IN6ADDR_ANY_INIT
                        };
                        bind_addr_length = sizeof(sockaddr_in6);
                    }
                    if (!bind(sock, (const sockaddr*)&bind_addr, bind_addr_length)) {
                        punch_socket = sock;
                        return true;
                    }
            }
            error = WSAGetLastError();
            closesocket(sock);
        } else {
            error = WSAGetLastError();
        }
        log_printf("UDP socket fail:%u\n", error);
        return false;
    }
    return true;
}

SOCKET WSAAPI inherit_punch_socket(int af, int type, int protocol, LPWSAPROTOCOL_INFOW lpProtocolInfo, GROUP g, DWORD dwFlags) {
    SOCKET sock_ret = punch_socket;
    if (sock_ret != INVALID_SOCKET) {
        //punch_socket = INVALID_SOCKET;
        return sock_ret;
    }
    return WSASocketW(af, type, protocol, lpProtocolInfo, g, dwFlags);
}

int WSAAPI confirm_inherited_socket(SOCKET s, const sockaddr* name, int namelen) {
    if (s == punch_socket) {
        punch_socket = INVALID_SOCKET;
        return 0;
    }
    return bind(s, name, namelen);
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
    log_printf("Sending:%s", str);
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

int thisfastcall lobby_send_string_udp_send_hook(
    AsyncLobbyClient* self,
    thisfastcall_edx(int dummy_edx,)
    const char* str
) {
    if (initialize_punch_socket(self->local_port)) {
        char* nickname = self->current_nickname.data();
        int success = sendto(punch_socket, nickname, self->current_nickname.length(), 0, (const sockaddr*)&lobby_addr, lobby_addr_length);
        if (success != SOCKET_ERROR) {
            log_printf("Sending nick:%s\n", nickname);
        } else {
            log_printf("FAILED nick:%u\n", WSAGetLastError());
        }
    }
    return based_pointer<lobby_send_string_t>(lobby_base_address, 0x20820)(
        self,
        thisfastcall_edx(int dummy_edx,)
        str
    );
}

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

int WSAAPI lobby_socket_connect_hook(SOCKET s, const sockaddr* name, int namelen) {
    int ret = connect(s, name, namelen);
    if (ret == 0) {
        memcpy(&lobby_addr, name, lobby_addr_length = namelen);
    }
    return ret;
}

int WSAAPI lobby_socket_close_hook(SOCKET s) {
    int ret = closesocket(s);
    if (ret == 0) {
        if (punch_socket != INVALID_SOCKET) {
            closesocket(punch_socket);
            punch_socket = INVALID_SOCKET;
        }
    }
    return ret;
}

hostent* WSAAPI my_gethostbyname(const char* name) {
    log_printf("LOBBY HOST: %s\n", name);
    return gethostbyname(name);
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
    //hotpatch_import(based_pointer(base_address, 0x1292AC), my_gethostbyname);

    //mem_write(based_pointer(base_address, 0x206F8), NOP_BYTES<2>);
    //mem_write(based_pointer(base_address, 0x20872), NOP_BYTES<2>);

    mem_write(based_pointer(base_address, 0x203AA), NOP_BYTES<55>);

    hotpatch_rel32(based_pointer(base_address, 0x8C4C), lobby_connect_hook);

    hotpatch_icall(based_pointer(base_address, 0x202C1), lobby_socket_connect_hook);
    hotpatch_icall(based_pointer(base_address, 0x20045), lobby_socket_close_hook);

    hotpatch_rel32(based_pointer(base_address, 0x6902), lobby_send_string_udp_send_hook);
    hotpatch_rel32(based_pointer(base_address, 0x84E6), lobby_send_string_udp_send_hook);

    static constexpr uint8_t remove_dupe_host_check[] = { 0xEB, 0x3A };
    mem_write(based_pointer(base_address, 0x6610), remove_dupe_host_check);

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
}