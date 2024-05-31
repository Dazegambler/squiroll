#include <winsock2.h>
#include <windows.h>
#include <stdint.h>

void mem_write(LPVOID address, const BYTE* data, size_t size) {
    DWORD oldProtect;
    if (VirtualProtect(address, size, PAGE_READWRITE, &oldProtect)) {
        memcpy(address, data, size);
        VirtualProtect(address, size, oldProtect, &oldProtect);
    }
}

uintptr_t base_address() {
    return (uintptr_t)GetModuleHandleA(NULL);
}

void yes_tampering(){
    BYTE data[] = {0xC3};
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

    //Rx12E820,Rx130630,Rx132AF0
	//0xC3
    yes_tampering();



    //0x00570E28,0x00570E88,0x00570E98
    BYTE data[] = {0xC3};
    //mem_write((LPVOID)0x00572bc5,data,sizeof(data));
    return 0;
}
