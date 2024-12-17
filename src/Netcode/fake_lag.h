#pragma once

#ifndef FAKE_LAG_H
#define FAKE_LAG_H 1

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <winsock2.h>
#include <windows.h>
#include <time.h>

#include "util.h"

#define FAKE_SEND_LAG_AMOUNT 0          // Base lag miliseconds
#define FAKE_SEND_JITTER_AMOUNT 0       // miliseconds
#define FAKE_PACKET_LOSS_PERCENTAGE 0   // 0-100
#define FAKE_SPIKE_PERCENTAGE 0        // 0-100
#define FAKE_SPIKE_MULTIPLIER 5

#if FAKE_SEND_LAG_AMOUNT > 0 || FAKE_SEND_JITTER_AMOUNT > 0 || FAKE_PACKET_LOSS_PERCENTAGE > 0 || FAKE_SPIKE_PERCENTAGE > 0

static inline DWORD idc_about_sent_bytes;
static int WSAAPI WSASendTo_fake_lag(SOCKET s, LPWSABUF lpBuffers, DWORD dwBufferCount, LPDWORD lpNumberOfBytesSent, DWORD dwFlags, const sockaddr* lpTo, int iTolen, LPWSAOVERLAPPED lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine) {
    size_t data_size = 0;
    for (size_t i = 0; i < dwBufferCount; ++i) {
        data_size += lpBuffers[i].len;
    }
    if (lpNumberOfBytesSent) {
        *lpNumberOfBytesSent = data_size;
        lpNumberOfBytesSent = &idc_about_sent_bytes;
    }
    size_t wsabuf_size = sizeof(WSABUF) * dwBufferCount;
    
    struct MinGWIsStupidWithThreads {
        SOCKET s;
        DWORD dwBufferCount;
        LPDWORD lpNumberOfBytesSent;
        DWORD dwFlags;
        const sockaddr* lpTo;
        int iTolen;
        LPWSAOVERLAPPED lpOverlapped;
        LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine;
        unsigned char data[];
    };
    
    MinGWIsStupidWithThreads* args = (MinGWIsStupidWithThreads*)malloc(sizeof(MinGWIsStupidWithThreads) + wsabuf_size + iTolen + data_size);
    
    uint8_t* send_data = args->data;
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
    
    args->s = s;
    args->dwBufferCount = dwBufferCount;
    args->lpNumberOfBytesSent = lpNumberOfBytesSent;
    args->dwFlags = dwFlags;
    args->lpTo = lpTo;
    args->iTolen = iTolen;
    args->lpOverlapped = lpOverlapped;
    args->lpCompletionRoutine = lpCompletionRoutine;

    CreateThread(NULL, 0, [](void* thread_args) lambda_cc(stdcall) -> DWORD {
#if FAKE_PACKET_LOSS_PERCENTAGE > 0 || FAKE_SEND_JITTER_AMOUNT > 0 || FAKE_SPIKE_PERCENTAGE > 0
        srand((unsigned int)time(NULL));
#endif
        
        MinGWIsStupidWithThreads* args = (MinGWIsStupidWithThreads*)thread_args;

#if FAKE_PACKET_LOSS_PERCENTAGE > 0
        if (!random_percentage(FAKE_PACKET_LOSS_PERCENTAGE))
#endif
        {

#if FAKE_SEND_LAG_AMOUNT > 0 || FAKE_SEND_JITTER_AMOUNT > 0 || FAKE_SPIKE_PERCENTAGE > 0

#if FAKE_SEND_LAG_AMOUNT > 0
            size_t lag_ms = FAKE_SEND_LAG_AMOUNT;
#else
            size_t lag_ms = 0;
#endif

#if FAKE_SEND_JITTER_AMOUNT > 0
            int jitter = (int)(get_random(FAKE_SEND_JITTER_AMOUNT) - FAKE_SEND_JITTER_AMOUNT) / 2;
#if FAKE_SEND_JITTER_AMOUNT / 2 > FAKE_SEND_LAG_AMOUNT
            if (jitter < 0) {
                lag_ms = saturate_sub<size_t>(lag_ms, -jitter);
            }
            else
#endif
            {
                lag_ms += jitter;
            }
#endif

#if FAKE_SPIKE_PERCENTAGE > 0
            if (random_percentage(FAKE_SPIKE_PERCENTAGE)) {
                lag_ms *= FAKE_SPIKE_MULTIPLIER;
            }
#endif
            Sleep(lag_ms);
#endif
        
            (WSASendTo)(args->s, (LPWSABUF)args->data, args->dwBufferCount, args->lpNumberOfBytesSent, args->dwFlags, args->lpTo, args->iTolen, args->lpOverlapped, args->lpCompletionRoutine);
        }
        free(thread_args);
        return 0;
    }, (void*)args, 0, NULL);
    
    return !lpOverlapped ? 0 : 997;
}

#define WSASendTo(...) WSASendTo_fake_lag(__VA_ARGS__)

#endif

#endif
