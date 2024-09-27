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

#include <winsock2.h>
#include <ws2tcpip.h>
//#include <MSWSock.h>

#include "util.h"
#include "config.h"
#include "PatchUtils.h"
#include "AllocMan.h"
#include "log.h"

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

uintptr_t lobby_base_address = 0;

static SpinLock punch_lock;

static SOCKET punch_socket = INVALID_SOCKET;
static bool punch_socket_is_loaned = false;
static bool punch_socket_is_inherited = false;

static sockaddr_storage lobby_addr = {};
static size_t lobby_addr_length = 0;

//static char SENDTO_STR[256];
//static char RECVFROM_STR[256];

static sockaddr_storage SENDTO_ADDR = {};
static sockaddr_storage RECVFROM_ADDR = {};
static int SENDTO_ADDR_LEN = 0;
static int RECVFROM_ADDR_LEN = 0;

// EXE hook, overrides ref count
int WSAAPI close_punch_socket(SOCKET s) {
    if (s != INVALID_SOCKET) {
        std::lock_guard<SpinLock> lock(punch_lock);

        if (s == punch_socket) {
            log_printf("Closing the punch socket. Bad? A\n");
            //memset(SENDTO_STR, 0, sizeof(SENDTO_STR));
            //memset(RECVFROM_STR, 0, sizeof(RECVFROM_STR));
            SENDTO_ADDR = {};
            RECVFROM_ADDR = {};
            SENDTO_ADDR_LEN = 0;
            RECVFROM_ADDR_LEN = 0;
            //halt_and_catch_fire();
            punch_socket = INVALID_SOCKET;
            punch_socket_is_loaned = false;
            punch_socket_is_inherited = false;
        }
    }

    return closesocket(s);
}

SOCKET get_punch_socket() {
    std::lock_guard<SpinLock> lock(punch_lock);

    return punch_socket;
}

SOCKET get_or_create_punch_socket(uint16_t port) {
    std::lock_guard<SpinLock> lock(punch_lock);

    SOCKET sock = punch_socket;
    if (sock == INVALID_SOCKET) {
        sock = WSASocketW(AF_INET, SOCK_DGRAM, IPPROTO_UDP, NULL, 0, WSA_FLAG_OVERLAPPED);
        int error;
        if (sock != INVALID_SOCKET) {
            sockaddr_storage bind_addr;
            int bind_addr_length;
            switch (lobby_addr.ss_family) {
                    if (0) {
                case AF_INET:
                        *(sockaddr_in*)&bind_addr = (sockaddr_in){
#if !MINGW_COMPAT
                            .sin_family = AF_INET,
                            .sin_port = __builtin_bswap16(port),
                            .sin_addr = INADDR_ANY
#else
                            AF_INET,
                            __builtin_bswap16(port),
                            INADDR_ANY
#endif
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
                    //log_printf("BNDA:%u\n", port);
                    if (!bind(sock, (const sockaddr*)&bind_addr, bind_addr_length)) {
                        punch_socket = sock;
                        return sock;
                    }
            }
            log_printf("UDP bind fail (%u):%u\n", port, WSAGetLastError());
            closesocket(sock);
        } else {
            log_printf("UDP socket fail:%u\n", WSAGetLastError());
        }
    }
    return sock;
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

        if (!punch_socket_is_loaned) {
            return 0;
        }
    }
    /*
    uint16_t port = 0;
    switch (name->sa_family) {
        case AF_INET:
            port = ((const sockaddr_in*)name)->sin_port;
            break;
        case AF_INET6:
            port = ((const sockaddr_in6*)name)->sin6_port;
            break;
    }
    log_printf("BNDB:%u\n", __builtin_bswap16(port));
    */
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

int thisfastcall lobby_send_string_udp_send_hook_REQUEST(
    AsyncLobbyClient* self,
    thisfastcall_edx(int dummy_edx,)
    const char* str
) {
    SOCKET sock = INVALID_SOCKET;
    //if (!ScrollLockOn()) {
        sock = get_or_create_punch_socket(self->local_port);
    //}
    //else {
        //sock = get_punch_socket();
    //}
    if (sock != INVALID_SOCKET) {
        char* nickname = self->current_nickname.data();
        size_t length = self->current_nickname.length();
        int success = sendto(sock, nickname, length, 0, (const sockaddr*)&lobby_addr, lobby_addr_length);
        log_printf("Sending nick (%zu):%s\n", length, nickname);
        if (success == SOCKET_ERROR) {
            log_printf("FAILED nick:%u\n", WSAGetLastError());
        }
    }
    return based_pointer<lobby_send_string_t>(lobby_base_address, 0x20820)(
        self,
        thisfastcall_edx(dummy_edx,)
        str
    );
}

int thisfastcall lobby_send_string_udp_send_hook_WELCOME(
    AsyncLobbyClient* self,
    thisfastcall_edx(int dummy_edx,)
    const char* str
) {
    SOCKET sock = get_or_create_punch_socket(self->local_port);
    if (sock != INVALID_SOCKET) {
        char* nickname = self->current_nickname.data();
        size_t length = self->current_nickname.length();
        int success = sendto(sock, nickname, length, 0, (const sockaddr*)&lobby_addr, lobby_addr_length);
        log_printf("Sending nick (%zu):%s\n", length, nickname);
        if (success == SOCKET_ERROR) {
            log_printf("FAILED nick:%u\n", WSAGetLastError());
        }
    }
    return based_pointer<lobby_send_string_t>(lobby_base_address, 0x20820)(
        self,
        thisfastcall_edx(dummy_edx,)
        str
    );
}

static constexpr char DUMMY_SEND[1]{};

int fastcall lobby_send_string_udp_send_hook_WELCOME2(
    AsyncLobbyClient* self,
    size_t current_nickname_length,
    const char* str,
    const char* host,
    const char* current_nickname,
    uint16_t port
) {
    SOCKET sock = get_or_create_punch_socket(self->local_port);
    if (sock != INVALID_SOCKET) {
        int success = sendto(sock, current_nickname, current_nickname_length, 0, (const sockaddr*)&lobby_addr, lobby_addr_length);
        log_printf("Sending nick (%zu):%s\n", current_nickname_length, current_nickname);
        if (success == SOCKET_ERROR) {
            log_printf("FAILED nick:%u\n", WSAGetLastError());
        }
    }
    int ret = based_pointer<lobby_send_string_t>(lobby_base_address, 0x20820)(
        self,
        thisfastcall_edx(0,)
        str
    );

    if (sock != INVALID_SOCKET) {
        sockaddr_storage client_addr;
        client_addr.ss_family = AF_INET;
        ((sockaddr_in*)&client_addr)->sin_port = __builtin_bswap16(port);
        inet_pton(AF_INET, host, &((sockaddr_in*)&client_addr)->sin_addr);
        for (size_t i = 0; i < 30; ++i) {
            sendto(sock, DUMMY_SEND, sizeof(DUMMY_SEND), 0, (const sockaddr*)&client_addr, sizeof(sockaddr));
        }
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

typedef int WSAAPI lobby_recv_hook_t(SOCKET s, char* buf, int len, int flags);

int WSAAPI lobby_recv_hook(SOCKET s, char* buf, int len, int flags) {
    int ret = recv(s, buf, len, flags);
    if (ret != SOCKET_ERROR) {
        log_printf("RECV:%s", buf);
    }
    return ret;
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
            log_printf("Closing the punch socket. Bad? B\n");
            closesocket(sock);
            //memset(SENDTO_STR, 0, sizeof(SENDTO_STR));
            //memset(RECVFROM_STR, 0, sizeof(RECVFROM_STR));
            SENDTO_ADDR = {};
            RECVFROM_ADDR = {};
            SENDTO_ADDR_LEN = 0;
            RECVFROM_ADDR_LEN = 0;
        }
        punch_socket_is_loaned = false;
        punch_socket_is_inherited = false;
    }
    return ret;
}

hostent* WSAAPI my_gethostbyname(const char* name) {
    log_printf("LOBBY HOST: %s\n", name);
    return gethostbyname(name);
}

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

        if (
            iTolen != SENDTO_ADDR_LEN ||
            memcmp(lpTo, &SENDTO_ADDR, iTolen)
        ) {
            SENDTO_ADDR_LEN = iTolen;
            memcpy(&SENDTO_ADDR, lpTo, iTolen);

            char ip_buffer[INET_ADDRSTRLEN];
            inet_ntop(AF_INET, &((sockaddr_in*)lpTo)->sin_addr, ip_buffer, countof(ip_buffer));
            uint16_t port = __builtin_bswap16(((sockaddr_in*)lpTo)->sin_port);
            log_printf("SENDTO: %s:%u\n", ip_buffer, port);
        }

        //log_printf("SENDTO: %s:%u\n", ip_buffer, port);
    }
    int ret = WSASendTo(s, lpBuffers, dwBufferCount, lpNumberOfBytesSent, dwFlags, lpTo, iTolen, lpOverlapped, lpCompletionRoutine);
    if (ret == SOCKET_ERROR) {
        int error = WSAGetLastError();
        if (error != WSA_IO_PENDING) {
            log_printf("SENDTO: FAIL %u\n", error);
        }
    }
    return ret;
}

#ifdef WSASendTo
#undef WSASendTo
#endif

int WSAAPI WSARecvFrom_log(
    SOCKET s,
    LPWSABUF lpBuffers,
    DWORD dwBufferCount,
    LPDWORD lpNumberOfBytesRecvd,
    LPDWORD lpFlags,
    sockaddr *lpFrom,
    LPINT lpFromlen,
    LPWSAOVERLAPPED lpOverlapped,
    LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine
) {
    int ret = WSARecvFrom(s, lpBuffers, dwBufferCount, lpNumberOfBytesRecvd, lpFlags, lpFrom, lpFromlen, lpOverlapped, lpCompletionRoutine);
    if (ret != SOCKET_ERROR) {
        if (lpFrom->sa_family == AF_INET) {
            
            /*
            char recvfrom_buff[countof(RECVFROM_STR)];
            snprintf(recvfrom_buff, countof(recvfrom_buff), "RECVFROM: %s:%u\n", ip_buffer, port);
            if (strcmp(recvfrom_buff, RECVFROM_STR)) {
                memcpy(RECVFROM_STR, recvfrom_buff, sizeof(RECVFROM_STR));
                log_printf("%s", RECVFROM_STR);
            }
            */

            int from_length = *lpFromlen;

            if (
                from_length != RECVFROM_ADDR_LEN ||
                memcmp(lpFrom, &RECVFROM_ADDR, from_length)
            ) {
                RECVFROM_ADDR_LEN = from_length;
                memcpy(&RECVFROM_ADDR, lpFrom, from_length);

                char ip_buffer[INET_ADDRSTRLEN];
                inet_ntop(AF_INET, &((sockaddr_in*)lpFrom)->sin_addr, ip_buffer, countof(ip_buffer));
                uint16_t port = __builtin_bswap16(((sockaddr_in*)lpFrom)->sin_port);
                log_printf("RECVFROM: %s:%u\n", ip_buffer, port);
            }
            
            //log_printf("RECVFROM: %s:%u\n", ip_buffer, port);
        }
    } else {
        int error = WSAGetLastError();
        if (error != WSA_IO_PENDING) {
            log_printf("RECVFROM: FAIL %u\n", error);
        }
    }
    return ret;
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

    /*
    static constexpr uint8_t lobby_socket_close_reg_swap[] = {
        0x8B, 0x3D, 0xFC,   // MOV ECX, DWORD PTR [EBP-4]
        0x8B, 0x41, 0x0C,   // MOV EAX, DWORD PTR [ECX+C]
        0x50                // PUSH EAX
    };
    mem_write(based_pointer(base_address, 0x2003E), lobby_socket_close_reg_swap);
    */
    hotpatch_icall(based_pointer(base_address, 0x20045), lobby_socket_close_hook);

    hotpatch_rel32(based_pointer(base_address, 0x6902), lobby_send_string_udp_send_hook_REQUEST);
    hotpatch_rel32(based_pointer(base_address, 0x84E6), lobby_send_string_udp_send_hook_WELCOME);

    /*
    mem_write(based_pointer(base_address, 0x846D), lobby_send_welcome_patchA);
    mem_write(based_pointer(base_address, 0x84D0), based_pointer(base_address, 0x182A98));
    mem_write(based_pointer(base_address, 0x84D4), lobby_send_welcome_patchB);
    hotpatch_rel32(based_pointer(base_address, 0x8508), lobby_send_string_udp_send_hook_WELCOME2);
    mem_write(based_pointer(base_address, 0x850C), lobby_send_welcome_patchC);
    */

    hotpatch_icall(based_pointer(base_address, 0x2070B), lobby_recv_hook);

    static constexpr uint8_t remove_dupe_host_check[] = { 0xEB, 0x3A };
    mem_write(based_pointer(base_address, 0x6610), remove_dupe_host_check);


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
}