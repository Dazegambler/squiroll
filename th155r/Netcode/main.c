#include <winsock2.h>
#include <windows.h>
#include <winuser.h>
#include <stdint.h>
#include <stdio.h>
#include <assert.h>

uintptr_t base_address() {
    return (uintptr_t)GetModuleHandleA(NULL);
}

void mem_write(LPVOID address, const BYTE* data, size_t size) {
    DWORD oldProtect;
    if (VirtualProtect(address, size, PAGE_READWRITE, &oldProtect)) {
        memcpy(address, data, size);
        VirtualProtect(address, size, oldProtect, &oldProtect);
    }
}

void hotpatch(void* target, void* replacement) {
    assert(((uintptr_t)target & 0x07) == 0);
    void* page = (void*)((uintptr_t)target & ~0xfff);
    DWORD oldProtect;
    if (VirtualProtect(page, 4096, PAGE_EXECUTE_READWRITE, &oldProtect)) {
        int32_t rel = (int32_t)((char*)replacement - (char*)target - 5);
        union {
            uint8_t bytes[8];
            uint64_t value;
        } instruction = { {0xe9, rel >> 0, rel >> 8, rel >> 16, rel >> 24} };
        *(uint64_t*)target = instruction.value;
        VirtualProtect(page, 4096, oldProtect, &oldProtect);
    }

}

void yes_tampering(){
    static const BYTE data[] = {0xC3};
    uintptr_t base = base_address();
    uintptr_t addrA = 0x0012E820,addrB = 0x00130630,addrC = 0x00132AF0;
    addrA +=base;
    addrB +=base;
    addrC +=base; 
    mem_write((LPVOID)addrA,data,sizeof(data)); 
    mem_write((LPVOID)addrB,data,sizeof(data)); 
    mem_write((LPVOID)addrC,data,sizeof(data)); 

}

//FUNCTION REQUIRED FOR THE LIBRARY
__declspec(dllexport) int __stdcall netcode_init(int32_t param) {
    yes_tampering();
    return 0;
}
