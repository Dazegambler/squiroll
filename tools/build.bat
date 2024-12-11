@echo off
clang++ -m32 -std=c++20 -o make_embed_windows.exe make_embed.cpp
IF ERRORLEVEL 1 (
    echo Failed to build make_embed
    exit /b 1
)
clang++ -m32 -std=c++20 -o condense_nut_windows.exe condense_nut.cpp
IF ERRORLEVEL 1 (
    echo Failed to build condense_nut
    exit /b 1
)