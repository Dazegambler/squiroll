@echo off

set TOOLS_PATH=.\tools\make_embed_windows.exe
set REPLACEMENT_FILES_DIR=replacement_files
set REPLACEMENT_DESTINATION_DIR=th155r\Netcode\embedded_h\replacement_files

set NEW_FILES_DIR=new_files
set NEW_DESTINATION_DIR=th155r\Netcode\embedded_h\new_files

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

clang++ -m32 -std=c++20 %WARNINGS% %DEFINES% /Ith155r/shared th155r/main.cpp -O2 /link $LIBPATHS /OUT:th155r.exe
clang++ -m32 -std=c++20 %WARNINGS% %DEFINES% /Ith155r/shared /Ith155r/Netcode/embedded_h /Ith155r/Netcode/include th155r/Netcode/*.cpp /std:c++20 -static -O2 /link /DLL $LIBPATHS user32.lib WS2_32.lib dbghelp.lib -exclude-all-symbols -kill-at /DEF:Netcode.def /OUT:Netcode.dll
