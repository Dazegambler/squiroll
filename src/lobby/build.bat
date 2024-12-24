@echo off
clang-cl -m32 /std:c++20 -O2 aocf_server.cpp -Wno-narrowing -DNOMINMAX -D_WINSOCKAPI_ -I../shared -o aocf_server.exe -Wno-switch -Wno-c99-designator -Wno-vla-cxx-extension -ferror-limit=100
