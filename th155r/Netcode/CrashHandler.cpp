#include "CrashHandler.h"

FILE *dump;

void printStackTrace() {
    HANDLE process = GetCurrentProcess();
    
    SymInitialize(process, NULL, TRUE);

    void *stack[64];
    DWORD frames = CaptureStackBackTrace(0, sizeof(stack) / sizeof(stack[0]), stack, NULL);

    SYMBOL_INFO *symbol = (SYMBOL_INFO *)calloc(sizeof(SYMBOL_INFO) + 256 * sizeof(char), 1);
    symbol->MaxNameLen = 255;
    symbol->SizeOfStruct = sizeof(SYMBOL_INFO);

    log_fprintf(dump,"Backtrace:\n");
    for (DWORD i = 0; i < frames; i++) {
        SymFromAddr(process, (DWORD64)(stack[i]), 0, symbol);
        log_fprintf(dump,"%02ld: %s - 0x%llX\n", i, symbol->Name, symbol->Address);
    }

    free(symbol);
    SymCleanup(process);
}

void signalHandler(int signum) {
    dump = fopen("crash_dump.dump","a");
    log_fprintf(dump,"Crash Detected\n");

    printStackTrace();
    log_fprintf(dump,"End of stacktrace\n");
    fclose(dump);
    exit(signum);
}