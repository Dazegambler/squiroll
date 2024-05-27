i686-w64-mingw32-gcc -o th155r.exe main.c 
i686-w64-mingw32-gcc -Wl,--exclude-all-symbols,--kill-at -shared -o Netcode.dll Netcode/main.c