#include <winsock2.h>
#include <windows.h>
#include <winuser.h>
#include <stdint.h>
#include <stdio.h>

typedef void (*func_ptr)(void);

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


void inject_func(void* addr/*RVA*/, func_ptr local_func, size_t original_size) {
    uintptr_t local_func_address = (uintptr_t)local_func;
    uintptr_t addr_address = (uintptr_t)addr+base_address();
    int32_t offset = (int32_t)(local_func_address - addr_address - 5);

    uint8_t jump_instruction[5] = { 0xE9 };
    memcpy(&jump_instruction[1], &offset, 4);

    unsigned char nop[] = {0x90};
    mem_write(addr,nop, original_size);
    mem_write(addr,jump_instruction,sizeof(jump_instruction));
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

void update_window_title(){
    // Rx4DAD30
}

void testInjection(){
    FILE *fp;
    fp = fopen("TEST.txt","w");
    fprintf(fp,"Successful test");
    fclose(fp);
    asm (
        "call 0x0056fde0\n\t"
    );
}

//FUNCTION REQUIRED FOR THE LIBRARY
__declspec(dllexport) int __stdcall netcode_init(int32_t param) {
    yes_tampering();

    uintptr_t addr = 0x00170e98; 
    inject_func((LPVOID)addr,testInjection,5);
    return 0;
}
