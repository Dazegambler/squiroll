PREFIX="$HOME/.xwin-cache/splat"
INCLUDES="/external:I$PREFIX/crt/include /external:I$PREFIX/sdk/include/shared /external:I$PREFIX/sdk/include/ucrt /external:I$PREFIX/sdk/include/um"
LIBPATHS="/LIBPATH:$PREFIX/crt/lib/x86 /LIBPATH:$PREFIX/sdk/lib/ucrt/x86 /LIBPATH:$PREFIX/sdk/lib/um/x86"
DEFINES="-D_CRT_SECURE_NO_WARNINGS -D_WINSOCK_DEPRECATED_NO_WARNINGS -DNOMINMAX -D_WINSOCKAPI_"
WARNINGS="-Wno-cpp -Wno-narrowing"

clang-cl-18 -m32 -fuse-ld=lld /EHsc $WARNINGS $DEFINES $INCLUDES /Ith155r/shared th155r/main.cpp -O2 /link $LIBPATHS /OUT:th155r.exe
clang-cl-18 -m32 -fuse-ld=lld /EHsc $WARNINGS $DEFINES $INCLUDES /Ith155r/shared /Ith155r/Netcode/include th155r/Netcode/*.cpp /std:c++20 -static -O2 /link /DLL $LIBPATHS user32.lib WS2_32.lib dbghelp.lib -exclude-all-symbols -kill-at /DEF:Netcode.def /OUT:Netcode.dll
