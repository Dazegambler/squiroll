#include <winsock2.h>
#include <windows.h>
#include <stdint.h>

void mem_write(LPVOID address, const BYTE* data, size_t size) {
    DWORD oldProtect;
    if (VirtualProtect(address, size, PAGE_EXECUTE_READWRITE, &oldProtect)) {
        memcpy(address, data, size);
        VirtualProtect(address, size, oldProtect, &oldProtect);
    }
}

//FUNCTION REQUIRED FOR THE LIBRARY
__declspec(dllexport) int __stdcall netcode_init(int32_t param) {
    BYTE data[] = {0xC3};
    //mem_write((LPVOID)0x00572bc5,data,sizeof(data));
    return 0;
}
