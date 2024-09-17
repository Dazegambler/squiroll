#include <windows.h>
#include <tlhelp32.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>

#ifndef NDEBUG
#define ENABLE_DEBUG_LOGGING 1
#else
#define ENABLE_DEBUG_LOGGING 0
#endif

//Code provided by zero318
static uint8_t inject_func[] = {
    0x53,             //   PUSH EBX
    0x6A, 0x00,       //   PUSH 0
    0x6A, 0x00,       //   PUSH 0
    0x68, 0, 0, 0, 0, //   PUSH dll_name
    0xE8, 0, 0, 0, 0, //   CALL LoadLibraryExW
    0x85, 0xC0,       //   TEST EAX, EAX
    0x74, 0x30,       //   JZ load_library_fail
    0x89, 0xC3,       //   MOV EBX, EAX
    0x68, 0, 0, 0, 0, //   PUSH init_func_name
    0x50,             //   PUSH EAX
    0xE8, 0, 0, 0, 0, //   CALL GetProcAddress
    0x85, 0xC0,       //   TEST EAX, EAX
    0x74, 0x32,       //   JZ get_init_func_fail
    0x68, 0, 0, 0, 0, //   PUSH init_func_param
    0xFF, 0xD0,       //   CALL EAX
    0x89, 0xD9,       //   MOV ECX, EBX
    0x89, 0xC3,       //   MOV EBX, EAX
    0x85, 0xC0,       //   TEST EAX, EAX
    0x74, 0x09,       //   JZ exit_thread
    0x83, 0xCB, 0xFF, //   OR EBX, -1
                      // free_library:
    0x51,             //   PUSH ECX
    0xE8, 0, 0, 0, 0, //   CALL FreeLibrary
                      // exit_thread:
    0x53,             //   PUSH EBX
    0xE8, 0, 0, 0, 0, //   CALL ExitThread
    0xCC,             //   INT3
                      // load_library_fail:
    0x31, 0xDB,       //   XOR EBX, EBX
                      //   CMP DWORD PTR FS:[LastErrorValue], STATUS_DLL_INIT_FAILED
    0x64, 0x81, 0x3D, 0x34, 0x00, 0x00, 0x00, 0x42, 0x01, 0x00, 0xC0,
    0x0F, 0x95, 0xC3, //   SETNE BL
    0x43,             //   INC EBX
    0xEB, 0xE6,       //   JMP exit_thread
                      // get_init_func_fail:
    0x89, 0xD9,       //   MOV ECX, EBX
                      //   MOV EBX, 3
    0xBB, 0x03, 0x00, 0x00, 0x00,
    0xEB, 0xD7,       //   JMP free_library
    0xCC
};

const size_t inject_func_length = sizeof(inject_func);
const size_t dll_name = 6;
const size_t load_library = 11;
const size_t init_func_name = 22;
const size_t get_proc_address = 28;
const size_t init_func_param = 37;
const size_t free_library = 56;
const size_t exit_thread = 62;

typedef enum {
    INJECT_INIT_FALSE = -1, // Initialization function did not succeed
    INJECT_SUCCESS = 0,
    INJECT_DLL_FALSE = 1, // DllMain returned FALSE
    INJECT_DLL_ERROR = 2, // LoadLibrary failed
    INJECT_INIT_ERROR = 3, // Initialization function not found
    INJECT_ALLOC_FAIL = 4, // One of the virtual memory functions failed
    INJECT_THREAD_FAIL = 5, // CreateRemoteThread failed
} InjectReturnCode;

static inline const char* get_inject_func_message(InjectReturnCode code) {
    switch (code) {
        case INJECT_INIT_FALSE: return "Initialization function did not succeed.";
        case INJECT_SUCCESS: return "WTF.";
        case INJECT_DLL_FALSE: return "DllMain returned FALSE.";
        case INJECT_DLL_ERROR: return "LoadLibrary failed.";
        case INJECT_INIT_ERROR: return "Initialization function not found.";
        case INJECT_ALLOC_FAIL: return "One of the virtual memory functions failed.";
        case INJECT_THREAD_FAIL: return "CreateRemoteThread failed.";
        default: return "Thread returned garbage exit";
    }
}

static bool is_running_on_wine = false;

InjectReturnCode inject(HANDLE process, const wchar_t* dll_str, const char* init_func, int32_t param) {
    size_t dll_name_bytes = (wcslen(dll_str) + 1) * sizeof(wchar_t);
    size_t init_func_bytes = strlen(init_func) + 1;

    uint8_t* inject_buffer = (uint8_t*)VirtualAllocEx(process, NULL, inject_func_length + dll_name_bytes + init_func_bytes, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!inject_buffer) {
        return INJECT_ALLOC_FAIL;
    }

    // Don't question this part
    *(uint8_t**)&inject_func[dll_name] = &inject_buffer[inject_func_length];
    *(int32_t*)&inject_func[load_library] = (uint8_t*)&LoadLibraryExW - &inject_buffer[load_library + sizeof(int32_t)];
    *(uint8_t**)&inject_func[init_func_name] = &inject_buffer[inject_func_length + dll_name_bytes];
    *(int32_t*)&inject_func[get_proc_address] = (uint8_t*)&GetProcAddress - &inject_buffer[get_proc_address + sizeof(int32_t)];
    *(int32_t*)&inject_func[init_func_param] = param;
    *(int32_t*)&inject_func[free_library] = (uint8_t*)&FreeLibrary - &inject_buffer[free_library + sizeof(int32_t)];
    *(int32_t*)&inject_func[exit_thread] = (uint8_t*)&ExitThread - &inject_buffer[exit_thread + sizeof(int32_t)];

    DWORD exit_code = INJECT_ALLOC_FAIL;
    if (
        WriteProcessMemory(process, inject_buffer, inject_func, inject_func_length, NULL) &&
        WriteProcessMemory(process, inject_buffer + inject_func_length, dll_str, dll_name_bytes, NULL) &&
        WriteProcessMemory(process, inject_buffer + inject_func_length + dll_name_bytes, init_func, init_func_bytes, NULL) &&
        FlushInstructionCache(process, inject_buffer, inject_func_length)
    ) {
        exit_code = INJECT_THREAD_FAIL;
        HANDLE thread = CreateRemoteThread(process, NULL, 0, (LPTHREAD_START_ROUTINE)inject_buffer, 0, 0, NULL);
        if (thread) {
            WaitForSingleObject(thread, INFINITE);
            GetExitCodeThread(thread, &exit_code);
            CloseHandle(thread);
        } else {
            fprintf(stdout,"Thread creation failed\n");
        }
    }

    VirtualFreeEx(process, inject_buffer, 0, MEM_RELEASE);

    return (InjectReturnCode)exit_code;
}

static const uint8_t infinite_loop[] = {
                // inf:
    0xEB, 0xFE, //   JMP inf
};

void bootstrap_program(HANDLE process, HANDLE thread) {
    CONTEXT context = {};
    context.ContextFlags = CONTEXT_INTEGER | CONTEXT_SEGMENTS;
    GetThreadContext(thread, &context);
    
    uintptr_t addr;
    if (!is_running_on_wine) {
        addr = context.Eax;
    } else {
        LDT_ENTRY entry;
        GetThreadSelectorEntry(thread, context.SegFs, &entry);
        addr = entry.BaseLow | entry.HighWord.Bits.BaseMid << 16 | entry.HighWord.Bits.BaseHi << 24;
        ReadProcessMemory(process, (LPCVOID)(addr + 0x30), &addr, sizeof(uintptr_t), NULL);
        ReadProcessMemory(process, (LPCVOID)(addr + 0x8), &addr, sizeof(uintptr_t), NULL);
        DWORD offset;
        ReadProcessMemory(process, (LPCVOID)(addr + 0x3C), &offset, sizeof(DWORD), NULL);
        ReadProcessMemory(process, (LPCVOID)(addr + offset + 0x28), &offset, sizeof(DWORD), NULL);
        addr += offset;
    }
    DWORD protection;
    VirtualProtectEx(process, (LPVOID)addr, sizeof(infinite_loop), PAGE_EXECUTE_READWRITE, &protection);
    uint8_t old_bytes[sizeof(infinite_loop)];
    ReadProcessMemory(process, (LPCVOID)addr, old_bytes, sizeof(old_bytes), NULL);
    WriteProcessMemory(process, (LPVOID)addr, infinite_loop, sizeof(infinite_loop), NULL);
    FlushInstructionCache(process, (LPCVOID)addr, sizeof(infinite_loop));

    do {
        ResumeThread(thread);
        Sleep(10);
        SuspendThread(thread);
        context.ContextFlags = CONTEXT_CONTROL;
        GetThreadContext(thread, &context);
    } while (addr != context.Eip);

    WriteProcessMemory(process, (LPVOID)addr, old_bytes, sizeof(old_bytes), NULL);
    VirtualProtectEx(process, (LPVOID)addr, sizeof(old_bytes), protection, &protection);
    FlushInstructionCache(process, (LPCVOID)addr, sizeof(old_bytes));
}

bool execute_program_inject()
{
    STARTUPINFOW si = { sizeof(STARTUPINFOW) };
    PROCESS_INFORMATION pi = {};
    
    bool ret = false;
    if (CreateProcessW(L"th155.exe", NULL, NULL, NULL, TRUE, CREATE_SUSPENDED, NULL, NULL, &si, &pi)) {
        
        //anti_tamper_disable(pi.hProcess);
        bootstrap_program(pi.hProcess, pi.hThread);

        
		InjectReturnCode inject_result = inject(pi.hProcess, L"Netcode.dll", "netcode_init", 0);
        if (inject_result == INJECT_SUCCESS) {
            ResumeThread(pi.hThread);
            ret = true;
        } else {
            fprintf(stderr,"Code Injection failed...(%X,%lX)\n", inject_result, GetLastError());
            fprintf(stderr,"%s\n", get_inject_func_message(inject_result));
        }
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
    }
    return ret;
}

void Debug(){
    AllocConsole();
    freopen("CONIN$","r",stdin);
    freopen("CONOUT$","w",stdout);
    freopen("CONOUT$","w",stderr);
    SetConsoleTitleW(L"th155r output");
}

int main(int argc, char* argv[])
{    
    //Debug();
    
    if (GetProcAddress(GetModuleHandleW(L"ntdll.dll"), "wine_get_version")) {
        is_running_on_wine = true;
    }
    
    fprintf(stdout,"Starting patcher\n");
    fprintf(stdout,"OS Type: %s\n", !is_running_on_wine ? "Windows" : "Wine");
    if(execute_program_inject()!= false){
        fprintf(stdout,"Patch succesful, you can close this now");
        return 0;
    }
    return 0;
}