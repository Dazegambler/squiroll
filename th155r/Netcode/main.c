#include <winsock2.h>
#include <windows.h>
#include <winuser.h>
#include <stdint.h>
#include <stdio.h>
#include <assert.h>
#include <stddef.h>

typedef struct{
    void *addr;
    unsigned char data[];
}Alloc;


void*(*actual_malloc)(size_t size) = malloc;
void(*actual_free)(void* ptr) = free;

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

void* my_malloc(size_t size) {
    Alloc* real_alloc = (Alloc*)malloc(sizeof(Alloc) + size);
    real_alloc->addr = &real_alloc->data;
    return &real_alloc->data;
}

void my_free(void* ptr){
    if (ptr) {
        Alloc* real_alloc = (Alloc*)(uintptr_t)ptr - offsetof(Alloc, data);
        free(real_alloc);
    }
}

void Cleanup(){
    hotpatch((void*)my_malloc,(void*)actual_malloc);
    hotpatch((void*)my_free,(void*)actual_free);
}

//FUNCTION REQUIRED FOR THE LIBRARY
__declspec(dllexport) int __stdcall netcode_init(int32_t param) {
    yes_tampering();

    hotpatch((void*)actual_malloc,(void*)my_malloc);
    hotpatch((void*)actual_free,(void*)my_free);

    return 0;
}

BOOL WINAPI DllMain(HINSTANCE hinst, DWORD dwReason, LPVOID reserved) {
	if (dwReason == DLL_PROCESS_DETACH) {
		Cleanup();
	}
	return TRUE;
}
