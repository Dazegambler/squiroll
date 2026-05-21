#!/usr/bin/env bash
llvm-rc src/th155r/th155r.rc

python3 generate_embeds.py

PREFIX="$HOME/.xwin-cache/splat"
INCLUDES="/imsvc$PREFIX/crt/include /imsvc$PREFIX/sdk/include/shared /imsvc$PREFIX/sdk/include/ucrt /imsvc$PREFIX/sdk/include/um"
LIBPATHS="/LIBPATH:$PREFIX/crt/lib/x86 /LIBPATH:$PREFIX/sdk/lib/ucrt/x86 /LIBPATH:$PREFIX/sdk/lib/um/x86"
DEFINES="-D_CRT_SECURE_NO_WARNINGS -D_WINSOCK_DEPRECATED_NO_WARNINGS -DNOMINMAX -D_WINSOCKAPI_ -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE -D_CRT_DECLARE_NONSTDC_NAMES"
WARNINGS="-Wno-cpp -Wno-narrowing -Wno-c99-designator -Wno-c23-extensions"
FLAGS="/Gs- /GS- /clang:-fwrapv /Zc:threadSafeInit- -mfpmath=sse -msse2 -msse -mstack-probe-size=1024 -flto=full -mstack-alignment=4 -mno-stackrealign /clang:-fomit-frame-pointer"

clang-cl -m32 -fuse-ld=lld /EHsc $WARNINGS $DEFINES $INCLUDES $FLAGS /Isrc/shared src/th155r/main.cpp src/th155r/th155r.res -O2 /link $LIBPATHS /OUT:build/th155r.exe
clang-cl -m32 -fuse-ld=lld /EHsc $WARNINGS $DEFINES $INCLUDES $FLAGS /Isrc/shared /Isrc/Netcode/include src/Netcode/*.cpp /std:c++20 -O2 /link /DLL $LIBPATHS user32.lib WS2_32.lib dbghelp.lib winmm.lib -exclude-all-symbols -kill-at /DEF:Netcode.def /OUT:build/Netcode.dll
