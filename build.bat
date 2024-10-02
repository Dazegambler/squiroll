@echo off
clang++ -std=c++20 -o make_embed_windows.exe make_embed.cpp
IF ERRORLEVEL 1 (
    echo Failed to build tools
    exit /b 1
)

set TOOLS_PATH=.\tools\make_embed_windows.exe
set REPLACEMENT_FILES_DIR=replacement_files
set REPLACEMENT_DESTINATION_DIR=th155r\Netcode\replacement_files


set NEW_FILES_DIR=new_files
set NEW_DESTINATION_DIR=th155r\Netcode\new_files

mkdir "%REPLACEMENT_DESTINATION_DIR%"
mkdir "%NEW_DESTINATION_DIR%"

for %%F in (%REPLACEMENT_FILES_DIR%\*) do (
    set FILENAME=%%~nxF
    set DEST_FILE=%REPLACEMENT_DESTINATION_DIR%\%FILENAME%.h
    %TOOLS_PATH% %%F %DEST_FILE%
)

for %%F in (%NEW_FILES_DIR%\*) do (
    set FILENAME=%%~nxF
    set DEST_FILE=%NEW_DESTINATION_DIR%\%FILENAME%.h
    %TOOLS_PATH% %%F %DEST_FILE%
)

set DEFINES=-D_CRT_SECURE_NO_WARNINGS -D_WINSOCK_DEPRECATED_NO_WARNINGS -DNOMINMAX -D_WINSOCKAPI_
set WARNINGS=-Wno-cpp -Wno-narrowing

clang++ -m32 -std=c++20 -o th155r.exe %WARNINGS% %DEFINES% /Ith155r\shared th155r\main.cpp -O2
clang++ -m32 -std=c++20 -shared -o Netcode.dll %WARNINGS% %DEFINES% /Ith155r\shared /Ith155r\Netcode\include th155r\Netcode\*.cpp -static -O2 -luser32 -lWS2_32 -ldbghelp -Wl,--kill-at -Wl,--exclude-all-symbols -Wl,--output-def,Netcode.def
