//Rx170E00
void __cdecl
fcn00570e00(LPDWORD lpNumberOfBytesRecvd, 
            LPWSABUF lpBuffers, 
            DWORD dwBufferCount, 
            sockaddr *lpFrom, 
            LPDWORD lpFlags,
            LPINT lpFromlen, 
            int32_t lpOverlapped)
{
    DWORD DVar1;
    int32_t arg_4h;
    int32_t *piVar2;
    int32_t iVar3;
    int32_t arg_8h;
    int32_t in_ECX;
    
    arg_4h = lpOverlapped;
    piVar2 = (int32_t *)(*(int32_t *)(in_ECX + 4) + 0x18);
    LOCK();
    *piVar2 = *piVar2 + 1;
    UNLOCK();
    DVar1 = *lpNumberOfBytesRecvd;
    //If received packets count = -1,Nullpointer handling(?);
    if (DVar1 == 0xffffffff) {
        fcn.0056fe50(lpOverlapped, 0x2719, (LPDWORD)0x0);
        return;
    }
    lpNumberOfBytesRecvd = (LPDWORD)0x0;//NULLs byte count
    iVar3 = (*WS2_32.dll_WSARecvFrom)
                      (DVar1, lpBuffers, dwBufferCount, &lpNumberOfBytesRecvd, &lpFlags, lpFrom, lpFromlen, lpOverlapped
                      );
    arg_8h = (*WS2_32.dll_WSAGetLastError)();
    if (arg_8h == 0x4d2) {
        arg_8h = 0x274d;
    }
    if ((iVar3 != 0) && (arg_8h != 0x3e5)) {
        fcn.0056fe50(arg_4h, arg_8h, lpNumberOfBytesRecvd);
        return;
    }
    fcn.0056fde0(arg_4h);
    return;
}

