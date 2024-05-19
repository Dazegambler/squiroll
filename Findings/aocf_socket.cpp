//FOUND BY ZERO318
//Rx170620
struct UnknownA {
    int wsa_last_error;
    void* __ptr_4;
};

void* __sub_r2DBEE0(); // This does something with TLS and is called everywhere. Seems to be something about error handling

SOCKET __create_socket_r170620(int af, int type, int protocol, UnknownA* arg4) {
    WSASetLastError(0);
    SOCKET sock = WSASocketW(af, type, protocol, NULL, 0, WSA_FLAG_OVERLAPPED);
    void* local1 = __sub_r2DBEE0();
    int last_error = WSAGetLastError();
    arg4->wsa_last_error = last_error;
    arg4->__ptr_4 = local1;
    if (sock == INVALID_SOCKET) {
        return INVALID_SOCKET;
    }
    if (af == AF_INET6) {
        uint32_t opt_value = 0;
        setsockopt(sock, 41, 27, (char*)&opt_value, sizeof(opt_value));
    }
    arg4->__ptr_4 = __sub_r2DBEE0();
    arg4->wsa_last_error = ERROR_SUCCESS;
    return sock;
}
