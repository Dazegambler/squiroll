@echo off

set MAKE_EMBED_PATH=tools\make_embed_windows.exe
set CONDENSE_NUT_PATH=tools\condense_nut_windows.exe

set EMBEDS_DIR=embed
set EMBEDS_DEST_DIR=src/Netcode/embed

mkdir "%EMBEDS_DIR%"
mkdir "%EMBEDS_DEST_DIR%"

for %%F in (%EMBEDS_DIR%\*) do (
    %MAKE_EMBED_PATH% %%F %EMBEDS_DEST_DIR%\%%~nxF.h
)

rc src/th155r/th155r.rc

set DEFINES=-D_CRT_SECURE_NO_WARNINGS -D_WINSOCK_DEPRECATED_NO_WARNINGS -DNOMINMAX -D_WINSOCKAPI_ -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE -D_CRT_DECLARE_NONSTDC_NAMES
set WARNINGS=-Wno-cpp -Wno-narrowing -Wno-c99-designator
set FLAGS=/Gs- /GS- /clang:-fwrapv /Zc:threadSafeInit- -mfpmath=sse -msse2 -msse -mstack-probe-size=1024 -flto=full -mstack-alignment=4 -mno-stackrealign /clang:-fomit-frame-pointer /Zi

clang-cl -m32 -fuse-ld=lld /EHsc %WARNINGS% %DEFINES% %FLAGS% /Isrc/shared src/th155r/main.cpp src/th155r/th155r.res -O2 /link /OUT:th155r.exe
clang-cl -m32 -fuse-ld=lld /EHsc %WARNINGS% %DEFINES% %FLAGS% /Isrc/shared /Isrc/Netcode/include src/Netcode/*.cpp /std:c++20 -static -O2 /link /DLL user32.lib WS2_32.lib dbghelp.lib winmm.lib -exclude-all-symbols -kill-at /DEF:Netcode.def /OUT:Netcode.dll
