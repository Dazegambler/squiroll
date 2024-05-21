#include <windows.h>
#include <stdio.h>
#include <string.h>

#define TH155 "th155.exe"
#define NETCODE "Netcode.dll"
#define FUNC "say_hello" //Placeholder

BOOL InjectDLL(HANDLE hProcess, const char* dllPath, HMODULE* outhModule) {
    FILE* log = fopen("th155r.log","a");
    if(hProcess == 0){
        fprintf(log,"No Process given...(%d)\n",GetLastError());
        fclose(log);
        return FALSE;
    }

    HMODULE hKernel32 = GetModuleHandle("Kernel32");
    if(!hKernel32){
        fprintf(log,"Failed to get Kernel32.dll...(%d)\n",GetLastError());
        fclose(log);
        return FALSE;
    }

    LPVOID lb = GetProcAddress(hKernel32,"LoadLibraryA");
    if(!lb){
        fprintf(log,"Failed to get LoadLibraryA...(%d)\n",GetLastError());
        fclose(log);
        return FALSE;
    }

    LPVOID remoteString = (LPVOID)VirtualAllocEx(hProcess,0, strlen(dllPath)+1, (MEM_RESERVE | MEM_COMMIT), PAGE_READWRITE);
    if (!remoteString){
        fprintf(log,"Could not allocate memory in target process...(%d)\n",GetLastError());
        fclose(log);
        return FALSE;
    }

    if (!WriteProcessMemory(hProcess, (LPVOID)remoteString,dllPath, strlen(dllPath), NULL)){
        fprintf(log,"Could not write to process memory...(%d)\n",GetLastError());
        fclose(log);
        return FALSE;
    }

    //THIS AINT WORKING FOR NO REASON...Could not create remote thread...(87)
    fprintf(log,"Params:%p|%p|%p\n",hProcess,lb,remoteString);
    HANDLE hThread = CreateRemoteThread(hProcess,NULL,0,lb,remoteString,0, NULL);
    fprintf(log,"Thread:%p\n",hThread);
    if (!hThread){
        fprintf(log,"Could not create remote thread...(%d)\n",GetLastError());
        fclose(log);
        return FALSE;
    }

    WaitForSingleObject(hThread, INFINITE);

    DWORD exitCode;
    if (!GetExitCodeThread(hThread, & exitCode)){
        fprintf(log,"Failed getting thread exit code...(%d)\n",GetLastError());
        CloseHandle(hThread);
        fclose(log);
        return FALSE;
    }

    *outhModule = (HMODULE) &exitCode;


    VirtualFreeEx(hProcess, remoteString, 0, MEM_RELEASE);
    CloseHandle(hThread);
    fclose(log);
    return TRUE;
}

void* get_remote_function_address(HANDLE hProcess, HMODULE hModule/*Injected Library*/, const char* functionName){
    FILE* log = fopen("th155r.log","a");
    void* functionAddress = GetProcAddress(hModule, functionName);
    if (!functionAddress) {
        fprintf(log,"Could not get function address locally...(%d)\n",GetLastError());
        fclose(log);
        return NULL;
    }
    fclose(log);
    return functionAddress;
}

BOOL patch_memory_with_jmp(HANDLE hProcess, void* targetAddress, void* jmpAddress){
    FILE* log = fopen("th155r.log","a");
    BYTE jmpInstruction[5] = { 0xE9, 0, 0, 0, 0 };
    DWORD offset = (DWORD)((BYTE*)jmpAddress - (BYTE*)targetAddress - 5);

    memcpy(&jmpInstruction[1], &offset, 4);

    if (!WriteProcessMemory(hProcess, targetAddress, jmpInstruction, sizeof(jmpInstruction), NULL)) {
        fprintf(log,"Could not write JMP instruction...(%d)\n",GetLastError());
        fclose(log);
        return FALSE;
    }
    fclose(log);
    return TRUE;
}

HANDLE execute_program(const char* program_path){
    FILE* log = fopen("th155r.log","a");
    STARTUPINFO si;
    PROCESS_INFORMATION pi;

    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    if(!CreateProcess(NULL,(LPSTR)program_path,NULL,NULL,FALSE,0,NULL,NULL,&si,&pi)){
        fprintf(log,"CreateProcess failed (%d)...(%d)\n",GetLastError());
        fclose(log);
        return NULL;
    }

    HANDLE hProcess = OpenProcess(
        PROCESS_ALL_ACCESS,
        FALSE,
        pi.dwProcessId
    );

    fclose(log);
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return hProcess;
}

int main() {
    FILE* log = fopen("th155r.log","a");
    LPVOID targetAddress = (LPVOID)0x12345678;// Placeholder address
    HANDLE hProcess = execute_program(TH155);
    if (!hProcess){
        fprintf(log,"Failed to start process...(%d)\n",GetLastError());
        fclose(log);
        return 1;
    }
    HMODULE* hModule;
    if(!InjectDLL(hProcess,NETCODE,hModule)){
        fprintf(log,"Failed to inject dll...(%d)\n",GetLastError());
        return 1;
    };

    LPVOID jmpAddress = get_remote_function_address(hProcess,*hModule,FUNC);   

    patch_memory_with_jmp(hProcess, targetAddress, jmpAddress);
    fclose(log);
    CloseHandle(hProcess);
    return 0;
}
