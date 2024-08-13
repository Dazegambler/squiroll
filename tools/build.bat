@echo off
i686-w64-mingw32-g++ -std=c++20 -o ToByteData_windows.exe ToByteData.cpp
IF ERRORLEVEL 1 (
    echo Failed to build tools
    exit /b 1
)