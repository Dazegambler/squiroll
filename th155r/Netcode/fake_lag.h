#pragma once

#ifndef FAKE_LAG_H
#define FAKE_LAG_H 1

#include <stdlib.h>
#include <thread>

#define FAKE_SEND_LAG_AMOUNT 10000

#if FAKE_SEND_LAG_AMOUNT > 0
static inline DWORD idc_about_sent_bytes;
static int WSAAPI WSASendTo_fake_lag(SOCKET s, LPWSABUF lpBuffers, DWORD dwBufferCount, LPDWORD lpNumberOfBytesSent, DWORD dwFlags, const sockaddr* lpTo, int iTolen, LPWSAOVERLAPPED lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine) {
    __asm__("int 3");
    size_t data_size = 0;
    for (size_t i = 0; i < dwBufferCount; ++i) {
        data_size += lpBuffers[i].len;
    }
    if (lpNumberOfBytesSent) {
        *lpNumberOfBytesSent = data_size;
        lpNumberOfBytesSent = &idc_about_sent_bytes;
    }
    size_t wsabuf_size = sizeof(WSABUF) * dwBufferCount;
    uint8_t* send_data = (uint8_t*)malloc(wsabuf_size + iTolen + data_size);
    uint8_t* data_write = send_data + wsabuf_size;
    
    memcpy(data_write, lpTo, iTolen);
    lpTo = (const sockaddr*)data_write;
    data_write += iTolen;
    
    for (size_t i = 0; i < dwBufferCount; ++i) {
        size_t length = lpBuffers[i].len;
        ((LPWSABUF)send_data)[i].len = length;
        ((LPWSABUF)send_data)[i].buf = (CHAR*)data_write;
        memcpy(data_write, lpBuffers[i].buf, length);
        data_write += length;
    }
    
    std::thread([=](){
        Sleep(FAKE_SEND_LAG_AMOUNT);
        DWORD idc_about_sent_bytes;
        
        WSASendTo(s, (LPWSABUF)send_data, dwBufferCount, lpNumberOfBytesSent, dwFlags, lpTo, iTolen, lpOverlapped, lpCompletionRoutine);
        free(send_data);
    }).detach();
    
    return !lpOverlapped ? 0 : 997;
}

#define WSASendTo(...) WSASendTo_fake_lag(__VA_ARGS__)

#endif

#endif