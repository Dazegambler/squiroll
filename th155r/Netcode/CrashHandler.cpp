#include "CrashHandler.h"

FILE *log;

void printStackTrace() {
    HANDLE process = GetCurrentProcess();
    
    // Initialize symbol handler for current process
    SymInitialize(process, NULL, TRUE);

    // Capture stack backtrace
    void *stack[64];
    DWORD frames = CaptureStackBackTrace(0, sizeof(stack) / sizeof(stack[0]), stack, NULL);

    // Allocate memory for SYMBOL_INFO
    SYMBOL_INFO *symbol = (SYMBOL_INFO *)calloc(sizeof(SYMBOL_INFO) + 256 * sizeof(char), 1);
    symbol->MaxNameLen = 255;
    symbol->SizeOfStruct = sizeof(SYMBOL_INFO);

    fputs("Backtrace:\n",log);
    for (DWORD i = 0; i < frames; i++) {
        SymFromAddr(process, (DWORD64)(stack[i]), 0, symbol);
        log_fprintf(log,"%02ld: %s - 0x%llX\n", i, symbol->Name, symbol->Address);
    }

    // Cleanup
    free(symbol);
    SymCleanup(process);
}

// Function to handle signals and print information to stdout
void signalHandler(int signum) {
    log = fopen("crash_dump.log","a");
    // Write signal information to stdout
    fputs("Crash Detected",log);

    // Print stack trace
    printStackTrace();
    log_fprintf("End of stacktrace");

    // Exit the program
    exit(signum);
}