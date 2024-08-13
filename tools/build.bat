@echo off
i686-w64-mingw32-g++ -std=c++20 -o make_embed_windows.exe make_embed.cpp
IF ERRORLEVEL 1 (
    echo Failed to build tools
    exit /b 1
)
