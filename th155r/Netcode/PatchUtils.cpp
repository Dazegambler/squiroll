
#include <string.h>
#include <windows.h>
#include "PatchUtils.h"
#include "log.h"

void mem_write(void* address, const void* data, size_t size) {
    DWORD oldProtect;
    if (VirtualProtect(address, size, PAGE_READWRITE, &oldProtect)) {
        memcpy(address, data, size);
        VirtualProtect(address, size, oldProtect, &oldProtect);
    }
}

int mem_prot_overwrite(void* address, size_t size, DWORD prot) {
    int r = VirtualProtect(address, size, prot, &prot);
    if (r != 0){
        log_printf("Failed to overwrite protection of %x error:%d\n", address, GetLastError());
    }
    return r;
}

void hotpatch_call(void* target, void* replacement) {
    uint8_t bytes[] = { 0xE8, 0, 0, 0, 0 };
    *(uint32_t*)&bytes[1] = (uintptr_t)replacement - (uintptr_t)target - 5;
    mem_write(target, bytes);
}

void hotpatch_icall(void* target, void* replacement) {
    uint8_t bytes[] = { 0xE8, 0, 0, 0, 0, 0x90 };
    *(uint32_t*)&bytes[1] = (uintptr_t)replacement - (uintptr_t)target - 5;
    mem_write(target, bytes);
}

void hotpatch_jump(void* target, void* replacement) {
    uint8_t bytes[] = { 0xE9, 0, 0, 0, 0, 0xCC };
    *(uint32_t*)&bytes[1] = (uintptr_t)replacement - (uintptr_t)target - 5;
    mem_write(target, bytes);
}

void hotpatch_ret(void* target, uint16_t pop_bytes) {
    uint8_t bytes[] = { 0xC2, 0, 0, 0xCC };
    *(uint16_t*)&bytes[1] = pop_bytes;
    mem_write(target, bytes);
}

void hotpatch_rel32(void* target, void* replacement) {
    mem_write(target, (uintptr_t)replacement - (uintptr_t)target - 4);
}

void hotpatch_import(void* addr, void* replacement) {
    mem_write(addr, replacement);
}