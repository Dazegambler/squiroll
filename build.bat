@echo off

set MAKE_EMBED_PATH=tools\make_embed_windows.exe
set CONDENSE_NUT_PATH=tools\condense_nut_windows.exe
set REPLACEMENT_FILES_DIR=replacement_files
set REPLACEMENT_COMPRESSED_DIR=compressed_nuts\replacement_files
set REPLACEMENT_DESTINATION_DIR=th155r\Netcode\replacement_files

set NEW_FILES_DIR=new_files
set NEW_COMPRESSED_DIR=compressed_nuts\new_files
set NEW_DESTINATION_DIR=th155r\Netcode\new_files

mkdir "%REPLACEMENT_DESTINATION_DIR%"
mkdir "%NEW_DESTINATION_DIR%"

for %%F in (%REPLACEMENT_FILES_DIR%\*) do (
    %CONDENSE_NUT_PATH% %%F %REPLACEMENT_COMPRESSED_DIR%\%%~nxF
)

for %%F in (%REPLACEMENT_COMPRESSED_DIR%\*) do (
    %MAKE_EMBED_PATH% %%F %REPLACEMENT_DESTINATION_DIR%\%%~nxF.h
)

for %%F in (%NEW_FILES_DIR%\*) do (
    %CONDENSE_NUT_PATH% %%F %NEW_COMPRESSED_DIR%\%%~nxF
)

for %%F in (%NEW_COMPRESSED_DIR%\*) do (
    %MAKE_EMBED_PATH% %%F %NEW_DESTINATION_DIR%\%%~nxF.h
)

set DEFINES=-D_CRT_SECURE_NO_WARNINGS -D_WINSOCK_DEPRECATED_NO_WARNINGS -DNOMINMAX -D_WINSOCKAPI_ -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE -D_CRT_DECLARE_NONSTDC_NAMES
set WARNINGS=-Wno-cpp -Wno-narrowing
set FLAGS=/Gs- /GS- /clang:-fwrapv /Zc:threadSafeInit- -mfpmath=sse -msse2 -msse -mstack-probe-size=1024 -flto=full -mstack-alignment=4 -mno-stackrealign /clang:-fomit-frame-pointer

clang-cl -m32 -fuse-ld=lld /EHsc %WARNINGS% %DEFINES% %FLAGS% /Ith155r/shared th155r/main.cpp -O2 /link /OUT:th155r.exe
clang-cl -m32 -fuse-ld=lld /EHsc %WARNINGS% %DEFINES% %FLAGS% /Ith155r/shared /Ith155r/Netcode/include th155r/Netcode/*.cpp /std:c++20 -static -O2 /link /DLL user32.lib WS2_32.lib dbghelp.lib winmm.lib -exclude-all-symbols -kill-at /DEF:Netcode.def /OUT:Netcode.dll
