i686-w64-mingw32-gcc -o th155r.exe main.c 
#i686-w64-mingw32-gcc -shared -o Netcode.dll Testlib/TestLib.c -Wl,--exclude-all-symbols
i686-w64-mingw32-gcc -Wl,--exclude-all-symbols,--subsystem,windows,--kill-at -shared -o Netcode.dll Testlib/TestLib.c
