@echo off
REM Build the executable
i686-w64-mingw32-gcc -o th155r.exe th155r/main.c
IF ERRORLEVEL 1 (
    echo Failed to build th155r.exe
    exit /b 1
)

REM Build the DLL
i686-w64-mingw32-gcc -Wl,--exclude-all-symbols,--kill-at -shared -I th155r/Netcode/include -o  Netcode.dll th155r/Netcode/*.cpp -std=c++20 -lstdc++ -lws2_32 -Wno-narrowing 
IF ERRORLEVEL 1 (
    echo Failed to build Netcode.dll
    exit /b 1
)

echo Build completed successfully.
