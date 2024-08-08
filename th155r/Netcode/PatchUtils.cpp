#include "PatchUtils.h"

void mem_write(LPVOID address, const void* data, size_t size)
{
    DWORD oldProtect;
    if (VirtualProtect(address, size, PAGE_READWRITE, &oldProtect))
    {
        memcpy(address, data, size);
        VirtualProtect(address, size, oldProtect, &oldProtect);
    }
}

void hotpatch_jump(void* target, void* replacement)
{
    uint8_t bytes[6] = { 0xE9, 0, 0, 0, 0, 0xCC };
    *(uint32_t*)&bytes[1] = (uintptr_t)replacement - (uintptr_t)target - 5;
    mem_write(target, bytes, sizeof(bytes));
}

void hotpatch_rel32(void* target, void* replacement)
{
    int32_t raw = (uintptr_t)replacement - (uintptr_t)target - 4;
    mem_write(target, &raw, sizeof(raw));
}

void hotpatch_import(void* addr, void* replacement) {
  mem_write(addr, &replacement, sizeof(replacement));
}