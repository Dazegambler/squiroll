#pragma once

#ifndef SHARED_HEADER_H
#define SHARED_HEADER_H 1

#include <stdio.h>
#include <windows.h>

enum LogType {
	NO_LOGGING = 0,
	LOG_TO_SEPARATE_CONSOLES = 1,
	LOG_TO_PARENT_CONSOLE = 2
};

static void enable_debug_console(bool inherit_console) {
    if (inherit_console) {
        AttachConsole(ATTACH_PARENT_PROCESS);
    } else {
        AllocConsole();
    }
    (void)freopen("CONIN$", "r", stdin);
    (void)freopen("CONOUT$", "w+b", stdout);
    setvbuf(stdout, NULL, _IONBF, 0);
    (void)freopen("CONOUT$", "w", stderr);
    SetConsoleTitleW(L"th155r debug");
}

struct InitFuncData {
	LogType log_type;
};

#endif