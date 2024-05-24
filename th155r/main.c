#include <windows.h>
#include <stdio.h>
#include <tlhelp32.h>
#include <tchar.h>
#include <string.h>

#define TH155 "th155.exe"
#define NETCODE "Netcode.dll"
//#define FUNC "say_hello" // Placeholder

char* GetLastErrorMessage() {
    DWORD error_code = GetLastError();
    if (error_code == 0) {
        char* buffer = (char*)LocalAlloc(LMEM_FIXED, sizeof("No error."));
        if (buffer) {
            strcpy(buffer, "No error.");
        }
        return buffer;
    }

    char* buffer = NULL;
    DWORD message_length = FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        error_code,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPSTR)&buffer,
        0,
        NULL
    );

    if (message_length == 0) {
        buffer = (char*)LocalAlloc(LMEM_FIXED, 64);
        if (buffer) {
            snprintf(buffer, 64, "Unknown error code: %lu", error_code);
        }
    }

    return buffer;
}


BOOL InjectDLL(HANDLE hProcess, const char *dllPath, HMODULE *outhModule)
{
    FILE *log = fopen("th155r.log", "a");
    if (hProcess == 0)
    {
        fprintf(log, "No Process given...(%d)\n", GetLastError());
        fclose(log);
        return FALSE;
    }

    SIZE_T pathLen = strlen(dllPath);
    LPVOID remoteString = (LPVOID)VirtualAllocEx(hProcess, NULL, sizeof(wchar_t)*pathLen+1, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    if (!remoteString)
    {
        fprintf(log, "Could not allocate memory in target process...(%d)\n", GetLastError());
        fclose(log);
        return FALSE;
    }

    if (!WriteProcessMemory(hProcess, remoteString,dllPath,sizeof(wchar_t)*pathLen, NULL))
    {
        fprintf(log, "Could not write to process memory...(%d)\n", GetLastError());
        VirtualFreeEx(hProcess, remoteString, 0, MEM_RELEASE);
        fclose(log);
        return FALSE;
    }

    HMODULE hKernel32 = GetModuleHandleA("Kernel32.dll");
    if (!hKernel32)
    {
        fprintf(log, "Failed to get Kernel32.dll...(%d)\n", GetLastError());
        VirtualFreeEx(hProcess, remoteString, 0, MEM_RELEASE);
        fclose(log);
        return FALSE;
    }

    LPVOID lb = GetProcAddress(hKernel32, "LoadLibraryA");
    if (!lb)
    {
        fprintf(log, "Failed to get LoadLibrary...(%d)\n", GetLastError());
        VirtualFreeEx(hProcess, remoteString, 0, MEM_RELEASE);
        fclose(log);
        return FALSE;
    }

    // NOT_CAUSES:
    // hprocess
    // injected string
    // loadlibrary address(?)
    
    fprintf(log, "Params: %p | %p...(%d)\n", hProcess, lb);
    HANDLE hThread = CreateRemoteThread(hProcess, NULL, 0, (LPTHREAD_START_ROUTINE)lb, remoteString, 0, NULL);
    fprintf(log, "Thread: %p\n", hThread);
    if (!hThread)
    {
        fprintf(log, "Could not create remote thread...(%d)\n", GetLastError());
        VirtualFreeEx(hProcess, remoteString, 0, MEM_RELEASE);
        fclose(log);
        return FALSE;
    }

    WaitForSingleObject(hThread, INFINITE);

    DWORD exitCode;
    if (!GetExitCodeThread(hThread, &exitCode))
    {
        fprintf(log, "Failed getting thread exit code...(%d)\n", GetLastError());
        CloseHandle(hThread);
        VirtualFreeEx(hProcess, remoteString, 0, MEM_RELEASE);
        fclose(log);
        return FALSE;
    }

    *outhModule = (HMODULE)&exitCode;

    VirtualFreeEx(hProcess, remoteString, 0, MEM_RELEASE);
    CloseHandle(hThread);
    fclose(log);
    return TRUE;
}

/*NOT NEEDED ANYMORE(?)*/void *get_remote_function_address(HANDLE hProcess, HMODULE hModule /*Injected Library*/, const char *functionName)
{
    FILE *log = fopen("th155r.log", "a");
    void *functionAddress = GetProcAddress(hModule, functionName);
    if (!functionAddress)
    {
        fprintf(log, "Could not get function address locally...(%d)\n", log);
        fclose(log);
        return NULL;
    }
    fclose(log);
    return functionAddress;
}

/*NOT NEEDED ANYMORE(?)*/BOOL patch_memory_with_jmp(HANDLE hProcess, void *targetAddress, void *jmpAddress)
{
    FILE *log = fopen("th155r.log", "a");
    BYTE jmpInstruction[5] = {0xE9, 0, 0, 0, 0}; // jmp instruction
    DWORD offset = (DWORD)((BYTE *)jmpAddress - (BYTE *)targetAddress - 5);

    memcpy(&jmpInstruction[1], &offset, 4);

    if (!WriteProcessMemory(hProcess, targetAddress, jmpInstruction, sizeof(jmpInstruction), NULL))
    {
        fprintf(log, "Could not write JMP instruction...(%d)\n", GetLastError());
        fclose(log);
        return FALSE;
    }
    fclose(log);
    return TRUE;
}

BOOL execute_program(const char *program_path)
{
    FILE *log = fopen("th155r.log", "a");
    STARTUPINFO si;
    PROCESS_INFORMATION pi;

    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    if (!CreateProcess(NULL, (LPSTR)program_path, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi))
    {
        fprintf(log, "CreateProcess failed...(%d)\n", log);
        return FALSE;
    }

    fclose(log);
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return TRUE;
}

HANDLE findProcess(const char *processName)
{
    FILE *log = fopen("th155r.log", "a");
    HANDLE hProcessSnap;
    HANDLE hProcess;

    hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hProcessSnap == INVALID_HANDLE_VALUE)
    {
        fprintf(log, "Could not create snapshot...(%d)\n", GetLastError());
        fclose(log);
        return NULL;
    }

    PROCESSENTRY32 pe32;
    pe32.dwSize = sizeof(PROCESSENTRY32);

    if (!Process32First(hProcessSnap, &pe32))
    {
        fprintf(log, "Failed to get first process...(%d)\n", log);
        fclose(log);
        CloseHandle(hProcessSnap);
        return FALSE;
    }

    do
    {
        if (!_tcsicmp(pe32.szExeFile, processName))
        {
            fprintf(log, "th155 was found in memory\n", log);
            fprintf(log, "path:%s\n", pe32.szExeFile);
            hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pe32.th32ProcessID);
            if (hProcess != NULL)
            {
                fprintf(log, "Found you!\n");
                fclose(log);
                return hProcess;
            }
            else
            {
                fprintf(log, "Failed to open process...(%d)\n", log);
                fclose(log);
                return NULL;
            }
        }
    } while (Process32Next(hProcessSnap, &pe32));
    fprintf(log, "th155 has not been loaded into memory, aborting...(%d)\n", log);
    fclose(log);
    return NULL;
}

int main()
{
    FILE *log = fopen("th155r.log", "a");
    fprintf(log, "Starting patcher\n");
    /*NOT NEEDED ANYMORE(?)*///LPVOID targetAddress = (LPVOID)0x12345678; // Placeholder address
    if (!execute_program(TH155))
    {
        fclose(log);
        return 1;
    }
    HANDLE hProcess = findProcess(TH155);
    if (!hProcess)
    {
        fprintf(log, "Failed to start process...(%d)\n", GetLastError());
        fclose(log);
        return 1;
    }
    HMODULE hModule;
    if (!InjectDLL(hProcess, NETCODE, &hModule))
    {
        fprintf(log, "Failed to inject dll...(%d)\n", GetLastError());
        CloseHandle(hProcess);
        fclose(log);
        return 1;
    }

    //The library itself can do the function injections
    // LPVOID jmpAddress = get_remote_function_address(hProcess, hModule, FUNC);
    // if (!jmpAddress)
    // {
    //     fprintf(log, "Failed to get remote function address...(%d)\n", GetLastError());
    //     fclose(log);
    //     CloseHandle(hProcess);
    //     return 1;
    // }

    // if (!patch_memory_with_jmp(hProcess, targetAddress, jmpAddress))
    // {
    //     fprintf(log, "Failed to patch memory...(%d)\n", GetLastError());
    //     CloseHandle(hProcess);
    //     fclose(log);
    //     return 1;
    // }
    //fprintf(log, "it actually worked");
    fclose(log);
    CloseHandle(hProcess);
    return 0;
}

