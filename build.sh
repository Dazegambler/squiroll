i686-w64-mingw32-gcc -o th155r.exe th155r/main.cpp
i686-w64-mingw32-gcc -Wl,--exclude-all-symbols,--kill-at -shared -I th155r/Netcode/include -o  Netcode.dll th155r/Netcode/*.cpp -std=c++20 -static-libgcc -static-libstdc++ -static -lstdc++ -ldbghelp -O2 -lws2_32 -Wno-cpp -Wno-narrowing -Wno-switch-unreachable -DNOMINMAX -D_WINSOCKAPI_ -DMINGW_COMPAT